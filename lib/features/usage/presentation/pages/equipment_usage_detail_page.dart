import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/equipment_usage_bloc.dart';
import '../bloc/equipment_usage_event.dart';
import '../bloc/equipment_usage_state.dart';
import '../../domain/entities/equipment_usage.dart';
import '../../domain/entities/equipment_usage_item.dart';
import 'equipment_usage_form_page.dart';

class EquipmentUsageDetailPage extends StatelessWidget {
  final String usageName;

  const EquipmentUsageDetailPage({super.key, required this.usageName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<EquipmentUsageBloc>()..add(LoadEquipmentUsageDetails(usageName)),
      child: BlocListener<EquipmentUsageBloc, EquipmentUsageState>(
        listenWhen: (prev, curr) => prev.pdfStatus != curr.pdfStatus,
        listener: (context, state) async {
          if (state.pdfStatus == EquipmentUsagePdfStatus.downloading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Downloading PDF...'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else if (state.pdfStatus == EquipmentUsagePdfStatus.success &&
              state.pdfBytes != null) {
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
            final tempDir = await getTemporaryDirectory();
            final sanitized =
                (state.pdfEntryName ?? 'usage').replaceAll(RegExp(r'[/\\]'), '_');
            final file = File('${tempDir.path}/$sanitized.pdf');
            await file.writeAsBytes(state.pdfBytes!);
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                subject: 'Equipment Usage ${state.pdfEntryName ?? ''}',
              ),
            );
          } else if (state.pdfStatus == EquipmentUsagePdfStatus.failure) {
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to download PDF: ${state.pdfError}'),
              backgroundColor: AppColors.error,
            ));
          }
        },
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
          title: BlocBuilder<EquipmentUsageBloc, EquipmentUsageState>(
            builder: (context, state) {
              final usage = state.selectedUsage;
              if (usage == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usage.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    usage.project,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            BlocBuilder<EquipmentUsageBloc, EquipmentUsageState>(
              builder: (context, state) {
                final usage = state.selectedUsage;
                if (usage == null) return const SizedBox.shrink();
                final docstatus = usage.rawData['docstatus'];
                final isSubmitted =
                    docstatus == 1 || docstatus == '1' || docstatus == 1.0;

                if (!isSubmitted) {
                  return IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black87),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EquipmentUsageFormPage(usageName: usageName),
                        ),
                      );
                      if (result == true && context.mounted) {
                        context.read<EquipmentUsageBloc>().add(
                          LoadEquipmentUsageDetails(usageName),
                        );
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.print, color: Colors.black87),
              onPressed: () {
                final usage = context
                    .read<EquipmentUsageBloc>()
                    .state
                    .selectedUsage;
                if (usage != null) {
                  _downloadPDF(context, usage);
                }
              },
            ),
            SizedBox(width: sizeContextOf(context, 8)),
          ],
        ),
        body: BlocBuilder<EquipmentUsageBloc, EquipmentUsageState>(
          builder: (context, state) {
            if (state.status == EquipmentUsageStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == EquipmentUsageStatus.failure) {
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
                      onPressed: () => context.read<EquipmentUsageBloc>().add(
                        LoadEquipmentUsageDetails(usageName),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGeneralInfoCard(context, usage),
                  const SizedBox(height: AppSizes.s16),
                  _buildItemsSummaryCard(context, usage),
                  const SizedBox(height: AppSizes.s24),
                  _buildItemsSection(context, usage),
                  const SizedBox(height: AppSizes.s16),
                  _buildValueSummaryCard(context, usage),
                  const SizedBox(height: AppSizes.s24),
                  _buildBottomActionButtons(context, usage),
                  const SizedBox(height: AppSizes.s16),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(BuildContext context, EquipmentUsage usage) {
    final List<Widget> children = [];

    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              usage.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: sizeContextOf(context, 8)),
          _buildStatusBadge(context, usage.status),
        ],
      ),
    );
    children.add(SizedBox(height: sizeContextOf(context, 16)));
    children.add(const Divider(color: Color(0xFFEEEEEE), height: 1));
    children.add(SizedBox(height: sizeContextOf(context, 20)));

    final List<Widget> detailFields = [];
    final siteDateStr = usage.siteDate != null
        ? DateFormat('dd MMM yyyy').format(usage.siteDate!)
        : '-';
    detailFields.addAll([
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Site Date',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sizeContextOf(context, 6)),
          Text(
            siteDateStr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sizeContextOf(context, 6)),
          Text(
            usage.project,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ]);
    if (usage.rawData['company'] != null) {
      detailFields.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sizeContextOf(context, 6)),
            Text(
              usage.rawData['company'].toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }
    if (usage.rawData['shift'] != null) {
      detailFields.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shift',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sizeContextOf(context, 6)),
            Text(
              usage.rawData['shift'].toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    // Grid of fields in 2 columns
    final List<Widget> gridRows = [];
    for (int i = 0; i < detailFields.length; i += 2) {
      gridRows.add(
        Row(
          children: [
            Expanded(child: detailFields[i]),
            if (i + 1 < detailFields.length)
              Expanded(child: detailFields[i + 1])
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      if (i + 2 < detailFields.length) {
        gridRows.add(SizedBox(height: sizeContextOf(context, 20)));
      }
    }

    children.addAll(gridRows);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildItemsSummaryCard(BuildContext context, EquipmentUsage usage) {
    final totalQty = usage.equipmentUsageDetails.fold(
      0.0,
      (sum, item) => sum + item.quantity,
    );
    final totalHours = usage.equipmentUsageDetails.fold(
      0.0,
      (sum, item) => sum + (item.workingHrs ?? 0.0),
    );
    final totalDiesel = usage.equipmentUsageDetails.fold(
      0.0,
      (sum, item) => sum + (item.dieselFilledInLtr ?? 0.0),
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 20.0), vertical: sizeContextOf(context, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Working Hours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        '${totalHours.toStringAsFixed(1)} Hrs',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Diesel Filled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        '${totalDiesel.toStringAsFixed(1)} Ltr',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Output Qty',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        '${totalQty.toStringAsFixed(0)} Units',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, EquipmentUsage usage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Equipment Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 10), vertical: sizeContextOf(context, 4)),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${usage.equipmentUsageDetails.length} Logs',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: sizeContextOf(context, 12)),
        ...List.generate(usage.equipmentUsageDetails.length, (index) {
          final item = usage.equipmentUsageDetails[index];
          return _ItemCard(item: item);
        }),
      ],
    );
  }

  Widget _buildValueSummaryCard(BuildContext context, EquipmentUsage usage) {
    final grandTotal = usage.equipmentUsageDetails.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 24.0)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grand Total Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              NumberFormat.currency(
                symbol: '₹ ',
                decimalDigits: 2,
              ).format(grandTotal),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons(BuildContext context, EquipmentUsage usage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 8.0)),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _downloadPDF(context, usage),
              icon: const Icon(
                Icons.file_download_outlined,
                color: Colors.black87,
                size: 18,
              ),
              label: const Text(
                'Download PDF',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'submitted':
        bgColor = const Color(0xFFA7D5B0);
        textColor = Colors.white;
        icon = Icons.check_circle_outline;
        break;
      case 'draft':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case 'cancelled':
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      default:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 10), vertical: sizeContextOf(context, 4)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            SizedBox(width: sizeContextOf(context, 4)),
          ],
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadPDF(BuildContext context, EquipmentUsage usage) {
    context.read<EquipmentUsageBloc>().add(DownloadEquipmentUsagePdfEvent(usage.name));
  }
}

class _ItemCard extends StatefulWidget {
  final EquipmentUsageItem item;

  const _ItemCard({required this.item});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: sizeContextOf(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isExpanded ? const Color(0xFFE1F2E9) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 16.0), vertical: sizeContextOf(context, 12.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.task,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          widget.item.subtask,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sizeContextOf(context, 8),
                          vertical: sizeContextOf(context, 2),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3EE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.item.equipmentItem.isNotEmpty
                              ? widget.item.equipmentItem
                              : 'Equipment',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B5E52),
                          ),
                        ),
                      ),
                      SizedBox(width: sizeContextOf(context, 8)),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (!_isExpanded) ...[
                SizedBox(height: sizeContextOf(context, 6)),
                Text(
                  'Working Hours: ${widget.item.workingHrs?.toStringAsFixed(1) ?? '0'} Hrs • Qty: ${widget.item.quantity.toStringAsFixed(0)} ${widget.item.uom}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: sizeContextOf(context, 10)),
                          const Divider(color: Color(0xFFEEEEEE), height: 1),
                          SizedBox(height: sizeContextOf(context, 10)),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Opening Reading',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.item.openingReading?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Closing Reading',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.item.closingReading?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizeContextOf(context, 10)),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Working Hours',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.item.workingHrs?.toStringAsFixed(
                                            1,
                                          ) ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Diesel filled (Ltr)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.item.dieselFilledInLtr
                                              ?.toStringAsFixed(1) ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizeContextOf(context, 10)),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Contractor',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.item.contractor.isNotEmpty
                                          ? widget.item.contractor
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Qty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      '${widget.item.quantity.toStringAsFixed(0)} ${widget.item.uom}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizeContextOf(context, 10)),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rate',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      NumberFormat.currency(
                                        symbol: '₹ ',
                                        decimalDigits: 2,
                                      ).format(widget.item.rate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Amount',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      NumberFormat.currency(
                                        symbol: '₹ ',
                                        decimalDigits: 2,
                                      ).format(widget.item.amount),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5A8B6C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizeContextOf(context, 10)),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      widget.item.billed == true
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: widget.item.billed == true
                                          ? AppColors.success
                                          : Colors.grey,
                                      size: 16,
                                    ),
                                    SizedBox(width: sizeContextOf(context, 4)),
                                    const Text(
                                      'Billed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      widget.item.paid == true
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: widget.item.paid == true
                                          ? AppColors.success
                                          : Colors.grey,
                                      size: 16,
                                    ),
                                    SizedBox(width: sizeContextOf(context, 4)),
                                    const Text(
                                      'Paid',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
