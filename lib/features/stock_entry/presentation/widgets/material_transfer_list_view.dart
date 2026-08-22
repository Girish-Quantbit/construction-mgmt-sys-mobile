import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/stock_entry_bloc.dart';
import '../bloc/stock_entry_event.dart';
import '../bloc/stock_entry_state.dart';
import '../pages/material_transfer_detail_page.dart';
import '../../domain/entities/stock_entry.dart';
import '../pages/stock_entry_form_page.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sort_chips.dart';
import '../../../../core/widgets/filter_button.dart';

class MaterialTransferListView extends StatefulWidget {
  final String? project;
  const MaterialTransferListView({super.key, this.project});

  @override
  State<MaterialTransferListView> createState() =>
      _MaterialTransferListViewState();
}

class _MaterialTransferListViewState extends State<MaterialTransferListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterSourceWarehouse = 'All';
  String _filterTargetWarehouse = 'All';
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<StockEntryBloc>().add(
      LoadStockEntries(
        isRefresh: true,
        stockEntryType: 'Material Transfer',
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
          stockEntryType: 'Material Transfer',
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
      title: const Text(
        'Material Transfers',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [FilterIconButton(onTap: () => _showFilterBottomSheet(context))],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final entries = context.read<StockEntryBloc>().state.entries;
    final sourceWarehouses =
        entries
            .map((e) => e.fromWarehouse)
            .whereType<String>()
            .where((w) => w.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final targetWarehouses =
        entries
            .map((e) => e.toWarehouse)
            .whereType<String>()
            .where((w) => w.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    String? selectedStatus = _filterStatus == 'All' ? null : _filterStatus;
    String? selectedSource = _filterSourceWarehouse == 'All'
        ? null
        : _filterSourceWarehouse;
    String? selectedTarget = _filterTargetWarehouse == 'All'
        ? null
        : _filterTargetWarehouse;

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
              title: 'Filter Material Transfers',
              onReset: () {
                setState(() {
                  _filterStatus = 'All';
                  _filterSourceWarehouse = 'All';
                  _filterTargetWarehouse = 'All';
                });
              },
              onApply: () {
                setState(() {
                  _filterStatus = selectedStatus ?? 'All';
                  _filterSourceWarehouse = selectedSource ?? 'All';
                  _filterTargetWarehouse = selectedTarget ?? 'All';
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
                SizedBox(height: sizeContextOf(context, 16)),
                FilterDropdownSelector(
                  title: 'Source Warehouse',
                  hintText: 'Select Source Warehouse',
                  value: selectedSource,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Source Warehouse'),
                        children: sourceWarehouses
                            .map(
                              (wh) => SimpleDialogOption(
                                onPressed: () {
                                  setModalState(() {
                                    selectedSource = wh;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text(wh),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                FilterDropdownSelector(
                  title: 'Target Warehouse',
                  hintText: 'Select Target Warehouse',
                  value: selectedTarget,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Target Warehouse'),
                        children: targetWarehouses
                            .map(
                              (wh) => SimpleDialogOption(
                                onPressed: () {
                                  setModalState(() {
                                    selectedTarget = wh;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text(wh),
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
                        state.errorMessage ??
                            'Failed to load material transfers',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.s16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<StockEntryBloc>().add(
                            LoadStockEntries(
                              isRefresh: true,
                              stockEntryType: 'Material Transfer',
                              project: widget.project,
                            ),
                          );
                        },
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
                      stockEntryType: 'Material Transfer',
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
                      _buildSortChips(),
                      SizedBox(height: sizeContextOf(context, 16)),
                      if (displayEntries.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: sizeContextOf(context, 40.0),
                          ),
                          child: Center(
                            child: Text(
                              'No material transfers found',
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
                            return _MaterialTransferCard(
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
          (entry.fromWarehouse ?? '').toLowerCase().contains(query) ||
          (entry.toWarehouse ?? '').toLowerCase().contains(query);

      final matchesStatus =
          _filterStatus == 'All' ||
          entry.status.toLowerCase() == _filterStatus.toLowerCase();

      final matchesSourceWarehouse =
          _filterSourceWarehouse == 'All' ||
          (entry.fromWarehouse ?? '').toLowerCase() ==
              _filterSourceWarehouse.toLowerCase();

      final matchesTargetWarehouse =
          _filterTargetWarehouse == 'All' ||
          (entry.toWarehouse ?? '').toLowerCase() ==
              _filterTargetWarehouse.toLowerCase();

      return matchesSearch &&
          matchesStatus &&
          matchesSourceWarehouse &&
          matchesTargetWarehouse;
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
        case 'status_asc':
          return a.status.compareTo(b.status);
        case 'status_desc':
          return b.status.compareTo(a.status);
        case 'id_desc':
          return b.name.compareTo(a.name);
        case 'id_asc':
          return a.name.compareTo(b.name);
        case 'from_warehouse_asc':
          return (a.fromWarehouse ?? '').compareTo(b.fromWarehouse ?? '');
        case 'from_warehouse_desc':
          return (b.fromWarehouse ?? '').compareTo(a.fromWarehouse ?? '');
        case 'to_warehouse_asc':
          return (a.toWarehouse ?? '').compareTo(b.toWarehouse ?? '');
        case 'to_warehouse_desc':
          return (b.toWarehouse ?? '').compareTo(a.toWarehouse ?? '');
        default:
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildSummaryCard(List<StockEntry> entries) {
    int totalTransfers = entries.length;
    int draftTransfers = entries
        .where((e) => e.status.toLowerCase() == 'draft')
        .length;
    double totalValue = entries.fold(0.0, (sum, e) {
      final val = e.rawData['base_grand_total'] ?? e.totalIncomingValue;
      return sum + (val is num ? val.toDouble() : 0.0);
    });

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
                      'Total Transfers',
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
                      '$totalTransfers',
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
                      'Draft Transfers',
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
                      '$draftTransfers',
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
              builder: (context) =>
                  const StockEntryFormPage(stockEntryType: 'Material Transfer'),
            ),
          );

          if (result == true && context.mounted) {
            context.read<StockEntryBloc>().add(
              LoadStockEntries(
                isRefresh: true,
                stockEntryType: 'Material Transfer',
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
            '+ Create Material Transfer',
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

class _MaterialTransferCard extends StatelessWidget {
  final StockEntry entry;

  const _MaterialTransferCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    double totalQty = entry.items.fold(0.0, (sum, item) => sum + item.qty);
    String qtyText = totalQty > 0
        ? '${totalQty.toStringAsFixed(0)} units'
        : '${entry.items.length} items';

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
                    MaterialTransferDetailPage(entryName: entry.name),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.fromWarehouse ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: sizeContextOf(context, 4.0),
                                ),
                                child: Icon(
                                  Icons.trending_flat,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.toWarehouse ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                          ).format(
                            (entry.rawData['base_grand_total'] as num?)
                                    ?.toDouble() ??
                                entry.totalIncomingValue,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          entry.purpose.isNotEmpty ? entry.purpose : 'Transfer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
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
