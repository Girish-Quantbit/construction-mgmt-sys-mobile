import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
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
      child: BlocListener<MaterialRequestBloc, MaterialRequestState>(
        listenWhen: (previous, current) => previous.pdfStatus != current.pdfStatus,
        listener: (context, state) {
          if (state.pdfStatus == MaterialRequestStatus.loading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(sizeContextOf(context, 20.0)),
                    child: const Column(
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
          } else if (state.pdfStatus == MaterialRequestStatus.success) {
            Navigator.of(context, rootNavigator: true).pop();
            if (state.pdfPath != null) {
              final xFile = XFile(state.pdfPath!);
              SharePlus.instance.share(
                ShareParams(
                  files: [xFile],
                  subject: 'Material Request ${state.selectedRequest?.name}',
                ),
              );
            }
          } else if (state.pdfStatus == MaterialRequestStatus.failure) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to download PDF'),
                backgroundColor: AppColors.error,
              ),
            );
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
          title: BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
            builder: (context, state) {
              final request = state.selectedRequest;
              if (request == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title ?? request.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    request.name,
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
            BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
              builder: (context, state) {
                final request = state.selectedRequest;
                if (request == null) return const SizedBox.shrink();
                final docstatus = request.rawData['docstatus'];
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
                              MaterialRequestFormPage(requestName: requestName),
                        ),
                      );
                      if (result == true && context.mounted) {
                        context.read<MaterialRequestBloc>().add(
                          LoadMaterialRequestDetails(requestName),
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
                final request = context
                    .read<MaterialRequestBloc>()
                    .state
                    .selectedRequest;
                if (request != null) {
                  context.read<MaterialRequestBloc>().add(
                    DownloadMaterialRequestPDF(request.name),
                  );
                }
              },
            ),
            SizedBox(width: sizeContextOf(context, 8)),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDetailsCard(context, request),
                  const SizedBox(height: AppSizes.s16),
                  _buildItemsCard(context, request),
                  const SizedBox(height: AppSizes.s24),
                  _buildItemsRequestedSection(context, request),
                  const SizedBox(height: AppSizes.s24),
                  _buildBottomActionButtons(context, request),
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

  Widget _buildDetailsCard(BuildContext context, dynamic request) {
    final transactionDateStr = request.transactionDate != null
        ? DateFormat('dd MMM yyyy').format(request.transactionDate!)
        : 'N/A';

    final scheduleDateStr = request.scheduleDate != null
        ? DateFormat('dd MMM yyyy').format(request.scheduleDate!)
        : 'N/A';

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
                    request.title ?? request.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 8)),
                _buildStatusBadge(context, request.status),
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
                        'Purpose',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        request.materialRequestType,
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
                        'Transaction Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        transactionDateStr,
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
                        'Required By',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        scheduleDateStr,
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
                        'Price List',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        request.buyingPriceList ?? '-',
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

  Widget _buildItemsCard(BuildContext context, dynamic request) {
    final totalQty = request.items.fold(0.0, (sum, item) => sum + item.qty);

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
                        'Set Warehouse',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        request.setWarehouse ?? '-',
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
            SizedBox(height: sizeContextOf(context, 12)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Percentage Ordered',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        request.perOrdered != null
                            ? '${request.perOrdered!.toStringAsFixed(1)}%'
                            : '0.0%',
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
                        'Percentage Received',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        request.perReceived != null
                            ? '${request.perReceived!.toStringAsFixed(1)}%'
                            : '0.0%',
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

  Widget _buildItemsRequestedSection(BuildContext context, dynamic request) {
    final List<dynamic> rawItems = request.rawData['items'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Items Requested',
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
                '${request.items.length} Items',
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
        ...List.generate(request.items.length, (index) {
          final item = request.items[index];
          final Map<String, dynamic> rawItem = rawItems.length > index
              ? Map<String, dynamic>.from(rawItems[index])
              : {};

          final String uom =
              rawItem['uom'] ?? rawItem['stock_uom'] ?? item.uom ?? 'Nos';
          final double qty = item.qty;
          final double orderedQty = (rawItem['ordered_qty'] ?? 0.0).toDouble();
          final String warehouse =
              rawItem['warehouse'] ?? request.setWarehouse ?? '-';
          final String project =
              rawItem['project'] ?? request.rawData['project'] ?? '-';
          final scheduleDate = item.scheduleDate ?? request.scheduleDate;

          return _ItemCard(
            item: item,
            rawItem: rawItem,
            uom: uom,
            qty: qty,
            orderedQty: orderedQty,
            warehouse: warehouse,
            project: project,
            scheduleDate: scheduleDate,
          );
        }),
      ],
    );
  }

  Widget _buildBottomActionButtons(BuildContext context, dynamic request) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 8.0)),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<MaterialRequestBloc>().add(
                  DownloadMaterialRequestPDF(request.name),
                );
              },
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
      case 'transferred':
      case 'received':
        bgColor = const Color(0xFFA7D5B0);
        textColor = Colors.white;
        icon = Icons.star;
        break;
      case 'partially ordered':
      case 'pending':
        bgColor = AppColors.warning.withValues(alpha: 0.2);
        textColor = AppColors.warning;
        break;
      case 'draft':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case 'cancelled':
      case 'stopped':
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
}


class _ItemCard extends StatefulWidget {
  final dynamic item;
  final Map<String, dynamic> rawItem;
  final String uom;
  final double qty;
  final double orderedQty;
  final String warehouse;
  final String project;
  final DateTime? scheduleDate;

  const _ItemCard({
    required this.item,
    required this.rawItem,
    required this.uom,
    required this.qty,
    required this.orderedQty,
    required this.warehouse,
    required this.project,
    this.scheduleDate,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheduleDateStr = widget.scheduleDate != null
        ? DateFormat('dd MMM yyyy').format(widget.scheduleDate!)
        : '-';

    final rate = widget.rawItem['rate'] != null
        ? (widget.rawItem['rate'] as num).toDouble()
        : 0.0;
    final amount = widget.rawItem['amount'] != null
        ? (widget.rawItem['amount'] as num).toDouble()
        : 0.0;

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
                          widget.uom,
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
                  'Quantity: ${widget.qty.toStringAsFixed(0)} ${widget.uom} • Required By: $scheduleDateStr',
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
                                      'Warehouse',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.warehouse,
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
                                      'Project',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.project,
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
                                      'Requested Qty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.qty.toStringAsFixed(0),
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
                                      'Ordered Qty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.orderedQty.toStringAsFixed(0),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Required By',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      scheduleDateStr,
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
                                        symbol: '₹',
                                        decimalDigits: 2,
                                      ).format(rate),
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
                                        symbol: '₹',
                                        decimalDigits: 2,
                                      ).format(amount),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                child: SizedBox.shrink(),
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
