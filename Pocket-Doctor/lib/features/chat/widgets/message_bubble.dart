import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/message.dart';
import '../../../data/models/doctor.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../core/utils/date_utils.dart' as utils;

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool showTime;
  final String? medicalDivision;
  final String? patientId;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTime = false,
    this.medicalDivision,
    this.patientId,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  late MarkdownStyleSheet _markdownStyleSheet;

  // ── Widget cache ──────────────────────────────────────────────────
  // The rendered Markdown widget tree is expensive to produce (tokenise →
  // AST → widget tree).  Because a Message's text is *immutable* after
  // insertion, we build this widget exactly **once** and reuse the same
  // instance on every subsequent frame.  Flutter's element reconciler
  // sees identical widget identity → skips build/layout/paint for the
  // entire Markdown subtree.  This is the highest-impact optimisation.
  Widget? _cachedContentWidget;
  String? _cachedText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _markdownStyleSheet = _buildMarkdownStyleSheet(context);
    // Theme changed → invalidate cached widget so it picks up new styles.
    _cachedContentWidget = null;
    _cachedText = null;
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.message != widget.message.message) {
      _cachedContentWidget = null;
      _cachedText = null;
    }
  }

  /// Returns a cached widget for the AI message content.
  /// Built at most once per unique message text.
  Widget _getOrBuildContentWidget(String text) {
    if (_cachedContentWidget != null && _cachedText == text) {
      return _cachedContentWidget!;
    }

    if (_looksLikeMarkdown(text)) {
      _cachedContentWidget = MarkdownBody(
        data: text,
        selectable: false,
        styleSheet: _markdownStyleSheet,
      );
    } else {
      _cachedContentWidget = Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimaryLight,
          height: 1.5,
          fontSize: 15,
        ),
      );
    }

    _cachedText = text;
    return _cachedContentWidget!;
  }

  static bool _looksLikeMarkdown(String text) {
    // Cheap heuristic to avoid running the markdown parser on plain responses.
    return text.contains('```') ||
        text.contains('**') ||
        text.contains('* ') ||
        text.contains('- ') ||
        text.contains('#') ||
        text.contains('[') && text.contains('](') ||
        text.contains('\n- ') ||
        text.contains('\n* ');
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MarkdownStyleSheet(
      p: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimaryLight,
            height: 1.5,
            fontSize: 15,
          ),
      strong: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
      em: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimaryLight,
            fontStyle: FontStyle.italic,
            fontSize: 15,
          ),
      listBullet: textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 15,
          ),
      h1: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
      h2: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
      h3: textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
      code: textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontFamily: 'monospace',
            backgroundColor: AppColors.primary.withOpacity(0.1),
          ),
      blockquotePadding: const EdgeInsets.all(8),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
    );
  }

  Future<void> _copyMessageToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    final text = widget.message.message;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _copyMessageToClipboard(this.context, text);
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_full_rounded),
                title: const Text('Open (selectable)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openSelectableView(this.context, text);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openSelectableView(BuildContext context, String text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SelectableMessageScreen(
          messageText: text,
          styleSheet: _markdownStyleSheet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFromUser = widget.message.isFromUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment:
              isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isFromUser) ...[
              _buildAIAvatar(),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: _buildMessageContent(context, isFromUser),
              ),
            ),
            if (isFromUser) ...[
              const SizedBox(width: 10),
              _buildUserAvatar(),
            ],
          ],
        ),
        if (widget.showTime) ...[
          const SizedBox(height: 6),
          _buildTimeStamp(context),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.psychology_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isFromUser) {
    final text = widget.message.message;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isFromUser ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isFromUser ? 20 : 4),
          bottomRight: Radius.circular(isFromUser ? 4 : 20),
        ),
        // No BoxShadow — each shadow triggers a saveLayer() GPU call.
        // With N visible bubbles that's N expensive compositing ops per
        // frame during scroll, blowing the 16.6 ms budget on mid-range
        // phones.  A thin border is ~free by comparison.
        border: isFromUser
            ? null
            : Border.all(color: const Color(0xFFECECEC), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromUser) ...[
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
                const SizedBox(width: 8),
                Text(
                  'AI Health Assistant',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // ── STEP 1 — No SelectableText in the scrolling list ────
          // SelectableText installs a gesture recognizer that competes
          // with the ListView's PrimaryScrollController on every pointer
          // event → jank.  Plain Text is sufficient here; users can
          // long-press → Copy for either bubble type.
          //
          // ── STEP 2 — Cached widget for AI messages ────────────────
          // _getOrBuildContentWidget returns the *same* widget instance
          // on every rebuild.  Element reconciler sees identical identity
          // → skips the entire Markdown subtree build/layout/paint.
          isFromUser
              ? Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.5,
                        fontSize: 15,
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () => _showMessageActions(context),
                      child: _getOrBuildContentWidget(text),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showDoctorValidationDialog(context, text),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Validate with Doctor',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  void _showDoctorValidationDialog(BuildContext context, String aiText) {
    Doctor? selectedDoctor;
    final division = widget.medicalDivision ?? 'General Practice';
    final patientId = widget.patientId ?? 'demo-patient-session';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24.0),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Doctor for Validation',
                              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Specialist Division: $division',
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a licensed specialist to review this AI diagnosis:',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Doctor>>(
                      future: DatabaseHelper.instance.getDoctors(specialty: division),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final doctors = snapshot.data ?? [];
                        if (doctors.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No specialists matching $division currently registered. An available physician will review your request.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: doctors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = doctors[index];
                            final isSelected = selectedDoctor?.id == doc.id;
                            final initials = doc.name.replaceAll('Dr. ', '').trim();
                            final avatarText = initials.isNotEmpty
                                ? (initials.length >= 2 ? initials.substring(0, 2).toUpperCase() : initials[0].toUpperCase())
                                : 'DR';

                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedDoctor = doc;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        avatarText,
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text('${doc.specialization} • ${doc.yearsOfExperience} yrs exp', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          Row(
                                            children: [
                                              Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                                              const SizedBox(width: 4),
                                              Text('${doc.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 10),
                                              Text('\$${doc.consultationFee.toStringAsFixed(0)} fee', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Radio<String>(
                                      value: doc.id,
                                      groupValue: selectedDoctor?.id,
                                      onChanged: (val) {
                                        setModalState(() {
                                          selectedDoctor = doc;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final req = await ReviewRepository().submitForDoctorValidation(
                              patientId: patientId,
                              chatId: widget.message.chatId,
                              assignedDoctorId: selectedDoctor?.id,
                              userQuery: 'Patient requested physician review for AI diagnosis.',
                              aiResponseContent: aiText,
                              medicalDivision: division,
                            );

                            if (!context.mounted) return;
                            final isSuccess = req != null;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(isSuccess
                                          ? 'Submitted to ${selectedDoctor?.name ?? "Doctor Care"} for review!'
                                          : 'Review request submitted for physician review!'),
                                    ),
                                  ],
                                ),
                                backgroundColor: isSuccess ? AppColors.primary : Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: const Text('Submit Request'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeStamp(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.message.isFromUser ? 48 : 48,
        right: widget.message.isFromUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: widget.message.isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 12,
            color: AppColors.textSecondaryLight.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            utils.DateUtils.formatMessageTime(widget.message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight.withOpacity(0.6),
                  fontSize: 11,
                ),
          ),
          if (widget.message.isFromUser) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.done_all_rounded,
              size: 14,
              color: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectableMessageScreen extends StatelessWidget {
  final String messageText;
  final MarkdownStyleSheet styleSheet;

  const _SelectableMessageScreen({
    required this.messageText,
    required this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: messageText,
              selectable: true,
              styleSheet: styleSheet,
            ),
          ),
        ),
      ),
    );
  }
}
