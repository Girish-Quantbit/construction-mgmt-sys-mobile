import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:cms/features/tasks/domain/entities/task.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';

class TaskListPage extends StatefulWidget {
  final String? project;

  const TaskListPage({super.key, this.project});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String? _filterStatus;
  String? _filterPriority;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(GetTasksRequested(project: widget.project));
  }

  void _showFilterBottomSheet(BuildContext context) {
    String? selectedStatus = _filterStatus;
    String? selectedPriority = _filterPriority;

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
              title: 'Filter Tasks',
              onReset: () {
                setState(() {
                  _filterStatus = null;
                  _filterPriority = null;
                });
              },
              onApply: () {
                setState(() {
                  _filterStatus = selectedStatus;
                  _filterPriority = selectedPriority;
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
                        children: ['Open', 'Active', 'Completed', 'Pending']
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
                FilterDropdownSelector(
                  title: 'Priority',
                  hintText: 'Select Priority',
                  value: selectedPriority,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Priority'),
                        children: ['High', 'Medium', 'Low']
                            .map(
                              (priority) => SimpleDialogOption(
                                onPressed: () {
                                  setModalState(() {
                                    selectedPriority = priority;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text(priority),
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
      appBar: CustomAppBar(
        title: widget.project ?? 'Project Tasks',
        showSearch: false,
        onMenuPressed: () => Navigator.of(context).pop(),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sizeContextOf(context, 12.0), top: sizeContextOf(context, 8.0), bottom: sizeContextOf(context, 8.0)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.filter_alt,
                  color: Colors.black87,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => _showFilterBottomSheet(context),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is TaskLoaded) {
            var filteredTasks = List<ProjectTask>.from(state.tasks);
            if (_filterStatus != null) {
              filteredTasks = filteredTasks
                  .where(
                    (task) =>
                        task.status.toLowerCase() ==
                        _filterStatus!.toLowerCase(),
                  )
                  .toList();
            }
            if (_filterPriority != null) {
              filteredTasks = filteredTasks
                  .where(
                    (task) =>
                        (task.priority ?? '').toLowerCase() ==
                        _filterPriority!.toLowerCase(),
                  )
                  .toList();
            }

            if (filteredTasks.isEmpty) {
              return const Center(child: Text('No tasks found.'));
            }

            // Build tree
            final Map<String, List<ProjectTask>> childrenMap = {};
            final List<ProjectTask> rootTasks = [];

            int totalTasks = 0;
            int totalSubtasks = 0;
            int totalStages = 0;
            double stageProgressSum = 0;
            double taskProgressSum = 0;
            double subtaskProgressSum = 0;

            for (var task in filteredTasks) {
              if (task.parentTask == null || task.parentTask!.isEmpty) {
                rootTasks.add(task);
                totalStages++;
                stageProgressSum += task.progress;
              } else {
                childrenMap.putIfAbsent(task.parentTask!, () => []).add(task);
                // Simple heuristic for counting task vs subtask
                if (task.isGroup) {
                  totalTasks++;
                  taskProgressSum += task.progress;
                } else {
                  totalSubtasks++;
                  subtaskProgressSum += task.progress;
                }
              }
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(sizeContextOf(context, 16)),
                    itemCount: rootTasks.length,
                    itemBuilder: (context, index) {
                      return _TaskNode(
                        task: rootTasks[index],
                        childrenMap: childrenMap,
                        depth: 0,
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sizeContextOf(context, 16),
                    vertical: sizeContextOf(context, 12),
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CompactSummary(
                        label: 'Stages',
                        percentage: totalStages > 0
                            ? stageProgressSum / totalStages
                            : 0,
                      ),
                      _CompactSummary(
                        label: 'Tasks',
                        percentage: totalTasks > 0
                            ? taskProgressSum / totalTasks
                            : 0,
                      ),
                      _CompactSummary(
                        label: 'Subtasks',
                        percentage: totalSubtasks > 0
                            ? subtaskProgressSum / totalSubtasks
                            : 0,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Initialize tasks...'));
        },
      ),
    );
  }
}

class _CompactSummary extends StatelessWidget {
  final String label;
  final double percentage;

  const _CompactSummary({required this.label, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sizeContextOf(context, 4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 8), vertical: sizeContextOf(context, 2)),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success, width: 1),
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskNode extends StatelessWidget {
  final ProjectTask task;
  final Map<String, List<ProjectTask>> childrenMap;
  final int depth;
  final bool isExpanded;

  const _TaskNode({
    required this.task,
    required this.childrenMap,
    this.depth = 0,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = childrenMap[task.name] ?? [];

    Color bgColor;
    if (depth == 0) {
      bgColor = const Color(0xFF4A90E2); // Blue for stage
    } else if (depth == 1) {
      bgColor = const Color(0xFFE3F2FD); // Light blue for task
    } else {
      bgColor = Colors.white; // White for subtask
    }

    Color textColor = depth == 0 ? Colors.white : AppColors.onSurface;

    return Container(
      margin: EdgeInsets.only(bottom: sizeContextOf(context, 12)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: depth >= 2 ? Border.all(color: AppColors.outlineVariant) : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: ListTileThemeData(
            textColor: textColor,
            iconColor: textColor,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.subject,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: sizeContextOf(context, 8)),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: sizeContextOf(context, 6),
                            vertical: sizeContextOf(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Priority: ${task.priority?.isNotEmpty == true ? task.priority : 'No priority'}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: sizeContextOf(context, 6),
                            vertical: sizeContextOf(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Weight: ${task.weight ?? 'No weight'}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        _TaskStatusBadge(status: task.status),
                      ],
                    ),
                    SizedBox(height: sizeContextOf(context, 8)),
                    Text(
                      task.description?.isNotEmpty == true
                          ? task.description!
                          : 'No description',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: task.description?.isNotEmpty == true
                            ? FontStyle.normal
                            : FontStyle.italic,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: sizeContextOf(context, 12)),
                    LinearProgressIndicator(
                      value: task.progress / 100,
                      backgroundColor: Colors.black12,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.success,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              SizedBox(width: sizeContextOf(context, 16)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 8), vertical: sizeContextOf(context, 4)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCA28), // Yellow badge
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${task.progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          children: [
            if (children.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: sizeContextOf(context, 16.0),
                  right: sizeContextOf(context, 16.0),
                  bottom: sizeContextOf(context, 8.0),
                ),
                child: Column(
                  children: children.map((childTask) {
                    return _TaskNode(
                      task: childTask,
                      childrenMap: childrenMap,
                      depth: depth + 1,
                      isExpanded: isExpanded,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskStatusBadge extends StatelessWidget {
  final String status;

  const _TaskStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'open':
      case 'active':
        color = AppColors.primary;
        break;
      case 'overdue':
        color = AppColors.error;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 6), vertical: sizeContextOf(context, 2)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
