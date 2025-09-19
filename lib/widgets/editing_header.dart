import 'package:flutter/material.dart';

class EditingHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onResetPressed;
  final bool hasEnhancedImage;
  final bool isSaving;
  final bool isSharing;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onNewImageTap;

  const EditingHeader({
    super.key,
    this.onBackPressed,
    this.onResetPressed,
    required this.hasEnhancedImage,
    required this.isSaving,
    required this.isSharing,
    this.onSaveTap,
    this.onShareTap,
    this.onNewImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBackPressed,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          
          const Spacer(),
          
          // Action buttons (only show when image is enhanced)
          if (hasEnhancedImage) ...[
            _buildActionButton(
              icon: isSaving ? Icons.hourglass_empty : Icons.save_alt,
              onPressed: isSaving ? null : onSaveTap,
              tooltip: 'Save Image',
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: isSharing ? Icons.hourglass_empty : Icons.share,
              onPressed: isSharing ? null : onShareTap,
              tooltip: 'Share Image',
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.add_photo_alternate,
              onPressed: onNewImageTap,
              tooltip: 'New Image',
            ),
            const SizedBox(width: 16), // Extra space before reset/credits
          ],
          
          // Reset button (if provided)
          if (onResetPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: onResetPressed,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed != null ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF3A3A3A),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: onPressed != null ? Colors.white : const Color(0xFF6A6A6A),
            size: 18,
          ),
          onPressed: onPressed,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
