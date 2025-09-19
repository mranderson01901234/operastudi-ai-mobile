import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8A4A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Enhancement Error',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFB0B0B0), size: 18),
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(color: Color(0xFFFFB0B0), fontSize: 14),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}
