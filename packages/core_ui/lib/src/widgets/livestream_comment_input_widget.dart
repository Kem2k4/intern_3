import 'package:flutter/material.dart';

/// Widget for inputting livestream comments
class LivestreamCommentInputWidget extends StatefulWidget {
  /// Whether to show the input widget
  final bool isVisible;

  /// Callback when a comment is submitted
  final void Function(String message) onCommentSubmitted;

  /// Placeholder text for the input field
  final String placeholder;

  const LivestreamCommentInputWidget({
    super.key,
    this.isVisible = true,
    required this.onCommentSubmitted,
    this.placeholder = 'Write a comment...',
  });

  @override
  State<LivestreamCommentInputWidget> createState() => _LivestreamCommentInputWidgetState();
}

class _LivestreamCommentInputWidgetState extends State<LivestreamCommentInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    widget.onCommentSubmitted(text.trim());
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isComposing ? Colors.blue : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isComposing ? () => _handleSubmitted(_controller.text) : null,
              icon: Icon(
                Icons.send,
                color: _isComposing ? Colors.white : Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              tooltip: 'Send comment',
            ),
          ),
        ],
      ),
    );
  }
}
