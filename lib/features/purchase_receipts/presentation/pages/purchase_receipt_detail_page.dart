import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/purchase_receipt_bloc.dart';
import '../bloc/purchase_receipt_event.dart';
import '../bloc/purchase_receipt_state.dart';
import 'purchase_receipt_form_page.dart';

class PurchaseReceiptDetailPage extends StatelessWidget {
  final String receiptName;

  const PurchaseReceiptDetailPage({super.key, required this.receiptName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<PurchaseReceiptBloc>()
            ..add(LoadPurchaseReceiptDetails(receiptName)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Receipt: $receiptName',
          actions: [
            BlocBuilder<PurchaseReceiptBloc, PurchaseReceiptState>(
              builder: (context, state) {
                final receipt = state.selectedReceipt;
                if (receipt == null) return const SizedBox.shrink();
                final docstatus = receipt.rawData['docstatus'];
                final isSubmitted = docstatus == 1 || docstatus == '1' || docstatus == 1.0;

                if (isSubmitted) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Text(
                        'Submitted',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                return IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PurchaseReceiptFormPage(
                          receiptName: receiptName,
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      context.read<PurchaseReceiptBloc>().add(
                        LoadPurchaseReceiptDetails(receiptName),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<PurchaseReceiptBloc, PurchaseReceiptState>(
          builder: (context, state) {
            if (state.detailStatus == PurchaseReceiptStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.detailStatus == PurchaseReceiptStatus.failure) {
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
                    Text(state.errorMessage ?? 'Error loading details'),
                    const SizedBox(height: AppSizes.s16),
                    ElevatedButton(
                      onPressed: () => context.read<PurchaseReceiptBloc>().add(
                        LoadPurchaseReceiptDetails(receiptName),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final receipt = state.selectedReceipt;
            if (receipt == null) {
              return const Center(child: Text('No details found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'General Information',
                    icon: Icons.info_outline,
                  ),
                  _buildGeneralInfoCard(receipt),
                  const SizedBox(height: AppSizes.s24),

                  _SectionHeader(
                    title: 'Supplier Details',
                    icon: Icons.business_outlined,
                  ),
                  _buildSupplierCard(receipt),
                  const SizedBox(height: AppSizes.s24),

                  _SectionHeader(
                    title: 'Items',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildItemsCard(context, receipt),
                  const SizedBox(height: AppSizes.s24),

                  _buildLogisticsCard(receipt),

                  _buildTaxesCard(receipt),

                  _SectionHeader(
                    title: 'Financial Summary',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _buildSummaryCard(receipt),
                  const SizedBox(height: AppSizes.s32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(dynamic receipt) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          children: [
            _buildInfoRow('Status', receipt.status, isStatus: true),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Posting Date',
              receipt.postingDate != null
                  ? DateFormat('MMM dd, yyyy').format(receipt.postingDate!)
                  : '-',
            ),
            _buildInfoRow('Project', receipt.rawData['project'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard(dynamic receipt) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          children: [
            _buildInfoRow('Supplier', receipt.supplier),
            if (receipt.supplierAddress != null) ...[
              const Divider(height: AppSizes.s16),
              _buildInfoRow('Address', receipt.supplierAddress!),
            ],
            if (receipt.contactPerson != null) ...[
              const Divider(height: AppSizes.s16),
              _buildInfoRow('Contact', receipt.contactPerson!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsCard(dynamic receipt) {
    final Map<String, dynamic> data = receipt.rawData;
    final logisticsFields = {
      'shipping_address': 'Shipping Address',
      'set_warehouse': 'Target Warehouse',
      'rejected_warehouse': 'Rejected Warehouse',
      'incoterm': 'Incoterm',
    };

    final fieldsToShow = data.entries
        .where(
          (e) =>
              logisticsFields.containsKey(e.key) &&
              e.value != null &&
              e.value.toString().isNotEmpty,
        )
        .toList();

    if (fieldsToShow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Logistics Details',
          icon: Icons.local_shipping_outlined,
        ),
        Card(
          elevation: 0,
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r12),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s16),
            child: Column(
              children: fieldsToShow.map((e) {
                return _buildInfoRow(
                  logisticsFields[e.key]!,
                  e.value.toString(),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.s24),
      ],
    );
  }

  Widget _buildTaxesCard(dynamic receipt) {
    final Map<String, dynamic> data = receipt.rawData;
    final List<dynamic> taxes = data['taxes'] ?? [];

    if (taxes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Taxes and Charges',
          icon: Icons.receipt_long_outlined,
        ),
        Card(
          elevation: 0,
          color: AppColors.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r12),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.surfaceContainer,
                  ),
                  horizontalMargin: AppSizes.s16,
                  columnSpacing: AppSizes.s24,
                  columns: const [
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Account Head')),
                    DataColumn(label: Text('Rate'), numeric: true),
                    DataColumn(label: Text('Amount'), numeric: true),
                  ],
                  rows: taxes.map<DataRow>((tax) {
                    return DataRow(
                      cells: [
                        DataCell(Text(tax['charge_type'] ?? '-')),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              tax['account_head'] ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text('${tax['rate']?.toString() ?? '0'}%')),
                        DataCell(
                          Text(
                            NumberFormat.currency(
                              symbol: '₹',
                              decimalDigits: 0,
                            ).format(tax['tax_amount'] ?? 0),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.s24),
      ],
    );
  }

  Widget _buildItemsCard(BuildContext context, dynamic receipt) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 64,
              dataRowMaxHeight: 64,
              headingRowColor: WidgetStateProperty.all(
                AppColors.surfaceContainer,
              ),
              horizontalMargin: AppSizes.s16,
              columnSpacing: AppSizes.s24,
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('Rate'), numeric: true),
                DataColumn(label: Text('Amount'), numeric: true),
              ],
              rows: (receipt.items as List).map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.s8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.itemCode,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(item.qty.toString())),
                    DataCell(
                      Text(
                        NumberFormat.currency(
                          symbol: '₹',
                          decimalDigits: 0,
                        ).format(item.rate),
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberFormat.currency(
                          symbol: '₹',
                          decimalDigits: 0,
                        ).format(item.amount),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if ((receipt.items as List).isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSizes.s16),
              child: Text('No items found'),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(dynamic receipt) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          children: [
            _buildInfoRow(
              'Base Grand Total',
              NumberFormat.currency(symbol: '₹').format(receipt.baseGrandTotal),
            ),
            _buildInfoRow(
              'Taxes and Charges',
              NumberFormat.currency(
                symbol: '₹',
              ).format(receipt.taxesAndCharges),
            ),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Grand Total',
              NumberFormat.currency(symbol: '₹').format(receipt.grandTotal),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isBold = false,
  }) {
    Widget valueWidget;
    if (isStatus) {
      Color statusColor;
      switch (value.toLowerCase()) {
        case 'completed':
          statusColor = AppColors.success;
          break;
        case 'draft':
          statusColor = AppColors.warning;
          break;
        case 'cancelled':
          statusColor = AppColors.error;
          break;
        default:
          statusColor = AppColors.primary;
      }
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      valueWidget = Text(
        value,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 16 : 14,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSizes.s16),
          Flexible(child: valueWidget),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12, left: AppSizes.s4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSizes.s8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
