import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/equipment_usage_bloc.dart';
import '../bloc/equipment_usage_event.dart';
import '../bloc/equipment_usage_state.dart';
import '../pages/equipment_usage_detail_page.dart';
import '../pages/equipment_usage_form_page.dart';
import '../../domain/entities/equipment_usage.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sort_chips.dart';
import '../../../../core/widgets/filter_button.dart';

class EquipmentUsageListView extends StatefulWidget {
  final String? project;
  const EquipmentUsageListView({super.key, this.project});

  @override
  State<EquipmentUsageListView> createState() => _EquipmentUsageListViewState();
}

class _EquipmentUsageListViewState extends State<EquipmentUsageListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<EquipmentUsageBloc>().add(LoadEquipmentUsages(project: widget.project));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<EquipmentUsageBloc>().add(LoadMoreEquipmentUsages());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showFilterBottomSheet(BuildContext context) {
    final bloc = context.read<EquipmentUsageBloc>();
    final currentState = bloc.state;
    String? selectedStatus = currentState.filterStatus;
    DateTime? fromDate = currentState.filterFromDate;
    DateTime? toDate = currentState.filterToDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FilterBottomSheet(
              title: 'Filter Equipment Usages',
              onReset: () {
                bloc.add(const FilterChanged());
              },
              onApply: () {
                bloc.add(
                  FilterChanged(
                    status: selectedStatus,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                );
              },
              children: [
                FilterDropdownSelector(
                  title: 'Status',
                  hintText: 'Select Status',
                  value: selectedStatus,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Status'),
                        children: ['Draft', 'Submitted', 'Cancelled']
                            .map(
                              (status) => SimpleDialogOption(
                                onPressed: () {
                                  setModalState(() {
                                    selectedStatus = status;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text(status),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
                FilterDateRangePicker(
                  title: 'Site Date Range',
                  fromDate: fromDate,
                  toDate: toDate,
                  onRangeSelected: (range) {
                    setModalState(() {
                      fromDate = range?.start;
                      toDate = range?.end;
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.only(
            left: sizeContextOf(context, 12.0),
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
                Icons.arrow_back,
                color: Colors.black87,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Equipment Usages',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          FilterIconButton(
            onTap: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          BlocBuilder<EquipmentUsageBloc, EquipmentUsageState>(
            builder: (context, state) {
              if (state.status == EquipmentUsageStatus.loading &&
                  state.usages.isEmpty) {
                return _buildLoadingSkeleton();
              }

              if (state.status == EquipmentUsageStatus.failure &&
                  state.usages.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.s24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSizes.s16),
                        Text(
                          state.errorMessage ?? 'Error loading equipment usage',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.s16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<EquipmentUsageBloc>()
                              .add(const LoadEquipmentUsages(isRefresh: true)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final usages = List<EquipmentUsage>.from(state.usages);
              usages.sort((a, b) {
                switch (_sortBy) {
                  case 'date_desc':
                    if (a.siteDate == null && b.siteDate == null) return 0;
                    if (a.siteDate == null) return 1;
                    if (b.siteDate == null) return -1;
                    return b.siteDate!.compareTo(a.siteDate!);
                  case 'date_asc':
                    if (a.siteDate == null && b.siteDate == null) return 0;
                    if (a.siteDate == null) return 1;
                    if (b.siteDate == null) return -1;
                    return a.siteDate!.compareTo(b.siteDate!);
                  case 'project_asc':
                    return a.project.compareTo(b.project);
                  case 'project_desc':
                    return b.project.compareTo(a.project);
                  case 'status_asc':
                    return a.status.compareTo(b.status);
                  case 'status_desc':
                    return b.status.compareTo(a.status);
                  case 'id_desc':
                    return b.name.compareTo(a.name);
                  case 'id_asc':
                    return a.name.compareTo(b.name);
                  default:
                    return 0;
                }
              });

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<EquipmentUsageBloc>().add(
                    const LoadEquipmentUsages(isRefresh: true),
                  );
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: sizeContextOf(context, 16),
                    right: sizeContextOf(context, 16),
                    top: sizeContextOf(context, 16),
                    bottom: sizeContextOf(
                      context,
                      100,
                    ), // Safe padding for bottom button
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // _buildSummaryCard(usages),
                      // SizedBox(height: sizeContextOf(context, 16)),
                      _buildSortChips(),
                      SizedBox(height: sizeContextOf(context, 16)),
                      if (usages.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: sizeContextOf(context, 40.0),
                          ),
                          child: Center(
                            child: Text(
                              'No equipment usage records found',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.hasReachedMax
                              ? usages.length
                              : usages.length + 1,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: sizeContextOf(context, 16)),
                          itemBuilder: (context, index) {
                            if (index >= usages.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSizes.s8),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final usage = usages[index];
                            return _EquipmentUsageCard(usage: usage);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<EquipmentUsage> usages) {
    int totalLogs = usages.length;
    int submittedLogs = usages
        .where((u) => u.status.toLowerCase() == 'submitted')
        .length;
    double totalCost = usages.fold(
      0.0,
      (sum, u) =>
          sum +
          u.equipmentUsageDetails.fold(
            0.0,
            (itemSum, item) => itemSum + item.amount,
          ),
    );

    String formattedCost = '';
    if (totalCost >= 1000) {
      formattedCost = '₹${(totalCost / 1000).toStringAsFixed(1)}k';
    } else {
      formattedCost = '₹${totalCost.toStringAsFixed(0)}';
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sizeContextOf(context, 4.0),
              ),
              child: Column(
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Total Logs',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$totalLogs',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sizeContextOf(context, 4.0),
              ),
              child: Column(
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Submitted Logs',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 8)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$submittedLogs',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sizeContextOf(context, 4.0),
              ),
              child: Column(
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Total Cost',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 8)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formattedCost,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    return SortChips(
      sortBy: _sortBy,
      options: const [
        SortOption(label: 'Date', field: 'date'),
        SortOption(label: 'Status', field: 'status'),
        SortOption(label: 'ID', field: 'id'),
      ],
      onSortChanged: (newSort) {
        setState(() {
          _sortBy = newSort;
        });
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: EdgeInsets.all(sizeContextOf(context, 16)),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: sizeContextOf(context, 16)),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Positioned(
      bottom: sizeContextOf(context, 24),
      left: sizeContextOf(context, 16),
      right: sizeContextOf(context, 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EquipmentUsageFormPage(),
            ),
          );

          if (result == true && context.mounted) {
            context.read<EquipmentUsageBloc>().add(
              const LoadEquipmentUsages(isRefresh: true),
            );
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 16)),
          decoration: BoxDecoration(
            color: AppColors.primaryButton,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '+ Add Equipment Log',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentUsageCard extends StatelessWidget {
  final EquipmentUsage usage;

  const _EquipmentUsageCard({required this.usage});

  @override
  Widget build(BuildContext context) {
    double totalCost = usage.equipmentUsageDetails.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    String qtyText = '${usage.equipmentUsageDetails.length} items';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EquipmentUsageDetailPage(usageName: usage.name),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(sizeContextOf(context, 12.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usage.project,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    StatusBadge(status: usage.status),
                  ],
                ),
                SizedBox(height: sizeContextOf(context, 6)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usage.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: sizeContextOf(context, 6)),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: sizeContextOf(context, 4)),
                              Text(
                                usage.siteDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(usage.siteDate!)
                                    : '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(width: sizeContextOf(context, 12)),
                              Icon(
                                Icons.handyman_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: sizeContextOf(context, 4)),
                              Text(
                                qtyText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: sizeContextOf(context, 12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(
                            symbol: '₹',
                            decimalDigits: 2,
                          ).format(totalCost),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        const Text(
                          'Total Cost',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
