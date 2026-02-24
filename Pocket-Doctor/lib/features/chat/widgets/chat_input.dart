import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSend;
  final VoidCallback? onImagePicker;
  final VoidCallback? onSendImage;
  final VoidCallback? onRemoveImage;
  final File? pendingImage;
  final bool isTyping;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onImagePicker,
    this.onSendImage,
    this.onRemoveImage,
    this.pendingImage,
    this.isTyping = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeOutBack,
    ));

    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty ||
        widget.pendingImage != null;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });

      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-evaluate send button visibility when pendingImage changes.
    if (oldWidget.pendingImage != widget.pendingImage) {
      _onTextChanged();
    }
  }

  void _handleSend() {
    if (widget.isTyping) return;

    // If there's a pending image, send the image (with optional text caption)
    if (widget.pendingImage != null && widget.onSendImage != null) {
      HapticFeedback.lightImpact();
      widget.onSendImage!();
      return;
    }

    // Otherwise send text as usual
    if (widget.controller.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSend(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image preview (shown when an image is selected) ───
            if (widget.pendingImage != null) _buildImagePreview(),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image picker button
                if (widget.onImagePicker != null) ...[
                  _buildImagePickerButton(),
                  const SizedBox(width: 10),
                ],

                // Text input field
                Expanded(
                  child: _buildTextField(),
                ),

                const SizedBox(width: 10),

                // Send button
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              widget.pendingImage!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image ready to send',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap send to analyze with AI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          // Remove button
          GestureDetector(
            onTap: widget.onRemoveImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButton() {
    return GestureDetector(
      onTap: widget.onImagePicker,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.add_photo_alternate_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.15),
          width: _isFocused ? 2 : 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontSize: 15,
                  ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: widget.isTyping
                    ? 'AI is thinking...'
                    : 'Describe your symptoms...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight.withOpacity(0.6),
                      fontSize: 15,
                    ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              enabled: !widget.isTyping,
            ),
          ),
          if (widget.isTyping)
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _handleSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: _hasText && !widget.isTyping
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          color: _hasText && !widget.isTyping
              ? null
              : AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hasText && !widget.isTyping
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: AnimatedBuilder(
          animation: _sendButtonScale,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.7 + (0.3 * _sendButtonScale.value),
              child: Icon(
                Icons.send_rounded,
                color: _hasText && !widget.isTyping
                    ? Colors.white
                    : AppColors.primary.withOpacity(0.4),
                size: 22,
              ),
            );
          },
        ),
      ),
    );
  }
}
