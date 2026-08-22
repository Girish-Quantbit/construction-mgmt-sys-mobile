import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/theme/app_sizes.dart';

class FilterBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: sizeContextOf(context, AppSizes.s20),
        right: sizeContextOf(context, AppSizes.s20),
        top: sizeContextOf(context, AppSizes.s20),
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            sizeContextOf(context, AppSizes.s24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: sizeContextOf(context, 18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.divider),
            SizedBox(height: sizeContextOf(context, AppSizes.s16)),
            ...children,
            SizedBox(height: sizeContextOf(context, AppSizes.s32)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onReset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: sizeContextOf(context, 14),
                      ),
                      side: const BorderSide(color: AppColors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.r12),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: sizeContextOf(context, 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: sizeContextOf(context, AppSizes.s12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onApply();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      padding: EdgeInsets.symmetric(
                        vertical: sizeContextOf(context, 14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.r12),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: sizeContextOf(context, 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FilterSectionTitle extends StatelessWidget {
  final String title;
  const FilterSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: sizeContextOf(context, AppSizes.s8)),
      child: Text(
        title,
        style: TextStyle(
          fontSize: sizeContextOf(context, 14),
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

class FilterStatusGroup extends StatelessWidget {
  final String title;
  final List<String> statuses;
  final String? selectedStatus;
  final ValueChanged<String?> onSelected;

  const FilterStatusGroup({
    super.key,
    required this.title,
    required this.statuses,
    required this.selectedStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionTitle(title: title),
        Wrap(
          spacing: sizeContextOf(context, AppSizes.s8),
          children: statuses.map((status) {
            final isSel = selectedStatus == status;
            return ChoiceChip(
              label: Text(status),
              selected: isSel,
              selectedColor: AppColors.selectedChip,
              backgroundColor: AppColors.surfaceContainer,
              labelStyle: TextStyle(
                color: isSel ? AppColors.onPrimary : AppColors.primaryText,
                fontSize: sizeContextOf(context, 12),
                fontWeight: FontWeight.w600,
              ),
              onSelected: (selected) {
                onSelected(selected ? status : null);
              },
            );
          }).toList(),
        ),
        SizedBox(height: sizeContextOf(context, AppSizes.s20)),
      ],
    );
  }
}

class FilterDropdownSelector extends StatelessWidget {
  final String title;
  final String hintText;
  final String? value;
  final VoidCallback onTap;

  const FilterDropdownSelector({
    super.key,
    required this.title,
    required this.hintText,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionTitle(title: title),
        InkWell(
          onTap: onTap,
          child: IgnorePointer(
            child: TextField(
              controller: TextEditingController(text: value),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: sizeContextOf(context, 13),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: sizeContextOf(context, AppSizes.s16),
                  vertical: sizeContextOf(context, AppSizes.s12),
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: sizeContextOf(context, AppSizes.s20)),
      ],
    );
  }
}

class FilterDateRangePicker extends StatelessWidget {
  final String title;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTimeRange?> onRangeSelected;

  const FilterDateRangePicker({
    super.key,
    required this.title,
    required this.fromDate,
    required this.toDate,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionTitle(title: title),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: (fromDate != null && toDate != null)
                        ? DateTimeRange(start: fromDate!, end: toDate!)
                        : null,
                  );
                  onRangeSelected(range);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sizeContextOf(context, AppSizes.s12),
                    vertical: sizeContextOf(context, AppSizes.s12),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline),
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: sizeContextOf(context, 16),
                        color: AppColors.onSurfaceVariant,
                      ),
                      SizedBox(width: sizeContextOf(context, AppSizes.s8)),
                      Expanded(
                        child: Text(
                          (fromDate != null && toDate != null)
                              ? '${DateFormat('MMM dd').format(fromDate!)} - ${DateFormat('MMM dd').format(toDate!)}'
                              : 'Select Date Range',
                          style: TextStyle(
                            fontSize: sizeContextOf(context, 13),
                            color: (fromDate != null)
                                ? AppColors.primaryText
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (fromDate != null) ...[
              SizedBox(width: sizeContextOf(context, AppSizes.s8)),
              IconButton(
                icon: const Icon(Icons.clear, color: AppColors.error),
                onPressed: () {
                  onRangeSelected(null);
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
