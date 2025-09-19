import 'package:flutter/material.dart';
import 'dart:io';

enum ShareMethod {
  native,
  whatsapp,
  instagram,
}

class ShareOptionsDialog extends StatefulWidget {
  final Function(ShareMethod method) onShare;
  
  const ShareOptionsDialog({
    super.key,
    required this.onShare,
  });

  @override
  State<ShareOptionsDialog> createState() => _ShareOptionsDialogState();
}

class _ShareOptionsDialogState extends State<ShareOptionsDialog> {
  ShareMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        'Share Your Enhanced Image',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how to share your image',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildShareOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedMethod != null ? () {
            widget.onShare(_selectedMethod!);
            Navigator.of(context).pop();
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Share'),
        ),
      ],
    );
  }

  Widget _buildShareOptions() {
    return Column(
      children: [
        _buildShareTile(
          ShareMethod.native,
          'Native Share',
          Platform.isLinux 
            ? 'Open file manager for manual sharing'
            : 'Use your device\'s built-in share menu',
          Icons.share,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),
        _buildShareTile(
          ShareMethod.whatsapp,
          'WhatsApp',
          'Share directly to WhatsApp contacts or groups',
          Icons.chat,
          color: const Color(0xFF25D366),
        ),
        const SizedBox(height: 12),
        _buildShareTile(
          ShareMethod.instagram,
          'Instagram',
          Platform.isAndroid 
            ? 'Share to Instagram Stories or Feed'
            : 'Share to Instagram (mobile only)',
          Icons.camera_alt,
          color: const Color(0xFFE4405F),
        ),
      ],
    );
  }

  Widget _buildShareTile(
    ShareMethod method, 
    String title, 
    String subtitle, 
    IconData icon,
    {Color? color}
  ) {
    final isSelected = _selectedMethod == method;
    final tileColor = color ?? const Color(0xFF2196F3);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? tileColor.withOpacity(0.2) : const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: tileColor) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? tileColor : Colors.white70,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? tileColor : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? tileColor.withOpacity(0.8) : Colors.white60,
            fontSize: 12,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
      ),
    );
  }
} 