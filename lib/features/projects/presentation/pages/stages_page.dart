/*
import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/features/projects/presentation/bloc/project_bloc.dart';
import 'package:cms/features/projects/domain/entities/project.dart';
import 'package:cms/features/tasks/presentation/pages/task_list_page.dart';
import 'package:cms/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:cms/core/di/injection_container.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(GetProjectsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Projects',
        showSearch: true,
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (state is ProjectLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProjectError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  SizedBox(height: sizeContextOf(context, 16)),
                  Text('Error: ${state.message}'),
                  SizedBox(height: sizeContextOf(context, 16)),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ProjectBloc>().add(GetProjectsRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ProjectLoaded) {
            if (state.projects.isEmpty) {
              return const Center(child: Text('No projects found.'));
            }
            return ListView.separated(
              padding: EdgeInsets.all(sizeContextOf(context, 16)),
              itemCount: state.projects.length,
              separatorBuilder: (context, index) => SizedBox(height: sizeContextOf(context, 12)),
              itemBuilder: (context, index) {
                final project = state.projects[index];
                return _ProjectCard(project: project);
              },
            );
          }
          return const Center(child: Text('Initialize projects...'));
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => sl<TaskBloc>(),
                child: TaskListPage(project: project.name),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(sizeContextOf(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.projectName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _StatusChip(status: project.status),
                ],
              ),
              SizedBox(height: sizeContextOf(context, 8)),
              Text(
                'Project ID: ${project.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: sizeContextOf(context, 16)),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: AppColors.progressBackground,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.progressValue,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: sizeContextOf(context, 12)),
                  Text(
                    '${project.progress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: sizeContextOf(context, 8)),
              if (project.expectedEndDate != null)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: sizeContextOf(context, 4)),
                    Text(
                      'End Date: ${project.expectedEndDate!.toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'open':
      case 'active':
        color = AppColors.success;
        break;
      case 'delayed':
      case 'urgent':
        color = AppColors.error;
        break;
      case 'closed':
      case 'completed':
        color = AppColors.onSurfaceVariant;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 8), vertical: sizeContextOf(context, 4)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
*/
