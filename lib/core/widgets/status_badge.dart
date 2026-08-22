import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/theme/app_sizes.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'submitted':
        bgColor = const Color(0xFFA7D5B0);
        textColor = Colors.white;
        icon = Icons.star;
        break;
      case 'draft':
        bgColor = AppColors.warning.withValues(alpha: 0.2);
        textColor = AppColors.warning;
        break;
      case 'cancelled':
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      case 'approved by pm':
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        break;
      case 'acknowledged by consultant':
        bgColor = AppColors.secondary.withValues(alpha: 0.1);
        textColor = AppColors.secondary;
        break;
      case 'stopped':
        bgColor = Colors.blueGrey.withValues(alpha: 0.2);
        textColor = Colors.blueGrey;
        break;
      case 'partially ordered':
        bgColor = Colors.purple.withValues(alpha: 0.2);
        textColor = Colors.purple;
        break;
      case 'ordered':
        bgColor = Colors.teal.withValues(alpha: 0.2);
        textColor = Colors.teal;
        break;
      case 'issued':
        bgColor = Colors.lightBlue.withValues(alpha: 0.2);
        textColor = Colors.lightBlue;
        break;
      case 'transferred':
      case 'received':
        bgColor = AppColors.success.withValues(alpha: 0.2);
        textColor = AppColors.success;
        break;
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        break;
      default:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, 10),
        vertical: sizeContextOf(context, 4),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            SizedBox(width: sizeContextOf(context, 4)),
          ],
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
