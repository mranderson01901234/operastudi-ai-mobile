import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDisplayWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (error == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF4A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF8A4A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 20),
              SizedBox(width: 8),
              Text(
                'Enhancement Error',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              if (onDismiss != null)
                IconButton(
                  icon: Icon(Icons.close, color: Color(0xFFB0B0B0), size: 18),
                  onPressed: onDismiss,
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(color: Color(0xFFFFB0B0), fontSize: 14),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A90E2),
                foregroundColor: Colors.white,
              ),
              child: Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}
