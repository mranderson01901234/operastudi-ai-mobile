import 'package:flutter/material.dart';

class EditingHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onResetPressed;

  const EditingHeader({
    Key? key,
    this.onBackPressed,
    this.onResetPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBackPressed,
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Text(
              'Edit Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onResetPressed != null)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: onResetPressed,
              constraints: BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
