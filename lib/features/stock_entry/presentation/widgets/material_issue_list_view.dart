import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/stock_entry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/stock_entry_bloc.dart';
import '../bloc/stock_entry_event.dart';
import '../bloc/stock_entry_state.dart';
import '../pages/material_transfer_detail_page.dart';
import '../pages/material_issue_detail_page.dart';
import '../pages/stock_entry_form_page.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sort_chips.dart';
import '../../../../core/widgets/filter_button.dart';

class MaterialIssueListView extends StatefulWidget {
  final String? stockEntryType;
  final String? project;
  const MaterialIssueListView({super.key, this.stockEntryType, this.project});

  @override
  State<MaterialIssueListView> createState() => _MaterialIssueListViewState();
}

class _MaterialIssueListViewState extends State<MaterialIssueListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<StockEntryBloc>().add(
      LoadStockEntries(
        isRefresh: true,
        stockEntryType: widget.stockEntryType,
        project: widget.project,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<StockEntryBloc>().add(
        LoadStockEntries(
          stockEntryType: widget.stockEntryType,
          project: widget.project,
        ),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Text(
        widget.stockEntryType ?? 'Stock Entries',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [FilterIconButton(onTap: () => _showFilterBottomSheet(context))],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String? selectedStatus = _filterStatus == 'All' ? null : _filterStatus;

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
              title: 'Filter Stock Entries',
              onReset: () {
                setState(() {
                  _filterStatus = 'All';
                });
              },
              onApply: () {
                setState(() {
                  _filterStatus = selectedStatus ?? 'All';
                });
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
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMaterialIssue = widget.stockEntryType == 'Material Issue';

    if (!isMaterialIssue) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildFilters(context),
            Expanded(
              child: BlocBuilder<StockEntryBloc, StockEntryState>(
                builder: (context, state) {
                  if (state.listStatus == StockEntryStatus.loading &&
                      state.entries.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.listStatus == StockEntryStatus.failure &&
                      state.entries.isEmpty) {
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
                              state.errorMessage ??
                                  'Failed to load stock entries',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSizes.s24),
                            ElevatedButton(
                              onPressed: () {
                                context.read<StockEntryBloc>().add(
                                  LoadStockEntries(
                                    isRefresh: true,
                                    stockEntryType: widget.stockEntryType,
                                    project: widget.project,
                                  ),
                                );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final displayEntries = _getFilteredAndSortedEntries(
                    state.entries,
                  );

                  if (displayEntries.isEmpty) {
                    return const Center(child: Text('No stock entries found'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<StockEntryBloc>().add(
                        LoadStockEntries(
                          isRefresh: true,
                          stockEntryType: widget.stockEntryType,
                          project: widget.project,
                        ),
                      );
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSizes.s16),
                      itemCount: state.hasReachedMax
                          ? displayEntries.length
                          : displayEntries.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSizes.s12),
                      itemBuilder: (context, index) {
                        if (index >= displayEntries.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSizes.s8),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final entry = displayEntries[index];
                        return _StockEntryCard(entry: entry);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Modern Premium Layout for Material Issues (matching PurchaseReceiptListView)
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: _buildAppBar(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          BlocBuilder<StockEntryBloc, StockEntryState>(
            builder: (context, state) {
              if (state.listStatus == StockEntryStatus.loading &&
                  state.entries.isEmpty) {
                return _buildLoadingSkeleton();
              }

              if (state.listStatus == StockEntryStatus.failure &&
                  state.entries.isEmpty) {
                return Center(
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
                        state.errorMessage ?? 'Error loading material issues',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.s16),
                      ElevatedButton(
                        onPressed: () => context.read<StockEntryBloc>().add(
                          LoadStockEntries(
                            isRefresh: true,
                            stockEntryType: widget.stockEntryType,
                            project: widget.project,
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final displayEntries = _getFilteredAndSortedEntries(
                state.entries,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<StockEntryBloc>().add(
                    LoadStockEntries(
                      isRefresh: true,
                      stockEntryType: widget.stockEntryType,
                      project: widget.project,
                    ),
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
                      // _buildSummaryCard(displayEntries),
                      // SizedBox(height: sizeContextOf(context, 16)),
                      // _buildFilterChips(),
                      // SizedBox(height: sizeContextOf(context, 16)),
                      _buildSortChips(),
                      SizedBox(height: sizeContextOf(context, 16)),
                      if (displayEntries.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: sizeContextOf(context, 40.0),
                          ),
                          child: Center(
                            child: Text(
                              'No material issues found',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.hasReachedMax
                              ? displayEntries.length
                              : displayEntries.length + 1,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: sizeContextOf(context, 16)),
                          itemBuilder: (context, index) {
                            if (index >= displayEntries.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSizes.s8),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _StockEntryCard(
                              entry: displayEntries[index],
                            );
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

  List<StockEntry> _getFilteredAndSortedEntries(List<StockEntry> entries) {
    final filtered = entries.where((entry) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          entry.name.toLowerCase().contains(query) ||
          entry.purpose.toLowerCase().contains(query) ||
          entry.stockEntryType.toLowerCase().contains(query);

      final matchesStatus =
          _filterStatus == 'All' ||
          entry.status.toLowerCase() == _filterStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date_desc':
          if (a.postingDate == null && b.postingDate == null) return 0;
          if (a.postingDate == null) return 1;
          if (b.postingDate == null) return -1;
          return b.postingDate!.compareTo(a.postingDate!);
        case 'date_asc':
          if (a.postingDate == null && b.postingDate == null) return 0;
          if (a.postingDate == null) return 1;
          if (b.postingDate == null) return -1;
          return a.postingDate!.compareTo(b.postingDate!);
        case 'type_asc':
          return a.stockEntryType.compareTo(b.stockEntryType);
        case 'type_desc':
          return b.stockEntryType.compareTo(a.stockEntryType);
        case 'status_asc':
          return a.status.compareTo(b.status);
        case 'status_desc':
          return b.status.compareTo(a.status);
        case 'id_desc':
          return b.name.compareTo(a.name);
        case 'id_asc':
          return a.name.compareTo(b.name);
        case 'total_outgoing_value_asc':
          return a.totalOutgoingValue.compareTo(b.totalOutgoingValue);
        case 'total_outgoing_value_desc':
          return b.totalOutgoingValue.compareTo(a.totalOutgoingValue);
        default:
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildSummaryCard(List<StockEntry> entries) {
    int totalIssues = entries.length;
    int draftIssues = entries
        .where((e) => e.status.toLowerCase() == 'draft')
        .length;
    double totalValue = entries.fold(
      0.0,
      (sum, e) => sum + e.totalOutgoingValue,
    );

    String formattedValue = '';
    if (totalValue >= 1000) {
      formattedValue = '₹${(totalValue / 1000).toStringAsFixed(1)}k';
    } else {
      formattedValue = '₹${totalValue.toStringAsFixed(0)}';
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
                      'Total Issues',
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
                      '$totalIssues',
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
                      'Draft Issues',
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
                      '$draftIssues',
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
                      'Total Value',
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
                      formattedValue,
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

  // Widget _buildFilterChips() {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       children: [
  //         _buildFilterChip('Date Range', true, isSelected: true),
  //         SizedBox(width: sizeContextOf(context, 6)),
  //         _buildFilterChip('Warehouse', true),
  //         SizedBox(width: sizeContextOf(context, 6)),
  //         _buildFilterChip('Status', true),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFilterChip(
    String label,
    bool hasDropdown, {
    bool isSelected = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, 14),
        vertical: sizeContextOf(context, 6),
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.selectedChip : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
          ),
          if (hasDropdown) ...[
            SizedBox(width: sizeContextOf(context, 4)),
            Icon(
              Icons.arrow_drop_down,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 18,
            ),
          ],
        ],
      ),
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
              builder: (context) => const StockEntryFormPage(
                stockEntryType: 'Material Issue',
              ),
            ),
          );

          if (result == true && context.mounted) {
            context.read<StockEntryBloc>().add(
              LoadStockEntries(
                isRefresh: true,
                stockEntryType: widget.stockEntryType,
                project: widget.project,
              ),
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
            '+ Create Material Issue',
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

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Stock Entry ID or Purpose...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.s12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppSizes.s12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.s12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.r8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                isExpanded: true,
                items: ['All', 'Draft', 'Submitted', 'Cancelled'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filterStatus = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          _buildSortChips(),
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    return SortChips(
      sortBy: _sortBy,
      options: const [
        SortOption(label: 'Date', field: 'date'),
        SortOption(label: 'Type', field: 'type'),
        SortOption(label: 'Status', field: 'status'),
        SortOption(label: 'ID', field: 'id'),
        SortOption(label: 'Amount', field: 'total_outgoing_value'),
      ],
      onSortChanged: (newSort) {
        setState(() {
          _sortBy = newSort;
        });
      },
    );
  }
}

class _StockEntryCard extends StatelessWidget {
  final StockEntry entry;

  const _StockEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMaterialIssue = entry.stockEntryType == 'Material Issue';

    if (!isMaterialIssue) {
      // Return fallback simple design for other Stock Entries
      return Card(
        elevation: 0,
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r12),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSizes.s16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              StatusBadge(status: entry.status),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.s8),
              Text(
                entry.stockEntryType,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSizes.s4),
                  Text(
                    entry.postingDate != null
                        ? DateFormat('dd-MM-yyyy').format(entry.postingDate!)
                        : '-',
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              if (entry.purpose.isNotEmpty) ...[
                const SizedBox(height: AppSizes.s4),
                Text(
                  'Purpose: ${entry.purpose}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          onTap: () {
            final page = entry.stockEntryType == 'Material Transfer'
                ? MaterialTransferDetailPage(entryName: entry.name)
                : MaterialIssueDetailPage(entryName: entry.name);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
        ),
      );
    }

    // Premium custom card layout for Material Issues matching _PurchaseReceiptCard
    double totalQty = entry.items.fold(0.0, (sum, item) => sum + item.qty);
    String qtyText = totalQty > 0
        ? '${totalQty.toStringAsFixed(0)} units'
        : '${entry.items.length} items';

    final double? perTransferred = entry.rawData['per_transferred'] != null
        ? (entry.rawData['per_transferred'] as num).toDouble()
        : null;
    final double percentage = perTransferred != null
        ? perTransferred / 100.0
        : 0.0;

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
                    MaterialIssueDetailPage(entryName: entry.name),
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
                      entry.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    StatusBadge(status: entry.status),
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
                            entry.fromWarehouse ?? entry.purpose,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: sizeContextOf(context, 4)),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: sizeContextOf(context, 4)),
                              Text(
                                entry.postingDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(entry.postingDate!)
                                    : 'Oct 24, 2023',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(width: sizeContextOf(context, 12)),
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
                          ).format(entry.totalOutgoingValue),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          entry.toWarehouse != null
                              ? 'To: ${entry.toWarehouse}'
                              : 'Issued Out',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (perTransferred != null) ...[
                          SizedBox(height: sizeContextOf(context, 2)),
                          Text(
                            'Transferred ${perTransferred.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (perTransferred != null) ...[
                  SizedBox(height: sizeContextOf(context, 8)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
