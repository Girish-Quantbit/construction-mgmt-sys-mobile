import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';

class FilterIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const FilterIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: sizeContextOf(context, 12.0),
        top: sizeContextOf(context, 8.0),
        bottom: sizeContextOf(context, 8.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.filter_alt,
            color: Colors.black87,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          onPressed: onTap,
        ),
      ),
    );
  }
}
