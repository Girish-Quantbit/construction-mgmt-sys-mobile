import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_bloc.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_event.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_state.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/features/task_progress/presentation/pages/task_progress_detail_page.dart';
import 'package:cms/features/task_progress/presentation/pages/task_progress_form_page.dart';
import 'package:cms/features/task_progress/presentation/pages/daily_progress_report_page.dart';
import 'package:cms/features/task_progress/domain/entities/task_progress.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sort_chips.dart';
import '../../../../core/widgets/filter_button.dart';

class TaskProgressListPage extends StatefulWidget {
  final String? project;
  const TaskProgressListPage({super.key, this.project});

  @override
  State<TaskProgressListPage> createState() => _TaskProgressListPageState();
}

class _TaskProgressListPageState extends State<TaskProgressListPage> {
  final ScrollController _scrollController = ScrollController();
  String? _filterStatus;
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<TaskProgressBloc>().add(
      GetTaskProgressesRequested(project: widget.project),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String? selectedStatus = _filterStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FilterBottomSheet(
              title: 'Filter Task Progress',
              onReset: () {
                setState(() {
                  _filterStatus = null;
                });
              },
              onApply: () {
                setState(() {
                  _filterStatus = selectedStatus;
                });
              },
              children: [
                FilterDropdownSelector(
                  title: 'Status',
                  hintText: 'Select Status',
                  value: selectedStatus,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Status'),
                        children: ['Draft', 'Submitted', 'Cancelled']
                            .map(
                              (status) => SimpleDialogOption(
                                onPressed: () {
                                  setModalState(() {
                                    selectedStatus = status;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text(status),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.only(left: sizeContextOf(context, 12.0), top: sizeContextOf(context, 8.0), bottom: sizeContextOf(context, 8.0)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          widget.project ?? 'Tasks Progress',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          FilterIconButton(
            onTap: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          BlocBuilder<TaskProgressBloc, TaskProgressState>(
            builder: (context, state) {
              if (state is TaskProgressLoading) {
                return _buildLoadingSkeleton();
              } else if (state is TaskProgressError) {
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
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: AppSizes.s16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is TaskProgressLoaded) {
                var list = List<TaskProgress>.from(state.progressList);

                // Apply status filter
                if (_filterStatus != null) {
                  list = list
                      .where(
                        (item) =>
                            item.status.toLowerCase() ==
                            _filterStatus!.toLowerCase(),
                      )
                      .toList();
                }

                // Apply local sorting
                list.sort((a, b) {
                  switch (_sortBy) {
                    case 'date_desc':
                      if (a.date == null && b.date == null) return 0;
                      if (a.date == null) return 1;
                      if (b.date == null) return -1;
                      return b.date!.compareTo(a.date!);
                    case 'date_asc':
                      if (a.date == null && b.date == null) return 0;
                      if (a.date == null) return 1;
                      if (b.date == null) return -1;
                      return a.date!.compareTo(b.date!);
                    case 'project_asc':
                      return a.project.compareTo(b.project);
                    case 'project_desc':
                      return b.project.compareTo(a.project);
                    case 'status_asc':
                      return a.status.compareTo(b.status);
                    case 'status_desc':
                      return b.status.compareTo(a.status);
                    case 'progress_desc':
                      return b.progress.compareTo(a.progress);
                    case 'progress_asc':
                      return a.progress.compareTo(b.progress);
                    case 'id_desc':
                      return b.name.compareTo(a.name);
                    case 'id_asc':
                      return a.name.compareTo(b.name);
                    default:
                      return 0;
                  }
                });

                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: sizeContextOf(context, 16),
                      right: sizeContextOf(context, 16),
                      top: sizeContextOf(context, 16),
                      bottom: sizeContextOf(context, 100), // Safe padding for bottom buttons
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(state.progressList),
                        SizedBox(height: sizeContextOf(context, 16)),
                        _buildDailyReportButton(state.progressList),
                        SizedBox(height: sizeContextOf(context, 16)),
                        _buildSortChips(),
                        SizedBox(height: sizeContextOf(context, 16)),
                        if (list.isEmpty)
                           Padding(
                            padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 40.0)),
                            child: Center(
                              child: Text(
                                'No task progress records found',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: sizeContextOf(context, 16)),
                            itemBuilder: (context, index) {
                              final item = list[index];
                              return _TaskProgressCard(
                                item: item,
                                onRefresh: _refresh,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }
              return const Center(child: Text('Initialize...'));
            },
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<TaskProgress> list) {
    int totalLogs = list.length;
    int submittedLogs = list
        .where((item) => item.status.toLowerCase() == 'submitted')
        .length;

    return Container(
      padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 4.0)),
              child: Column(
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Total Logs',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 8)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$totalLogs',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 4.0)),
              child: Column(
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Submitted Logs',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 8)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$submittedLogs',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReportButton(List<TaskProgress> list) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          DateTime reportDate = DateTime.now();
          if (list.isNotEmpty) {
            reportDate = list.first.date ?? DateTime.now();
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DailyProgressReportPage(
                initialProject:
                    widget.project ??
                    (list.isNotEmpty ? list.first.project : ''),
                initialSiteDate: reportDate,
              ),
            ),
          );
        },
        icon: const Icon(Icons.summarize_outlined, size: 20),
        label: const Text(
          'Daily Progress Report',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 14)),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    return SortChips(
      sortBy: _sortBy,
      options: const [
        SortOption(label: 'Date', field: 'date'),
        SortOption(label: 'Status', field: 'status'),
        SortOption(label: 'ID', field: 'id'),
      ],
      onSortChanged: (newSort) {
        setState(() {
          _sortBy = newSort;
        });
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: EdgeInsets.all(sizeContextOf(context, 16)),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: sizeContextOf(context, 16)),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Positioned(
      bottom: sizeContextOf(context, 24),
      left: sizeContextOf(context, 16),
      right: sizeContextOf(context, 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskProgressFormPage(),
            ),
          );

          if (result == true && context.mounted) {
            _refresh();
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 16)),
          decoration: BoxDecoration(
            color: AppColors.primaryButton,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '+ Add Task Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskProgressCard extends StatelessWidget {
  final TaskProgress item;
  final VoidCallback onRefresh;

  const _TaskProgressCard({required this.item, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => sl<TaskProgressBloc>(),
                  child: TaskProgressDetailPage(name: item.name),
                ),
              ),
            ).then((_) => onRefresh());
          },
          child: Padding(
            padding: EdgeInsets.all(sizeContextOf(context, 12.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    StatusBadge(status: item.status),
                  ],
                ),
                SizedBox(height: sizeContextOf(context, 8)),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: sizeContextOf(context, 4)),
                    Text(
                      item.date != null
                          ? DateFormat('MMM dd, yyyy').format(item.date!)
                          : '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

