import 'package:flutter/material.dart';

class CreditDisplayWidget extends StatelessWidget {
  final int credits;
  final String subscriptionTier;

  const CreditDisplayWidget({
    Key? key,
    required this.credits,
    required this.subscriptionTier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, color: Color(0xFF4A90E2), size: 16),
          SizedBox(width: 4),
          Text(
            '$credits',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '($subscriptionTier)',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
