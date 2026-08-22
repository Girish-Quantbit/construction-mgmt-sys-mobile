import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class SortOption {
  final String label;
  final String field;

  const SortOption({required this.label, required this.field});
}

class SortChips extends StatelessWidget {
  final String sortBy;
  final List<SortOption> options;
  final ValueChanged<String> onSortChanged;

  const SortChips({
    super.key,
    required this.sortBy,
    required this.options,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = sortBy.startsWith(option.field);
          final isAsc = sortBy.endsWith('asc');

          return Padding(
            padding: EdgeInsets.only(
              right: option == options.last ? 0 : sizeContextOf(context, 6),
            ),
            child: GestureDetector(
              onTap: () {
                if (isSelected) {
                  onSortChanged(
                    isAsc ? '${option.field}_desc' : '${option.field}_asc',
                  );
                } else {
                  onSortChanged('${option.field}_desc');
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sizeContextOf(context, 14),
                  vertical: sizeContextOf(context, 8),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.selectedChip : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    if (isSelected) ...[
                      SizedBox(width: sizeContextOf(context, 4)),
                      Icon(
                        isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
