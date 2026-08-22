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

class StockEntryDetailPage extends StatelessWidget {
  final String entryName;

  const StockEntryDetailPage({super.key, required this.entryName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<StockEntryBloc>()..add(LoadStockEntryDetails(entryName)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Stock Entry: $entryName',
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

                  if (entry.fromWarehouse != null ||
                      entry.toWarehouse != null) ...[
                    _SectionHeader(
                      title: 'Warehouse Details',
                      icon: Icons.warehouse_outlined,
                    ),
                    _buildWarehouseCard(entry),
                    const SizedBox(height: AppSizes.s24),
                  ],

                  _SectionHeader(
                    title: 'Items',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildItemsCard(context, entry),
                  const SizedBox(height: AppSizes.s24),

                  _buildLogisticsCard(entry),
                  _buildReferenceCard(entry),

                  _buildAdditionalInfoCard(entry),
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
            _buildInfoRow('Type', entry.stockEntryType),
            _buildInfoRow(
              'Posting Date',
              entry.postingDate != null
                  ? DateFormat('MMM dd, yyyy').format(entry.postingDate!)
                  : '-',
            ),
            _buildInfoRow('Purpose', entry.purpose),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseCard(StockEntry entry) {
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
            if (entry.fromWarehouse != null)
              _buildInfoRow('Source Warehouse', entry.fromWarehouse!),
            if (entry.fromWarehouse != null && entry.toWarehouse != null)
              const Divider(height: AppSizes.s16),
            if (entry.toWarehouse != null)
              _buildInfoRow('Target Warehouse', entry.toWarehouse!),
          ],
        ),
      ),
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

  Widget _buildReferenceCard(StockEntry entry) {
    final Map<String, dynamic> data = entry.rawData;
    final refFields = {
      'project': 'Project',
      'remarks': 'Remarks',
      'naming_series': 'Series',
      'job_card': 'Job Card',
      'work_order': 'Work Order',
    };

    final fieldsToShow = data.entries
        .where(
          (e) =>
              refFields.containsKey(e.key) &&
              e.value != null &&
              e.value.toString().isNotEmpty,
        )
        .toList();

    if (fieldsToShow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Reference Information',
          icon: Icons.assignment_outlined,
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
                return _buildInfoRow(refFields[e.key]!, e.value.toString());
              }).toList(),
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
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('UOM')),
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
                    DataCell(Text(item.qty.toString())),
                    DataCell(Text(item.uom)),
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

  Widget _buildAdditionalInfoCard(StockEntry entry) {
    final Map<String, dynamic> data = entry.rawData;
    final excludedFields = {
      'name',
      'stock_entry_type',
      'posting_date',
      'purpose',
      'status',
      'from_warehouse',
      'to_warehouse',
      'items',
      'total_incoming_value',
      'total_outgoing_value',
      'doctype',
      'owner',
      'creation',
      'modified',
      'modified_by',
      'docstatus',
      'idx',
      'transporter_name',
      'vehicle_no',
      'lr_no',
      'lr_date',
      'project',
      'remarks',
      'naming_series',
      'job_card',
      'work_order',
    };

    final fieldsToShow = data.entries
        .where(
          (e) =>
              !excludedFields.contains(e.key) &&
              e.value != null &&
              e.value.toString().isNotEmpty &&
              e.value is! List &&
              e.value is! Map,
        )
        .toList();

    if (fieldsToShow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Additional Information', icon: Icons.more_horiz),
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
                String label = e.key
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map(
                      (s) => s.isNotEmpty
                          ? s[0].toUpperCase() + s.substring(1)
                          : '',
                    )
                    .join(' ');
                return _buildInfoRow(label, e.value.toString());
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
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
        style: const TextStyle(fontSize: 14),
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
