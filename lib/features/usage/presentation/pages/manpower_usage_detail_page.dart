import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/manpower_usage_bloc.dart';
import '../bloc/manpower_usage_event.dart';
import '../bloc/manpower_usage_state.dart';
import 'manpower_usage_form_page.dart';

class ManpowerUsageDetailPage extends StatelessWidget {
  final String usageName;

  const ManpowerUsageDetailPage({super.key, required this.usageName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ManpowerUsageBloc>()..add(LoadManpowerUsageDetails(usageName)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Manpower: $usageName',
          actions: [
            BlocBuilder<ManpowerUsageBloc, ManpowerUsageState>(
              builder: (context, state) {
                final usage = state.selectedUsage;
                if (usage == null) return const SizedBox.shrink();
                final docstatus = usage.rawData['docstatus'];
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
                        builder: (context) => ManpowerUsageFormPage(
                          usageName: usageName,
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      context.read<ManpowerUsageBloc>().add(
                        LoadManpowerUsageDetails(usageName),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ManpowerUsageBloc, ManpowerUsageState>(
          builder: (context, state) {
            if (state.detailStatus == ManpowerUsageStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.detailStatus == ManpowerUsageStatus.failure) {
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
                      onPressed: () => context.read<ManpowerUsageBloc>().add(
                        LoadManpowerUsageDetails(usageName),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final usage = state.selectedUsage;
            if (usage == null) {
              return const Center(child: Text('No details found'));
            }

            return FutureBuilder<DocTypeMeta>(
              future: sl<FrappeSDK>().meta.getMeta('Manpower Usage'),
              builder: (context, metaSnapshot) {
                final meta = metaSnapshot.data;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'General Information',
                        icon: Icons.info_outline,
                      ),
                      _buildGeneralInfoCard(usage, meta),
                      const SizedBox(height: AppSizes.s24),
                      _SectionHeader(
                        title: 'Manpower Usage',
                        icon: Icons.people_outline,
                      ),
                      _buildItemsCard(context, usage),
                      const SizedBox(height: AppSizes.s32),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(dynamic usage, DocTypeMeta? meta) {
    final List<Widget> children = [];

    // Always show Status first
    children.add(_buildInfoRow('Status', usage.status, isStatus: true));
    children.add(const Divider(height: AppSizes.s24));

    if (meta != null) {
      // Get all fields that are data fields, not child tables, and not hidden, and not amended_from/status/docstatus
      final fields = meta.fields
          .where(
            (f) =>
                f.fieldname != null &&
                f.isDataField &&
                f.fieldtype != 'Table' &&
                f.fieldtype != 'Table MultiSelect' &&
                f.fieldname != 'amended_from' &&
                f.fieldname != 'status' &&
                f.fieldname != 'docstatus',
          )
          .toList();

      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        final val = usage.rawData[field.fieldname];
        if (val != null && val.toString().isNotEmpty) {
          String displayVal = val.toString();
          if (field.fieldtype == 'Date' || field.fieldtype == 'Date Time') {
            final parsedDate = DateTime.tryParse(displayVal);
            if (parsedDate != null) {
              displayVal = DateFormat('MMM dd, yyyy').format(parsedDate);
            }
          }
          children.add(_buildInfoRow(field.displayLabel, displayVal));
          if (i < fields.length - 1) {
            children.add(const Divider(height: AppSizes.s16));
          }
        }
      }
    } else {
      // Fallback if metadata is not loaded yet
      children.add(
        _buildInfoRow(
          'Site Date',
          usage.siteDate != null
              ? DateFormat('MMM dd, yyyy').format(usage.siteDate!)
              : '-',
        ),
      );
      children.add(const Divider(height: AppSizes.s16));
      children.add(_buildInfoRow('Project', usage.project));
      if (usage.rawData['company'] != null) {
        children.add(const Divider(height: AppSizes.s16));
        children.add(
          _buildInfoRow('Company', usage.rawData['company'].toString()),
        );
      }
      if (usage.rawData['remarks'] != null &&
          usage.rawData['remarks'].toString().isNotEmpty) {
        children.add(const Divider(height: AppSizes.s16));
        children.add(
          _buildInfoRow('Remarks', usage.rawData['remarks'].toString()),
        );
      }
    }

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, dynamic usage) {
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
              headingRowColor: WidgetStateProperty.all(
                AppColors.surfaceContainer,
              ),
              horizontalMargin: AppSizes.s16,
              columnSpacing: AppSizes.s24,
              columns: const [
                DataColumn(label: Text('Task')),
                DataColumn(label: Text('Subtask')),
                DataColumn(label: Text('Skill Type')),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('UOM')),
                DataColumn(label: Text('Rate'), numeric: true),
                DataColumn(label: Text('Amount'), numeric: true),
                DataColumn(label: Text('Equipment Item')),
                DataColumn(label: Text('Contractor')),
              ],
              rows: (usage.manpowerUsage as List).map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.task)),
                    DataCell(Text(item.subtask)),
                    DataCell(Text(item.skillType)),
                    DataCell(Text(item.quantity.toString())),
                    DataCell(Text(item.uom)),
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
                    DataCell(Text(item.equipmentItem)),
                    DataCell(Text(item.contractor)),
                  ],
                );
              }).toList(),
            ),
          ),
          if ((usage.manpowerUsage as List).isEmpty)
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
