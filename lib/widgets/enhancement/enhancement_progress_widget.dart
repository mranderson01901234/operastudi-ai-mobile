import 'package:flutter/material.dart';

class EnhancementProgressWidget extends StatelessWidget {
  final bool isProcessing;
  final double progress;
  final String status;

  const EnhancementProgressWidget({
    super.key,
    required this.isProcessing,
    required this.progress,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProcessing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF3A3A3A),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% Complete',
            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
