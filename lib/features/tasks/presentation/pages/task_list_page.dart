import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:cms/features/tasks/domain/entities/task.dart';

class TaskListPage extends StatefulWidget {
  final String? project;

  const TaskListPage({super.key, this.project});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(GetTasksRequested(project: widget.project));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.project ?? 'Project Tasks',
        showSearch: false,
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is TaskLoaded) {
            if (state.tasks.isEmpty) {
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

            for (var task in state.tasks) {
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
                    padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
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
      margin: const EdgeInsets.only(bottom: 12),
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
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
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
                    const SizedBox(height: 8),
                    Text(
                      task.description?.isNotEmpty == true
                          ? task.description!
                          : 'No description',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: task.description?.isNotEmpty == true
                            ? FontStyle.normal
                            : FontStyle.italic,
                        color: textColor.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
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
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 8.0,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
