import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/stock_entry.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/stock_entry_bloc.dart';
import '../bloc/stock_entry_event.dart';
import '../bloc/stock_entry_state.dart';
import 'material_transfer_form_page.dart';

class MaterialTransferDetailPage extends StatelessWidget {
  final String entryName;

  const MaterialTransferDetailPage({super.key, required this.entryName});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MaterialTransferDetailPage for $entryName');
    return BlocProvider(
      create: (context) =>
          sl<StockEntryBloc>()..add(LoadStockEntryDetails(entryName)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Material Transfer: $entryName',
          actions: [
            BlocBuilder<StockEntryBloc, StockEntryState>(
              builder: (context, state) {
                final entry = state.selectedEntry;
                if (entry == null) return const SizedBox.shrink();
                final docstatus = entry.rawData['docstatus'];
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
                        builder: (context) => MaterialTransferFormPage(
                          stockEntryType: 'Material Transfer',
                          entryName: entryName,
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      context.read<StockEntryBloc>().add(
                        LoadStockEntryDetails(entryName),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<StockEntryBloc, StockEntryState>(
          builder: (context, state) {
            if (state.detailStatus == StockEntryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.detailStatus == StockEntryStatus.failure) {
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
                      onPressed: () => context.read<StockEntryBloc>().add(
                        LoadStockEntryDetails(entryName),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final entry = state.selectedEntry;
            if (entry == null) {
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
                  _buildGeneralInfoCard(entry),
                  const SizedBox(height: AppSizes.s24),

                  _SectionHeader(
                    title: 'Transfer Details',
                    icon: Icons.swap_horiz,
                  ),
                  _buildTransferCard(entry),
                  const SizedBox(height: AppSizes.s24),

                  _buildAccountingDimensionsCard(entry),

                  _SectionHeader(
                    title: 'Items',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildItemsCard(context, entry),
                  const SizedBox(height: AppSizes.s24),

                  _buildLogisticsCard(entry),

                  _SectionHeader(
                    title: 'Value Summary',
                    icon: Icons.summarize_outlined,
                  ),
                  _buildSummaryCard(entry),
                  const SizedBox(height: AppSizes.s24),

                  _buildOtherInfoCard(entry),

                  const SizedBox(height: AppSizes.s32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(StockEntry entry) {
    final data = entry.rawData;
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
            _buildInfoRow('Status', entry.status, isStatus: true),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Posting Date',
              entry.postingDate != null
                  ? DateFormat('dd-MM-yyyy').format(entry.postingDate!)
                  : '-',
            ),
            _buildInfoRow('Posting Time', data['posting_time'] ?? '-'),
            _buildInfoRow('Purpose', entry.purpose),
            if (data['add_to_transit'] != null)
              _buildCheckboxRow('Add to Transit', data['add_to_transit'] == 1),
            if (data['apply_putaway_rule'] != null)
              _buildCheckboxRow(
                'Apply Putaway Rule',
                data['apply_putaway_rule'] == 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferCard(StockEntry entry) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Source',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    entry.fromWarehouse ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.s8),
              child: Icon(Icons.arrow_forward, color: AppColors.primary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Default Target',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    entry.toWarehouse ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountingDimensionsCard(StockEntry entry) {
    final data = entry.rawData;
    if (data['project'] == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Accounting Dimensions',
          icon: Icons.account_balance_outlined,
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
              children: [_buildInfoRow('Project', data['project'] ?? '-')],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.s24),
      ],
    );
  }

  Widget _buildItemsCard(BuildContext context, StockEntry entry) {
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
              dataRowMaxHeight: 80,
              headingRowColor: WidgetStateProperty.all(
                AppColors.surfaceContainer,
              ),
              horizontalMargin: AppSizes.s16,
              columnSpacing: AppSizes.s24,
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Source Warehouse')),
                DataColumn(label: Text('Target Warehouse')),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('Rate'), numeric: true),
                DataColumn(label: Text('Amount'), numeric: true),
              ],
              rows: entry.items.map<DataRow>((item) {
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
                    DataCell(Text(item.sWarehouse ?? '-')),
                    DataCell(Text(item.tWarehouse ?? '-')),
                    DataCell(Text(item.qty.toString())),
                    DataCell(
                      Text(
                        NumberFormat.currency(
                          symbol: '₹',
                          decimalDigits: 0,
                        ).format(item.basicRate),
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
          if (entry.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSizes.s16),
              child: Text('No items found'),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(StockEntry entry) {
    final data = entry.rawData;
    final difference = entry.totalIncomingValue - entry.totalOutgoingValue;
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
              'Total Estimated Taxes',
              NumberFormat.currency(
                symbol: '₹',
              ).format(data['total_estimated_taxes'] ?? 0),
            ),
            _buildInfoRow(
              'Grand Total',
              NumberFormat.currency(
                symbol: '₹',
              ).format(data['grand_total'] ?? 0),
              isBold: true,
            ),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Total Outgoing (Consumption)',
              NumberFormat.currency(
                symbol: '₹',
              ).format(entry.totalOutgoingValue),
            ),
            _buildInfoRow(
              'Total Incoming (Receipt)',
              NumberFormat.currency(
                symbol: '₹',
              ).format(entry.totalIncomingValue),
            ),
            _buildInfoRow(
              'Value Difference',
              NumberFormat.currency(symbol: '₹').format(difference),
              isBold: true,
              valueColor: difference != 0 ? AppColors.error : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherInfoCard(StockEntry entry) {
    final data = entry.rawData;
    final otherFields = {
      'is_opening': 'Is Opening',
      'per_transferred': 'Per Transferred',
      'total_amount': 'Total Amount',
    };

    final fieldsToShow = data.entries
        .where(
          (e) =>
              otherFields.containsKey(e.key) &&
              e.value != null &&
              e.value.toString().isNotEmpty,
        )
        .toList();

    if (fieldsToShow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Other Information', icon: Icons.more_outlined),
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
                String value = e.value.toString();
                if (e.key == 'per_transferred') value = '$value%';
                if (e.key == 'total_amount') {
                  value = NumberFormat.currency(symbol: '₹').format(e.value);
                }
                if (e.key == 'is_opening') {
                  value = (e.value == 1 || e.value == 'Yes') ? 'Yes' : 'No';
                }
                return _buildInfoRow(otherFields[e.key]!, value);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.s24),
      ],
    );
  }

  Widget _buildLogisticsCard(StockEntry entry) {
    final Map<String, dynamic> data = entry.rawData;
    final logisticsFields = {
      'transporter_name': 'Transporter',
      'vehicle_no': 'Vehicle No',
      'lr_no': 'LR No',
      'lr_date': 'LR Date',
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

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isBold = false,
    Color? valueColor,
  }) {
    Widget valueWidget;
    if (isStatus) {
      Color statusColor;
      switch (value.toLowerCase()) {
        case 'submitted':
          statusColor = AppColors.success;
          break;
        case 'draft':
          statusColor = AppColors.warning;
          break;
        case 'cancelled':
          statusColor = AppColors.error;
          break;
        default:
          statusColor = AppColors.outline;
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
          fontSize: isBold ? 15 : 14,
          color: valueColor,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s4),
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

  Widget _buildCheckboxRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s4),
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
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value ? AppColors.primary : AppColors.outline,
            size: 20,
          ),
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
