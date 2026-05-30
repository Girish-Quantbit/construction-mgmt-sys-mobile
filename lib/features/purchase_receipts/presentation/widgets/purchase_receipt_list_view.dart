import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/purchase_receipt_bloc.dart';
import '../bloc/purchase_receipt_event.dart';
import '../bloc/purchase_receipt_state.dart';
import '../pages/purchase_receipt_detail_page.dart';
import '../pages/purchase_receipt_form_page.dart';
import '../../domain/entities/purchase_receipt.dart';

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
    context.read<PurchaseReceiptBloc>().add(LoadPurchaseReceipts(project: widget.project));
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
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: BlocBuilder<PurchaseReceiptBloc, PurchaseReceiptState>(
              builder: (context, state) {
                if (state.status == PurchaseReceiptStatus.loading &&
                    state.receipts.isEmpty) {
                  return _buildLoadingSkeleton();
                }

                if (state.status == PurchaseReceiptStatus.failure &&
                    state.receipts.isEmpty) {
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
                            state.errorMessage ?? 'Error loading receipts',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSizes.s16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<PurchaseReceiptBloc>().add(
                                  LoadPurchaseReceipts(isRefresh: true, project: widget.project),
                                ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.receipts.isEmpty) {
                  return const Center(
                    child: Text('No purchase receipts found'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<PurchaseReceiptBloc>().add(
                      LoadPurchaseReceipts(isRefresh: true, project: widget.project),
                    );
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSizes.s16),
                    itemCount: state.hasReachedMax
                        ? state.receipts.length
                        : state.receipts.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.s12),
                    itemBuilder: (context, index) {
                      if (index >= state.receipts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizes.s8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final receipt = state.receipts[index];
                      return _PurchaseReceiptCard(receipt: receipt);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Receipt ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12,
                ),
              ),
              onChanged: (value) {
                context.read<PurchaseReceiptBloc>().add(SearchChanged(value));
              },
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          BlocBuilder<PurchaseReceiptBloc, PurchaseReceiptState>(
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.filterStatus,
                    hint: const Text('All Status'),
                    items:
                        [
                          'Draft',
                          'To Receive and Bill',
                          'To Bill',
                          'Completed',
                          'Cancelled',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      context.read<PurchaseReceiptBloc>().add(
                        FilterChanged(value),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(AppSizes.s16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.s12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSizes.r12),
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
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.r12),
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
          padding: const EdgeInsets.all(AppSizes.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    receipt.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _StatusBadge(status: receipt.status),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: Text(
                      receipt.supplier,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSizes.s4),
                      Text(
                        receipt.postingDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(receipt.postingDate!)
                            : '-',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: '₹',
                      decimalDigits: 0,
                    ).format(receipt.grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Draft':
        color = Colors.grey;
        break;
      case 'Completed':
        color = AppColors.success;
        break;
      case 'Cancelled':
        color = AppColors.error;
        break;
      case 'To Receive and Bill':
      case 'To Bill':
        color = AppColors.warning;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8,
        vertical: AppSizes.s4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
