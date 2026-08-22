import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/entities/stock_entry_item.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/stock_entry_bloc.dart';
import '../bloc/stock_entry_event.dart';
import '../bloc/stock_entry_state.dart';
import 'stock_entry_form_page.dart';

class MaterialTransferDetailPage extends StatelessWidget {
  final String entryName;

  const MaterialTransferDetailPage({super.key, required this.entryName});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MaterialTransferDetailPage for $entryName');
    return BlocProvider(
      create: (context) =>
          sl<StockEntryBloc>()..add(LoadStockEntryDetails(entryName)),
      child: BlocListener<StockEntryBloc, StockEntryState>(
        listenWhen: (prev, curr) => prev.pdfStatus != curr.pdfStatus,
        listener: (context, state) async {
          if (state.pdfStatus == StockEntryPdfStatus.downloading) {
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
          } else if (state.pdfStatus == StockEntryPdfStatus.success &&
              state.pdfBytes != null) {
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
            final tempDir = await getTemporaryDirectory();
            final sanitized =
                (state.pdfEntryName ?? 'entry').replaceAll(RegExp(r'[/\\]'), '_');
            final file = File('${tempDir.path}/$sanitized.pdf');
            await file.writeAsBytes(state.pdfBytes!);
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                subject: 'Stock Entry ${state.pdfEntryName ?? ''}',
              ),
            );
          } else if (state.pdfStatus == StockEntryPdfStatus.failure) {
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to download PDF: ${state.errorMessage}'),
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
          title: BlocBuilder<StockEntryBloc, StockEntryState>(
            builder: (context, state) {
              final entry = state.selectedEntry;
              if (entry == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    entry.purpose,
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
            BlocBuilder<StockEntryBloc, StockEntryState>(
              builder: (context, state) {
                final entry = state.selectedEntry;
                if (entry == null) return const SizedBox.shrink();
                final docstatus = entry.rawData['docstatus'];
                final isSubmitted =
                    docstatus == 1 || docstatus == '1' || docstatus == 1.0;

                if (!isSubmitted) {
                  return IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black87),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockEntryFormPage(
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
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.print, color: Colors.black87),
              onPressed: () {
                final entry = context
                    .read<StockEntryBloc>()
                    .state
                    .selectedEntry;
                if (entry != null) {
                  _downloadPDF(context, entry);
                }
              },
            ),
            SizedBox(width: sizeContextOf(context, 8)),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDetailsCard(context, entry),
                  const SizedBox(height: AppSizes.s16),
                  _buildAccountingDimensionsCard(context, entry),
                  const SizedBox(height: AppSizes.s16),
                  _buildItemsSummaryCard(context, entry),
                  const SizedBox(height: AppSizes.s24),
                  _buildItemsSection(context, entry),
                  const SizedBox(height: AppSizes.s16),
                  _buildOtherInfoCard(context, entry),
                  const SizedBox(height: AppSizes.s24),
                  _buildValueSummaryCard(context, entry),
                  const SizedBox(height: AppSizes.s24),
                  _buildBottomActionButtons(context, entry),
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

  Widget _buildDetailsCard(BuildContext context, StockEntry entry) {
    final Map<String, dynamic> data = entry.rawData;
    final postingDateStr = entry.postingDate != null
        ? DateFormat('dd MMM yyyy').format(entry.postingDate!)
        : 'N/A';
    final postingTimeStr = data['posting_time'] ?? '12:00 PM';

    String formattedTime = postingTimeStr;
    try {
      final parts = postingTimeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        formattedTime =
            '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
      }
    } catch (_) {}

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 8)),
                _buildStatusBadge(context, entry.status),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 16)),
            const Divider(color: Color(0xFFEEEEEE), height: 1),
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stock Entry Type',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        entry.stockEntryType,
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
                        'Posting Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        postingDateStr,
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
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Posting Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        formattedTime,
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
                        'Purpose',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        entry.purpose,
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
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Source Warehouse',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        entry.fromWarehouse ?? '-',
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
                        'Target Warehouse',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        entry.toWarehouse ?? '-',
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

  Widget _buildAccountingDimensionsCard(BuildContext context, StockEntry entry) {
    final Map<String, dynamic> data = entry.rawData;
    if (data['project'] == null && data['cost_center'] == null && data['custom_task'] == null) {
      return const SizedBox.shrink();
    }
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
              'Accounting Dimensions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            Row(
              children: [
                if (data['project'] != null)
                  Expanded(
                    child: Column(
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
                        SizedBox(height: sizeContextOf(context, 4)),
                        Text(
                          data['project'] ?? '-',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (data['custom_task'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Task',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 4)),
                        Text(
                          data['custom_task'] ?? '-',
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
            if (data['cost_center'] != null) ...[
              SizedBox(height: sizeContextOf(context, 12)),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost Centre',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 4)),
                        Text(
                          data['cost_center'] ?? '-',
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
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSummaryCard(BuildContext context, StockEntry entry) {
    final totalQty = entry.items.fold(0.0, (sum, item) => sum + item.qty);
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
              'Items Summary',
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
                        'Total Items',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        '${entry.items.length}',
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
                        'Total Quantity',
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

  Widget _buildItemsSection(BuildContext context, StockEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Items Transferred',
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
                '${entry.items.length} Items',
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
        ...List.generate(entry.items.length, (index) {
          final item = entry.items[index];
          final List<dynamic> rawItems = entry.rawData['items'] ?? [];
          final Map<String, dynamic> rawItem = rawItems.length > index
              ? Map<String, dynamic>.from(rawItems[index])
              : {};
          return _ItemCard(item: item, entry: entry, rawItem: rawItem);
        }),
      ],
    );
  }

  Widget _buildValueSummaryCard(BuildContext context, StockEntry entry) {
    final difference = entry.totalIncomingValue - entry.totalOutgoingValue;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 24.0)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Outgoing Value',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: '₹ ',
                    decimalDigits: 2,
                  ).format(entry.totalOutgoingValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Incoming Value',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: '₹ ',
                    decimalDigits: 2,
                  ).format(entry.totalIncomingValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.black26, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Value Difference',
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
                  ).format(difference),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: difference != 0 ? AppColors.error : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherInfoCard(BuildContext context, StockEntry entry) {
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

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Other Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            ...fieldsToShow.map((e) {
              String value = e.value.toString();
              if (e.key == 'per_transferred') value = '$value%';
              if (e.key == 'total_amount') {
                value = NumberFormat.currency(symbol: '₹ ').format(e.value);
              }
              if (e.key == 'is_opening') {
                value = (e.value == 1 || e.value == 'Yes') ? 'Yes' : 'No';
              }
              return Padding(
                padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 4.0)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      otherFields[e.key]!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons(BuildContext context, StockEntry entry) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 8.0)),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _downloadPDF(context, entry),
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

  void _downloadPDF(BuildContext context, StockEntry entry) {
    context.read<StockEntryBloc>().add(DownloadStockEntryPdfEvent(entry.name));
  }
}

class _ItemCard extends StatefulWidget {
  final StockEntryItem item;
  final StockEntry entry;
  final Map<String, dynamic> rawItem;

  const _ItemCard({
    required this.item,
    required this.entry,
    required this.rawItem,
  });

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
                          widget.item.itemCode,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          widget.item.itemName,
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
                          widget.item.uom,
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
                  'Quantity: ${widget.item.qty.toStringAsFixed(0)} ${widget.item.uom}',
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
                                      'Source Warehouse',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.item.sWarehouse ??
                                          widget.entry.fromWarehouse ??
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
                                      'Target Warehouse',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.item.tWarehouse ??
                                          widget.entry.toWarehouse ??
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
                                      'Actual Qty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      '${(widget.rawItem['actual_qty'] ?? 0.0).toStringAsFixed(0)} ${widget.item.uom}',
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
                                      'Transferred Qty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      '${(widget.rawItem['transferred_qty'] ?? widget.item.qty).toStringAsFixed(0)} ${widget.item.uom}',
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
                          if (widget.rawItem['custom_item_type'] != null ||
                              widget.rawItem['custom_diameter_of_steel'] !=
                                  null) ...[
                            SizedBox(height: sizeContextOf(context, 10)),
                            Row(
                              children: [
                                if (widget.rawItem['custom_item_type'] != null)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Item Type',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: sizeContextOf(context, 2)),
                                        Text(
                                          widget.rawItem['custom_item_type']
                                              .toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget
                                        .rawItem['custom_diameter_of_steel'] !=
                                    null)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Steel Diameter',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: sizeContextOf(context, 2)),
                                        Text(
                                          widget
                                              .rawItem['custom_diameter_of_steel']
                                              .toString(),
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
                          ],
                          SizedBox(height: sizeContextOf(context, 10)),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Basic Rate',
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
                                      ).format(widget.item.basicRate),
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
