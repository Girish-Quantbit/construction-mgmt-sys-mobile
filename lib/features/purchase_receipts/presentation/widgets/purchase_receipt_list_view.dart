import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/purchase_receipt_bloc.dart';
import '../bloc/purchase_receipt_event.dart';
import '../bloc/purchase_receipt_state.dart';
import '../pages/purchase_receipt_detail_page.dart';
import '../pages/purchase_receipt_form_page.dart';
import '../../domain/entities/purchase_receipt.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sort_chips.dart';
import '../../../../core/widgets/filter_button.dart';

class PurchaseReceiptListView extends StatefulWidget {
  final String? project;
  const PurchaseReceiptListView({super.key, this.project});

  @override
  State<PurchaseReceiptListView> createState() =>
      _PurchaseReceiptListViewState();
}

class _PurchaseReceiptListViewState extends State<PurchaseReceiptListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<PurchaseReceiptBloc>().add(
      LoadPurchaseReceipts(project: widget.project),
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
      context.read<PurchaseReceiptBloc>().add(LoadMorePurchaseReceipts());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: _buildAppBar(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              context.read<PurchaseReceiptBloc>().add(
                LoadPurchaseReceipts(isRefresh: true, project: widget.project),
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: sizeContextOf(context, 16),
                right: sizeContextOf(context, 16),
                top: sizeContextOf(context, 0),
                bottom: sizeContextOf(
                  context,
                  100,
                ), // Safe padding for bottom button
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // _buildSummaryCard(),
                  // SizedBox(height: sizeContextOf(context, 16)),
                  // _buildSearchBar(),
                  // SizedBox(height: sizeContextOf(context, 16)),
                  // _buildSearchBar(),
                  // SizedBox(height: sizeContextOf(context, 16)),
                  _buildSortChips(),
                  SizedBox(height: sizeContextOf(context, 16)),
                  _buildReceiptList(),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
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
        'Purchase Receipts',
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
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final bloc = context.read<PurchaseReceiptBloc>();
    final currentState = bloc.state;

    String? selectedStatus = currentState.filterStatus;
    String? enteredSupplier = currentState.filterSupplier;
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
              title: 'Filter Receipts',
              onReset: () {
                bloc.add(ClearFilters());
              },
              onApply: () {
                bloc.add(
                  ApplyFilters(
                    status: selectedStatus,
                    supplier: enteredSupplier?.trim(),
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
                        children:
                            [
                                  'Draft',
                                  'To Bill',
                                  'To Receive and Bill',
                                  'Completed',
                                  'Cancelled',
                                ]
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
                FilterDropdownSelector(
                  title: 'Supplier',
                  hintText: 'Select Supplier...',
                  value: enteredSupplier,
                  onTap: () {
                    _showSupplierSelector(context, (val) {
                      setModalState(() {
                        enteredSupplier = val;
                      });
                    });
                  },
                ),
                FilterDateRangePicker(
                  title: 'Date Range',
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

  Widget _buildSummaryCard() {
    return BlocBuilder<PurchaseReceiptBloc, PurchaseReceiptState>(
      builder: (context, state) {
        int totalReceipts = state.receipts.length;
        int toBilled = state.receipts
            .where(
              (r) => r.status == 'To Bill' || r.status == 'To Receive and Bill',
            )
            .length;
        double totalValue = state.receipts.fold(
          0.0,
          (sum, r) => sum + r.grandTotal,
        );
        String formattedValue = '';
        if (totalValue >= 1000) {
          formattedValue = '₹${(totalValue / 1000).toStringAsFixed(1)}k';
        } else {
          formattedValue = '₹${totalValue.toStringAsFixed(0)}';
        }

        if (state.status == PurchaseReceiptStatus.loading &&
            state.receipts.isEmpty) {
          totalReceipts = 0;
          toBilled = 14;
          formattedValue = '₹42.5k';
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
                          'Total Receipts',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      // SizedBox(height: sizeContextOf(context, 8)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$totalReceipts',
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
                          'To Billed',
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
                          '$toBilled',
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
      },
    );
  }

  // Widget _buildSearchBar() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(30),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: TextField(
  //       controller: _searchController,
  //       decoration: InputDecoration(
  //         hintText: 'Search receipt, supplier, or site...',
  //         hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
  //         prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
  //         border: InputBorder.none,
  //         contentPadding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 20), vertical: sizeContextOf(context, 14)),
  //       ),
  //       onChanged: (value) {
  //         context.read<PurchaseReceiptBloc>().add(SearchChanged(value));
  //       },
  //     ),
  //   );
  // }

  Widget _buildSortChips() {
    return BlocBuilder<PurchaseReceiptBloc, PurchaseReceiptState>(
      builder: (context, state) {
        return SortChips(
          sortBy: '${state.sortBy}_${state.sortOrder}',
          options: const [
            SortOption(label: 'Date', field: 'posting_date'),
            SortOption(label: 'Supplier Name', field: 'supplier'),
            SortOption(label: 'Amount', field: 'grand_total'),
            SortOption(label: 'Status', field: 'status'),
          ],
          onSortChanged: (newSort) {
            final parts = newSort.split('_');
            final order = parts.last;
            final field = parts.sublist(0, parts.length - 1).join('_');
            context.read<PurchaseReceiptBloc>().add(
              SortChanged(sortBy: field, sortOrder: order),
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptList() {
    return BlocBuilder<PurchaseReceiptBloc, PurchaseReceiptState>(
      builder: (context, state) {
        if (state.status == PurchaseReceiptStatus.loading &&
            state.receipts.isEmpty) {
          return _buildLoadingSkeleton();
        }

        if (state.status == PurchaseReceiptStatus.failure &&
            state.receipts.isEmpty) {
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
                  state.errorMessage ?? 'Error loading receipts',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s16),
                ElevatedButton(
                  onPressed: () => context.read<PurchaseReceiptBloc>().add(
                    LoadPurchaseReceipts(
                      isRefresh: true,
                      project: widget.project,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.receipts.isEmpty) {
          return const Center(child: Text('No purchase receipts found'));
        }

        final receipts = state.receipts;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.hasReachedMax
              ? receipts.length
              : receipts.length + 1,
          separatorBuilder: (context, index) =>
              SizedBox(height: sizeContextOf(context, 16)),
          itemBuilder: (context, index) {
            if (index >= receipts.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.s8),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _PurchaseReceiptCard(receipt: receipts[index]);
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: sizeContextOf(context, 16)),
        child: Container(
          height: 160,
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
              builder: (context) => const PurchaseReceiptFormPage(),
            ),
          );

          if (result == true && context.mounted) {
            context.read<PurchaseReceiptBloc>().add(
              LoadPurchaseReceipts(isRefresh: true, project: widget.project),
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
            '+ Upload New Receipt',
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

class _PurchaseReceiptCard extends StatelessWidget {
  final PurchaseReceipt receipt;

  const _PurchaseReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    double percentageBilled = 0.0;
    if (receipt.status == 'Completed') {
      percentageBilled = 1.0;
    } else if (receipt.status == 'To Receive and Bill') {
      percentageBilled = 0.5;
    } else if (receipt.status == 'To Bill') {
      percentageBilled = 0.8;
    } else if (receipt.status == 'Draft') {
      percentageBilled = 0.0;
    }

    double totalQty = receipt.totalQty ?? 0.0;
    if (totalQty == 0) {
      if (receipt.items.isNotEmpty) {
        totalQty = receipt.items.fold(0.0, (sum, item) => sum + item.qty);
      } else if (receipt.rawData.containsKey('total_qty')) {
        totalQty = (receipt.rawData['total_qty'] as num).toDouble();
      } else {
        totalQty = 450;
      }
    }
    String qtyText = totalQty > 0
        ? '${totalQty.toStringAsFixed(0)} Qty'
        : '450 Qty';

    if (receipt.rawData.containsKey('per_billed')) {
      percentageBilled =
          (receipt.rawData['per_billed'] as num).toDouble() / 100.0;
    }

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
                    PurchaseReceiptDetailPage(receiptName: receipt.name),
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
                      receipt.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    StatusBadge(status: receipt.status),
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
                            (receipt.supplierName != null &&
                                    receipt.supplierName!.isNotEmpty)
                                ? receipt.supplierName!
                                : receipt.supplier,
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
                                receipt.postingDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(receipt.postingDate!)
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
                          ).format(receipt.grandTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          'Billed ${(percentageBilled * 100).toInt()}%',
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
                SizedBox(height: sizeContextOf(context, 8)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentageBilled,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showSupplierSelector(
  BuildContext context,
  ValueChanged<String> onSelected,
) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return _SupplierSearchBottomSheet(
        onSelected: (val) {
          Navigator.pop(sheetContext);
          onSelected(val);
        },
      );
    },
  );
}

class _SupplierSearchBottomSheet extends StatefulWidget {
  final ValueChanged<String> onSelected;
  const _SupplierSearchBottomSheet({required this.onSelected});

  @override
  State<_SupplierSearchBottomSheet> createState() =>
      _SupplierSearchBottomSheetState();
}

class _SupplierSearchBottomSheetState
    extends State<_SupplierSearchBottomSheet> {
  final _searchController = TextEditingController();
  List<LinkOptionEntity> _options = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOptions([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sdk = sl<FrappeSDK>();
      final List<List<dynamic>> filters = [];
      if (query.isNotEmpty) {
        filters.add(['Supplier', 'supplier_name', 'like', '%$query%']);
      }
      final options = await sdk.linkOptions.getLinkOptions(
        'Supplier',
        filters: filters.isNotEmpty ? filters : null,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: sizeContextOf(context, 16),
        left: sizeContextOf(context, 16),
        right: sizeContextOf(context, 16),
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Supplier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: sizeContextOf(context, 12)),
          TextField(
            controller: _searchController,
            onChanged: (val) => _fetchOptions(val),
            decoration: InputDecoration(
              hintText: 'Search Supplier...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(
                horizontal: sizeContextOf(context, 12),
                vertical: sizeContextOf(context, 12),
              ),
              filled: true,
              fillColor: const Color(0xFFF2FAF6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: sizeContextOf(context, 16)),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _options.isEmpty
                ? const Center(child: Text('No suppliers found'))
                : ListView.builder(
                    itemCount: _options.length,
                    itemBuilder: (context, idx) {
                      final option = _options[idx];
                      return ListTile(
                        title: Text(option.label ?? option.name),
                        subtitle: Text(option.name),
                        onTap: () => widget.onSelected(option.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
