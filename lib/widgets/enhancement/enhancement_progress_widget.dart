import 'package:flutter/material.dart';

class EnhancementProgressWidget extends StatelessWidget {
  final bool isProcessing;
  final double progress;
  final String status;

  const EnhancementProgressWidget({
    Key? key,
    required this.isProcessing,
    required this.progress,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isProcessing) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Color(0xFF3A3A3A),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
          ),
          SizedBox(height: 12),
          Text(
            status,
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% Complete',
            style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
