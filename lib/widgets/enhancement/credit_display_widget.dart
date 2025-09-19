import 'package:flutter/material.dart';

class CreditDisplayWidget extends StatelessWidget {
  final int credits;
  final String subscriptionTier;

  const CreditDisplayWidget({
    super.key,
    required this.credits,
    required this.subscriptionTier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFF4A90E2), size: 16),
          const SizedBox(width: 4),
          Text(
            '$credits',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($subscriptionTier)',
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
