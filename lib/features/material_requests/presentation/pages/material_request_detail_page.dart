import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/material_request_bloc.dart';
import '../bloc/material_request_event.dart';
import '../bloc/material_request_state.dart';
import 'material_request_form_page.dart';

class MaterialRequestDetailPage extends StatelessWidget {
  final String requestName;

  const MaterialRequestDetailPage({super.key, required this.requestName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<MaterialRequestBloc>()
            ..add(LoadMaterialRequestDetails(requestName)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Request: $requestName',
          actions: [
            BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
              builder: (context, state) {
                final request = state.selectedRequest;
                if (request == null) return const SizedBox.shrink();
                final docstatus = request.rawData['docstatus'];
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
                        builder: (context) => MaterialRequestFormPage(
                          requestName: requestName,
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      context.read<MaterialRequestBloc>().add(
                        LoadMaterialRequestDetails(requestName),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
          builder: (context, state) {
            if (state.detailStatus == MaterialRequestStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.detailStatus == MaterialRequestStatus.failure) {
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
                      onPressed: () => context.read<MaterialRequestBloc>().add(
                        LoadMaterialRequestDetails(requestName),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final request = state.selectedRequest;
            if (request == null) {
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
                  _buildGeneralInfoCard(request),
                  const SizedBox(height: AppSizes.s24),

                  _SectionHeader(
                    title: 'Requested Items',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildItemsCard(context, request),
                  const SizedBox(height: AppSizes.s32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(dynamic request) {
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
            _buildInfoRow('Status', request.status, isStatus: true),
            const Divider(height: AppSizes.s24),
            _buildInfoRow('Request Type', request.materialRequestType),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Transaction Date',
              request.transactionDate != null
                  ? DateFormat('MMM dd, yyyy').format(request.transactionDate!)
                  : '-',
            ),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Schedule Date',
              request.scheduleDate != null
                  ? DateFormat('MMM dd, yyyy').format(request.scheduleDate!)
                  : '-',
            ),
            const Divider(height: AppSizes.s24),
            _buildInfoRow('Price List', request.buyingPriceList ?? '-'),
            const Divider(height: AppSizes.s24),
            _buildInfoRow('Set Warehouse', request.setWarehouse ?? '-'),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Percentage Ordered',
              request.perOrdered != null
                  ? '${request.perOrdered!.toStringAsFixed(1)}%'
                  : '0.0%',
            ),
            const Divider(height: AppSizes.s24),
            _buildInfoRow(
              'Percentage Received',
              request.perReceived != null
                  ? '${request.perReceived!.toStringAsFixed(1)}%'
                  : '0.0%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, dynamic request) {
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
                DataColumn(label: Text('Item Code')),
                DataColumn(label: Text('Schedule Date')),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('UOM')),
              ],
              rows: (request.items as List).map<DataRow>((item) {
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
                              item.itemCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.scheduleDate != null
                            ? DateFormat('MMM dd, yyyy').format(item.scheduleDate!)
                            : '-',
                      ),
                    ),
                    DataCell(Text(item.qty.toString())),
                    DataCell(Text(item.warehouse ?? '-')),
                    DataCell(Text(item.uom ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
          if ((request.items as List).isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSizes.s16),
              child: Text('No items found'),
            ),
        ],
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
        case 'submitted':
          statusColor = AppColors.success;
          break;
        case 'draft':
          statusColor = Colors.grey;
          break;
        case 'cancelled':
          statusColor = AppColors.error;
          break;
        case 'stopped':
          statusColor = Colors.blueGrey;
          break;
        case 'partially ordered':
          statusColor = Colors.purple;
          break;
        case 'ordered':
          statusColor = Colors.teal;
          break;
        case 'issued':
          statusColor = Colors.lightBlue;
          break;
        case 'transferred':
        case 'received':
          statusColor = AppColors.success;
          break;
        case 'pending':
          statusColor = Colors.orange;
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
