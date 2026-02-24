import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/message.dart';
import '../../../data/database/database_helper.dart';
import '../../emergency/screens/emergency_alert_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'chat_history_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatScreen({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isEmergency = false;  // Track emergency level from AI response
  File? _pendingImage;         // Image waiting to be sent
  late AnimationController _typingAnimationController;
  late AnimationController _headerAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadMessages();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.chat.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final messages =
          await DatabaseHelper.instance.getMessagesByChatId(widget.chat.id!);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom(force: true);

        // Add welcome message if this is a new chat
        if (_messages.isEmpty) {
          _addWelcomeMessage();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Failed to load messages: $e');
      }
    }
  }

  void _addWelcomeMessage() {
    final specialty = widget.chat.specialty;
    final emoji = MedicalDivisions.getEmojiByName(specialty);
    final welcomeText = specialty == 'General'
        ? 'Hello! I\'m your AI Health Assistant. 👋\n\nHow can I help you today? Feel free to describe your symptoms or health concerns, and I\'ll do my best to provide helpful information.'
        : 'Hello! I\'m your AI Health Assistant specializing in $specialty $emoji\n\nHow can I help you today? Feel free to describe your symptoms or health concerns related to $specialty.';

    _addAIMessage(welcomeText);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || widget.chat.id == null) return;

    final userMessage = text.trim();

    // Check for emergency keywords
    if (_containsEmergencyKeywords(userMessage)) {
      _showEmergencyAlert();
    }

    // Add user message
    await _addUserMessage(userMessage);
    _messageController.clear();

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });
    _typingAnimationController.repeat();

    // Get AI response
    await _getAIResponse(userMessage);
  }

  bool _containsEmergencyKeywords(String text) {
    final lowerText = text.toLowerCase();
    return AppConstants.emergencyKeywords
        .any((keyword) => lowerText.contains(keyword.toLowerCase()));
  }

  void _showEmergencyAlert() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EmergencyAlertScreen(
          onContinue: () {
            Navigator.of(context).pop();
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _addUserMessage(String text) async {
    final message = Message(
      chatId: widget.chat.id!,
      sender: 'user',
      message: text,
      createdAt: DateTime.now(),
    );

    final messageId = await DatabaseHelper.instance.insertMessage(message);
    final newMessage = message.copyWith(id: messageId);

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom(force: true);
  }

  Future<void> _addAIMessage(String text, {bool isEmergency = false}) async {
    if (widget.chat.id == null) return;

    final message = Message(
      chatId: widget.chat.id!,
      sender: 'ai',
      message: text,
      createdAt: DateTime.now(),
    );

    final messageId = await DatabaseHelper.instance.insertMessage(message);
    final newMessage = message.copyWith(id: messageId);

    setState(() {
      _messages.add(newMessage);
      _isTyping = false;
      _isEmergency = isEmergency;
    });

    _typingAnimationController.stop();
    _scrollToBottom();
  }

  Future<void> _getAIResponse(String userMessage) async {
    try {
      // Call AI service directly - no pre-check needed
      // The API call itself will tell us if there's an error
      final aiResponse = await GeminiAIService.sendMessage(
        message: userMessage,
        specialty: widget.chat.specialty,
        userId: widget.chat.userId.toString(),
      );

      // Check for emergency in response
      if (aiResponse.isEmergency && mounted) {
        _showEmergencyAlert();
      }

      await _addAIMessage(aiResponse.message, isEmergency: aiResponse.isEmergency);
    } on AIException catch (e) {
      // Handle specific AI service errors
      debugPrint('AI Error: ${e.message} (${e.code})');
      
      final fallbackResponse = FallbackResponses.createFallbackResponse(userMessage);
      await _addAIMessage(fallbackResponse.message, isEmergency: false);

      if (mounted) {
        String snackBarMessage = 'Connection issue. Showing general guidance.';
        IconData snackIcon = Icons.wifi_off;
        
        if (e.code == 'NO_INTERNET') {
          snackBarMessage = 'No internet connection. Please check WiFi/data.';
          snackIcon = Icons.wifi_off;
        } else if (e.code == 'TIMEOUT') {
          snackBarMessage = 'Request timed out. Slow connection detected.';
          snackIcon = Icons.timer_off;
        } else if (e.code == 'API_ERROR') {
          snackBarMessage = 'Server error. Please try again later.';
          snackIcon = Icons.cloud_off;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(snackIcon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(snackBarMessage)),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      debugPrint('Unexpected error: $e');
      
      final fallbackResponse = FallbackResponses.createFallbackResponse(userMessage);
      await _addAIMessage(fallbackResponse.message, isEmergency: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Something went wrong. Showing general guidance.')),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Only auto-scroll if user is near bottom or force is true
        final isNearBottom = _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100;
        
        if (force || isNearBottom) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.splashBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),

              // Chat messages
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : _buildMessagesList(),
              ),

              // Medical disclaimer (compact)
              _buildCompactDisclaimer(),

              // Chat input
              _buildChatInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    final emoji = MedicalDivisions.getEmojiByName(widget.chat.specialty);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // AI Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.specialty,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Assistant Online',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chat History button
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatHistoryScreen(
                      userId: widget.chat.userId,
                    ),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              tooltip: 'Chat History',
            ),

            // Menu button
            IconButton(
              onPressed: _showChatOptions,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondaryLight,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty && !_isTyping) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start Your Consultation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Describe your symptoms or health concerns to begin.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      // Keep this modest to avoid prebuilding lots of Markdown-heavy bubbles.
      cacheExtent: 250,
      // Don't keep off-screen items alive — frees memory for long chats.
      addAutomaticKeepAlives: false,
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          final message = _messages[index];
          final isLast = index == _messages.length - 1;
          final showTime = isLast ||
              (index < _messages.length - 1 &&
                  _messages[index + 1]
                          .createdAt
                          .difference(message.createdAt)
                          .inMinutes >
                      5);

          return Column(
            children: [
              RepaintBoundary(
                child: MessageBubble(
                  key: ValueKey<int>(message.id ?? message.createdAt.microsecondsSinceEpoch),
                  message: message,
                  showTime: showTime,
                ),
              ),
              if (message.isFromAI && isLast && !_isTyping && _isEmergency) ...[
                const SizedBox(height: 8),
                _buildEmergencyLevelIndicator(),
              ],
            ],
          );
        } else {
          // Typing indicator
          return _buildTypingIndicator();
        }
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final progress =
                        ((_typingAnimationController.value - delay) % 1.0)
                            .clamp(0.0, 1.0);
                    final bounce = progress < 0.5
                        ? progress * 2
                        : 2 - progress * 2;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.translate(
                        offset: Offset(0, -6 * bounce),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6 + 0.4 * bounce),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyLevelIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emergency icon with animated pulse effect
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            
            // Emergency text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Emergency Level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Please seek medical help immediately',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDisclaimer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI analysis only. Consult a doctor for proper diagnosis.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ChatInput(
        controller: _messageController,
        focusNode: _focusNode,
        onSend: _sendMessage,
        onImagePicker: _handleImagePicker,
        onSendImage: _sendPendingImage,
        onRemoveImage: _removePendingImage,
        pendingImage: _pendingImage,
        isTyping: _isTyping,
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
                title: const Text('Clear Chat'),
                subtitle: const Text('Delete all messages'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmClearChat();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Export Chat'),
                subtitle: const Text('Save conversation as PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showFeatureComingSoon('Export');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: AppColors.warning),
                ),
                title: const Text('Report Issue'),
                subtitle: const Text('Report incorrect information'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showFeatureComingSoon('Report');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text('$feature feature coming soon!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              const Text('Clear Chat'),
            ],
          ),
          content: const Text(
              'Are you sure you want to clear all messages? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearChat();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearChat() async {
    if (widget.chat.id == null) return;

    try {
      // Delete all messages in this chat
      for (final message in _messages) {
        if (message.id != null) {
          await DatabaseHelper.instance.deleteMessage(message.id!);
        }
      }

      setState(() {
        _messages.clear();
      });

      // Add welcome message again
      _addWelcomeMessage();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Chat cleared successfully'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      _showError('Failed to clear chat: $e');
    }
  }

  Future<void> _handleImagePicker() async {
    // Let the user choose Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.accent),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return; // User cancelled

      // Store the image as pending — do NOT send yet.
      // The preview will appear in ChatInput; user presses Send to confirm.
      setState(() {
        _pendingImage = File(image.path);
      });
    } catch (e) {
      if (mounted) {
        _showError('Failed to pick image: $e');
      }
    }
  }

  void _removePendingImage() {
    setState(() {
      _pendingImage = null;
    });
  }

  Future<void> _sendPendingImage() async {
    if (_pendingImage == null || widget.chat.id == null) return;

    final imageFile = _pendingImage!;

    // Clear the pending image immediately so the preview disappears.
    setState(() {
      _pendingImage = null;
    });

    // Use any text in the input box as a caption, or fallback.
    final caption = _messageController.text.trim().isNotEmpty
        ? _messageController.text.trim()
        : 'Please analyze this medical image and provide health guidance.';
    _messageController.clear();

    // Add user message showing an image was sent.
    await _addUserMessage('📷 Sent an image for analysis${caption != 'Please analyze this medical image and provide health guidance.' ? '\n$caption' : ''}');

    // Show typing indicator.
    setState(() {
      _isTyping = true;
    });
    _typingAnimationController.repeat();

    try {
      // Read image bytes and convert to base64.
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine MIME type from extension.
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      // Send to Gemini multimodal API.
      final aiResponse = await GeminiAIService.sendMessageWithImage(
        message: caption,
        imageBase64: base64Image,
        mimeType: mimeType,
        specialty: widget.chat.specialty,
      );

      if (aiResponse.isEmergency && mounted) {
        _showEmergencyAlert();
      }

      await _addAIMessage(
          aiResponse.message, isEmergency: aiResponse.isEmergency);
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Image analysis failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
