import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/project_bloc.dart';
import '../../domain/entities/project.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class ProjectTimelinePage extends StatelessWidget {
  const ProjectTimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Project Timeline'),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (state is ProjectLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProjectError) {
            return Center(child: Text(state.message));
          } else if (state is ProjectLoaded) {
            final projectsWithDates = state.projects
                .where(
                  (p) =>
                      p.expectedStartDate != null && p.expectedEndDate != null,
                )
                .toList();

            if (projectsWithDates.isEmpty) {
              return const Center(
                child: Text('No projects with start and end dates'),
              );
            }

            // Find overall date range
            DateTime minDate = projectsWithDates
                .map((p) => p.expectedStartDate!)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            DateTime maxDate = projectsWithDates
                .map((p) => p.expectedEndDate!)
                .reduce((a, b) => a.isAfter(b) ? a : b);

            // Add some padding to dates
            minDate = DateTime(minDate.year, minDate.month, 1);
            maxDate = DateTime(maxDate.year, maxDate.month + 1, 0);

            return _TimelineView(
              projects: projectsWithDates,
              minDate: minDate,
              maxDate: maxDate,
            );
          }
          return const Center(child: Text('Initial State'));
        },
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  final List<Project> projects;
  final DateTime minDate;
  final DateTime maxDate;

  const _TimelineView({
    required this.projects,
    required this.minDate,
    required this.maxDate,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = maxDate.difference(minDate).inDays + 1;
    const double dayWidth = 50.0;
    const double projectHeight = 80.0;
    const double headerHeight = 60.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalDays * dayWidth + 200, // +200 for project names
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with months/days
              SizedBox(
                height: headerHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 200), // Space for project names
                    ...List.generate(totalDays, (index) {
                      final date = minDate.add(Duration(days: index));
                      final isFirstOfMonth = date.day == 1;
                      return Container(
                        width: dayWidth,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isFirstOfMonth
                                  ? AppColors.outline
                                  : AppColors.outlineVariant.withOpacity(0.3),
                              width: isFirstOfMonth ? 1 : 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isFirstOfMonth)
                              Text(
                                DateFormat('MMM').format(date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: date.weekday > 5
                                    ? AppColors.error
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Projects rows
              ...projects.map((project) {
                final startOffset = project.expectedStartDate!
                    .difference(minDate)
                    .inDays;
                final duration =
                    project.expectedEndDate!
                        .difference(project.expectedStartDate!)
                        .inDays +
                    1;

                return SizedBox(
                  height: projectHeight,
                  child: Stack(
                    children: [
                      // Project Name
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 200,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.outlineVariant.withOpacity(
                                  0.2,
                                ),
                              ),
                              right: const BorderSide(
                                color: AppColors.outlineVariant,
                              ),
                            ),
                          ),
                          child: Text(
                            project.projectName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Grid background
                      Positioned(
                        left: 200,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: List.generate(totalDays, (index) {
                            final date = minDate.add(Duration(days: index));
                            return Container(
                              width: dayWidth,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.outlineVariant.withOpacity(
                                      0.1,
                                    ),
                                    width: 0.5,
                                  ),
                                  bottom: BorderSide(
                                    color: AppColors.outlineVariant.withOpacity(
                                      0.1,
                                    ),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // Timeline Bar
                      Positioned(
                        left: 200 + (startOffset * dayWidth),
                        width: duration * dayWidth,
                        top: 20,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              project.status,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(project.status),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${project.progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(project.status),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Overdue':
        return AppColors.error;
      case 'On Track':
        return AppColors.success;
      case 'In Review':
        return AppColors.secondary;
      case 'Delayed':
        return AppColors.warning;
      case 'Completed':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
