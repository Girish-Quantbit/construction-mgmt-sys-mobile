import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/features/task_progress/domain/entities/task_progress.dart';
import 'package:cms/features/task_progress/domain/entities/task_progress_detail.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_bloc.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_event.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_state.dart';
import 'package:cms/features/task_progress/presentation/pages/task_progress_form_page.dart';

class TaskProgressDetailPage extends StatefulWidget {
  final String name;
  const TaskProgressDetailPage({super.key, required this.name});

  @override
  State<TaskProgressDetailPage> createState() => _TaskProgressDetailPageState();
}

class _TaskProgressDetailPageState extends State<TaskProgressDetailPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<TaskProgressBloc>().add(
      GetTaskProgressDetailsRequested(widget.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskProgressBloc, TaskProgressState>(
      listenWhen: (prev, curr) {
        if (prev is TaskProgressDetailLoaded && curr is TaskProgressDetailLoaded) {
          return prev.pdfStatus != curr.pdfStatus;
        }
        return false;
      },
      listener: (context, state) async {
        if (state is TaskProgressDetailLoaded) {
          if (state.pdfStatus == TaskProgressPdfStatus.downloading) {
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
          } else if (state.pdfStatus == TaskProgressPdfStatus.success &&
              state.pdfBytes != null) {
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
            final tempDir = await getTemporaryDirectory();
            final sanitized =
                (state.pdfEntryName ?? 'progress').replaceAll(RegExp(r'[/\\]'), '_');
            final file = File('${tempDir.path}/$sanitized.pdf');
            await file.writeAsBytes(state.pdfBytes!);
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                subject: 'Task Progress ${state.pdfEntryName ?? ''}',
              ),
            );
          } else if (state.pdfStatus == TaskProgressPdfStatus.failure) {
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to download PDF: ${state.pdfError}'),
              backgroundColor: AppColors.error,
            ));
          }
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
        title: BlocBuilder<TaskProgressBloc, TaskProgressState>(
          builder: (context, state) {
            if (state is TaskProgressDetailLoaded) {
              final p = state.taskProgress;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    p.project,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            }
            return const Text(
              'Task Progress Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            );
          },
        ),
        actions: [
          BlocBuilder<TaskProgressBloc, TaskProgressState>(
            builder: (context, state) {
              if (state is TaskProgressDetailLoaded &&
                  state.taskProgress.status == 'Draft') {
                return IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskProgressFormPage(
                          progressName: state.taskProgress.name,
                        ),
                      ),
                    ).then((_) => _load());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.black87),
            onPressed: () {
              final state = context.read<TaskProgressBloc>().state;
              if (state is TaskProgressDetailLoaded) {
                _downloadPDF(context, state.taskProgress);
              }
            },
          ),
          SizedBox(width: sizeContextOf(context, 8)),
        ],
      ),
      body: BlocBuilder<TaskProgressBloc, TaskProgressState>(
        builder: (context, state) {
          if (state is TaskProgressLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskProgressError) {
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
                  Text(state.message),
                  const SizedBox(height: AppSizes.s16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            );
          } else if (state is TaskProgressDetailLoaded) {
            final p = state.taskProgress;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDetailsCard(context, p),
                  const SizedBox(height: AppSizes.s16),
                  _buildSummaryCard(context, p),
                  const SizedBox(height: AppSizes.s24),
                  _buildItemsSection(context, p),
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.s24),
                    _buildDescriptionCard(context, p),
                  ],
                  const SizedBox(height: AppSizes.s24),
                  _buildBottomActionButtons(context, p),
                  const SizedBox(height: AppSizes.s16),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, TaskProgress p) {
    final dateStr = p.date != null
        ? DateFormat('dd MMM yyyy').format(p.date!)
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
                const Text(
                  'General Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _buildStatusBadge(context, p.status),
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
                        'Project',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        p.project,
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
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        dateStr,
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
                        'Shift',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        p.rawData['shift']?.toString() ?? '-',
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
                        'Site Engineer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        (p.rawData['site_engineer_name'] != null &&
                                p.rawData['site_engineer_name']
                                    .toString()
                                    .isNotEmpty)
                            ? p.rawData['site_engineer_name'].toString()
                            : (p.rawData['site_engineer']?.toString() ?? '-'),
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
                        'Site',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        p.rawData['site']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.taskSubject != null && p.taskSubject!.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Task Subject',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 6)),
                        Text(
                          p.taskSubject!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, TaskProgress p) {
    final totalTasks = p.taskProgressDetails.length;
    final double avgCompleted = totalTasks > 0
        ? p.taskProgressDetails.fold(
                0.0,
                (sum, item) => sum + item.percentCompleted,
              ) /
              totalTasks
        : 0.0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sizeContextOf(context, 20.0),
          vertical: sizeContextOf(context, 16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Summary',
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
                        'Total Tasks Logged',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        '$totalTasks',
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
                        'Average Completion',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        '${avgCompleted.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
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

  Widget _buildItemsSection(BuildContext context, TaskProgress p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tasks Progress Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: sizeContextOf(context, 10),
                vertical: sizeContextOf(context, 4),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${p.taskProgressDetails.length} Tasks',
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
        ...List.generate(p.taskProgressDetails.length, (index) {
          final detail = p.taskProgressDetails[index];
          return _ItemCard(detail: detail);
        }),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, TaskProgress p) {
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
              'Description / Remarks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            Text(
              p.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueSummaryCard(BuildContext context, TaskProgress p) {
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
              'Overall Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${p.progress.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons(BuildContext context, TaskProgress p) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 8.0)),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _downloadPDF(context, p),
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
                padding: EdgeInsets.symmetric(
                  vertical: sizeContextOf(context, 16),
                ),
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
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, 10),
        vertical: sizeContextOf(context, 4),
      ),
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

  void _downloadPDF(BuildContext context, TaskProgress p) {
    context.read<TaskProgressBloc>().add(DownloadTaskProgressPdfEvent(p.name));
  }
}

class _ItemCard extends StatefulWidget {
  final TaskProgressDetail detail;
  const _ItemCard({required this.detail});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _isExpanded = false;
  bool _showImages = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (!_isExpanded) {
            _showImages = false;
          }
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
          padding: EdgeInsets.symmetric(
            horizontal: sizeContextOf(context, 16.0),
            vertical: sizeContextOf(context, 12.0),
          ),
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
                          widget.detail.task ?? 'Unknown Task',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          widget.detail.taskSubject ?? 'No Subject',
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
                          color: const Color(0xFFE1F2E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.detail.percentCompleted.toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
                  'Planned: ${widget.detail.plannedToday.toStringAsFixed(0)} • Achieved: ${widget.detail.achievedToday.toStringAsFixed(0)}',
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
                          if (widget.detail.parentTask != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Parent Task',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                        height: sizeContextOf(context, 2),
                                      ),
                                      Text(
                                        widget.detail.parentTask!,
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
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Qty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.detail.totalQty.toStringAsFixed(0),
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
                                      'Planned Today',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.detail.plannedToday
                                          .toStringAsFixed(0),
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
                                      'Achieved Today',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.detail.achievedToday
                                          .toStringAsFixed(0),
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
                                      'Total Achieved',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 2)),
                                    Text(
                                      widget.detail.totalAchieved
                                          .toStringAsFixed(0),
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
                          SizedBox(height: sizeContextOf(context, 14)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.detail.percentCompleted.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizeContextOf(context, 6)),
                          LinearProgressIndicator(
                            value: widget.detail.percentCompleted / 100,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: Colors.grey[100],
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                          _buildImagesButton(context),
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

  Widget _buildImagesButton(BuildContext context) {
    // Gather all image URLs
    final List<String> imageUrls = [];
    if (widget.detail.image1 != null && widget.detail.image1!.isNotEmpty) {
      imageUrls.add(widget.detail.image1!);
    }
    if (widget.detail.image2 != null && widget.detail.image2!.isNotEmpty) {
      imageUrls.add(widget.detail.image2!);
    }
    if (widget.detail.image3 != null && widget.detail.image3!.isNotEmpty) {
      imageUrls.add(widget.detail.image3!);
    }
    if (widget.detail.image4 != null && widget.detail.image4!.isNotEmpty) {
      imageUrls.add(widget.detail.image4!);
    }
    if (widget.detail.image5 != null && widget.detail.image5!.isNotEmpty) {
      imageUrls.add(widget.detail.image5!);
    }
    if (widget.detail.image6 != null && widget.detail.image6!.isNotEmpty) {
      imageUrls.add(widget.detail.image6!);
    }
    if (widget.detail.image7 != null && widget.detail.image7!.isNotEmpty) {
      imageUrls.add(widget.detail.image7!);
    }
    if (widget.detail.image8 != null && widget.detail.image8!.isNotEmpty) {
      imageUrls.add(widget.detail.image8!);
    }
    if (widget.detail.image9 != null && widget.detail.image9!.isNotEmpty) {
      imageUrls.add(widget.detail.image9!);
    }
    if (widget.detail.image10 != null && widget.detail.image10!.isNotEmpty) {
      imageUrls.add(widget.detail.image10!);
    }

    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (!_showImages) {
      return Padding(
        padding: EdgeInsets.only(top: sizeContextOf(context, 12.0)),
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showImages = true;
            });
          },
          icon: const Icon(
            Icons.image_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          label: Text(
            'Show Images (${imageUrls.length})',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            padding: EdgeInsets.symmetric(
              horizontal: sizeContextOf(context, 12),
              vertical: sizeContextOf(context, 8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    final state = context.read<TaskProgressBloc>().state;
    final baseUrl = state is TaskProgressDetailLoaded ? (state.baseUrl ?? '') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: sizeContextOf(context, 14)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Images',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showImages = false;
                });
              },
              child: const Text(
                'Hide Images',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: sizeContextOf(context, 6)),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            itemBuilder: (context, idx) {
              final url = imageUrls[idx];
              final fullUrl = url.startsWith('http') ? url : '$baseUrl$url';
              return Padding(
                padding: EdgeInsets.only(right: sizeContextOf(context, 8.0)),
                child: GestureDetector(
                  onTap: () {
                    // Open large full-screen dialog
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        return Dialog.fullscreen(
                          backgroundColor: Colors.black.withValues(alpha: 0.95),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: PageController(initialPage: idx),
                                itemCount: imageUrls.length,
                                itemBuilder: (pCtx, pIdx) {
                                  final pUrl = imageUrls[pIdx];
                                  final pFullUrl = pUrl.startsWith('http')
                                      ? pUrl
                                      : '$baseUrl$pUrl';
                                  return Center(
                                    child: Image.network(
                                      pFullUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.broken_image,
                                        color: Colors.white30,
                                        size: 80,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: MediaQuery.of(ctx).padding.top + 16,
                                right: sizeContextOf(context, 16),
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fullUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
