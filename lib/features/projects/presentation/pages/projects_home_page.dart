import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/features/projects/presentation/bloc/project_bloc.dart';
import 'package:cms/features/projects/domain/entities/project.dart';
import 'package:intl/intl.dart';

import 'package:cms/features/projects/presentation/pages/project_list_page.dart';
import 'package:cms/features/usage/presentation/pages/usage_page.dart';
import 'package:cms/features/auth/presentation/pages/profile_page.dart';
import 'package:cms/features/task_progress/presentation/pages/task_progress_list_page.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_bloc.dart';
import 'package:cms/core/di/injection_container.dart';

class ProjectsHomePage extends StatefulWidget {
  const ProjectsHomePage({super.key});

  @override
  State<ProjectsHomePage> createState() => _ProjectsHomePageState();
}

class _ProjectsHomePageState extends State<ProjectsHomePage> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _isSearching = false;
  Project? _selectedProject;
  String? _selectedSite;

  List<Project> _getFilteredAndSortedProjects(List<Project> projects) {
    var filtered = projects.where((p) {
      if (_selectedSite != null &&
          (p.site ?? 'Unspecified Site') != _selectedSite) {
        return false;
      }
      if (_selectedProject != null && p.name != _selectedProject!.name) {
        return false;
      }
      final query = _searchQuery.toLowerCase();
      return p.projectName.toLowerCase().contains(query) ||
          p.status.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'name') {
        return a.projectName.toLowerCase().compareTo(
          b.projectName.toLowerCase(),
        );
      } else if (_sortBy == 'progress') {
        return b.progress.compareTo(a.progress);
      } else if (_sortBy == 'expectedEndDate') {
        if (a.expectedEndDate == null && b.expectedEndDate == null) return 0;
        if (a.expectedEndDate == null) return 1;
        if (b.expectedEndDate == null) return -1;
        return a.expectedEndDate!.compareTo(b.expectedEndDate!);
      } else if (_sortBy == 'priority') {
        final pA = _priorityValue(a.priority);
        final pB = _priorityValue(b.priority);
        return pB.compareTo(pA); // Highest priority first
      } else if (_sortBy == 'status') {
        return a.status.toLowerCase().compareTo(b.status.toLowerCase());
      }
      return 0;
    });

    return filtered;
  }

  int _priorityValue(String? priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  void _showSelectionSheet(BuildContext context) {
    final state = context.read<ProjectBloc>().state;
    if (state is! ProjectLoaded) return;

    final projects = state.projects;
    final sites = projects
        .map((p) => p.site ?? 'Unspecified Site')
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.all(sizeContextOf(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedSite == null
                            ? 'Select Site'
                            : 'Select Project',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_selectedSite != null)
                    ListTile(
                      leading: const Icon(Icons.arrow_back),
                      title: const Text('Back to Sites'),
                      onTap: () {
                        setSheetState(() {
                          _selectedSite = null;
                        });
                        setState(() {});
                      },
                    ),
                  Expanded(
                    child: _selectedSite == null
                        ? ListView.builder(
                            itemCount: sites.length,
                            itemBuilder: (context, index) {
                              final site = sites[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primary,
                                ),
                                title: Text(site),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  setSheetState(() {
                                    _selectedSite = site;
                                  });
                                  setState(() {});
                                },
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: projects
                                .where(
                                  (p) =>
                                      (p.site ?? 'Unspecified Site') ==
                                      _selectedSite,
                                )
                                .length,
                            itemBuilder: (context, index) {
                              final siteProjects = projects
                                  .where(
                                    (p) =>
                                        (p.site ?? 'Unspecified Site') ==
                                        _selectedSite,
                                  )
                                  .toList();
                              final project = siteProjects[index];
                              final isSelected =
                                  _selectedProject?.name == project.name;
                              return ListTile(
                                leading: Icon(
                                  Icons.assignment_outlined,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                                title: Text(project.projectName),
                                subtitle: Text(project.status),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedProject = project;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                  if (_selectedProject != null || _selectedSite != null)
                    Padding(
                      padding: EdgeInsets.only(top: sizeContextOf(context, 8.0)),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedProject = null;
                            _selectedSite = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Clear Filters',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: _selectedProject?.projectName ?? 'Select Project',
        subtitle: _selectedSite ?? 'Select Site',
        onTitleTap: () => _showSelectionSheet(context),
      ),
      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectLoaded &&
              state.projects.isNotEmpty &&
              _selectedProject == null) {
            final firstProject = state.projects.first;
            setState(() {
              _selectedProject = firstProject;
              _selectedSite = firstProject.site ?? 'Unspecified Site';
            });
          }
        },
        child: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            List<Project> displayProjects = [];
            if (state is ProjectLoaded) {
              displayProjects = _getFilteredAndSortedProjects(state.projects);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProjectBloc>().add(GetProjectsRequested());
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isSearching
                            ? Row(
                                key: const ValueKey('searching_header'),
                                children: [
                                  Expanded(
                                    child: TextField(
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        hintText: 'Search projects...',
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isSearching = false;
                                              _searchQuery = '';
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.outlineVariant,
                                          ),
                                        ),
                                        contentPadding:
                                            EdgeInsets.symmetric(
                                              horizontal: sizeContextOf(context, 12),
                                              vertical: sizeContextOf(context, 8),
                                            ),
                                        filled: true,
                                        fillColor:
                                            AppColors.surfaceContainerLowest,
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: sizeContextOf(context, 8)),
                                  _buildSortMenu(context),
                                ],
                              )
                            : Row(
                                key: const ValueKey('normal_header'),
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Projects',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineLarge,
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.search,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isSearching = true;
                                          });
                                        },
                                      ),
                                      _buildSortMenu(context),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (state is ProjectLoaded && state.projects.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSummarySection(state.projects),
                    ),
                  if (state is ProjectLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is ProjectError)
                    SliverFillRemaining(
                      child: Center(child: Text(state.message)),
                    )
                  else if (state is ProjectLoaded)
                    displayProjects.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 24)),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 400,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    mainAxisExtent: 120,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                return ProjectCard(
                                  project: displayProjects[index],
                                );
                              }, childCount: displayProjects.length),
                            ),
                          ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                    ), // Space for bottom nav and FAB
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, color: AppColors.onSurfaceVariant),
      tooltip: 'Sort projects',
      onSelected: (val) {
        setState(() {
          _sortBy = val;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'name', child: Text('Sort by Name')),
        PopupMenuItem(value: 'progress', child: Text('Sort by Progress')),
        PopupMenuItem(
          value: 'expectedEndDate',
          child: Text('Sort by End Date'),
        ),
        PopupMenuItem(value: 'priority', child: Text('Sort by Priority')),
        PopupMenuItem(value: 'status', child: Text('Sort by Status')),
      ],
    );
  }

  Widget _buildSummarySection(List<Project> projects) {
    final totalProjects = projects.length;
    final onTrack = projects.where((p) => p.status == 'On Track').length;
    final overdue = projects.where((p) => p.status == 'Overdue').length;
    final inReview = projects.where((p) => p.status == 'In Review').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 24), vertical: sizeContextOf(context, 8)),
      child: Row(
        children: [
          _buildSummaryCard(
            'Total Projects',
            totalProjects.toString(),
            Icons.business_center,
            AppColors.primary,
          ),
          SizedBox(width: sizeContextOf(context, 12)),
          _buildSummaryCard(
            'On Track',
            onTrack.toString(),
            Icons.check_circle_outline,
            AppColors.success,
          ),
          SizedBox(width: sizeContextOf(context, 12)),
          _buildSummaryCard(
            'Overdue',
            overdue.toString(),
            Icons.error_outline,
            AppColors.error,
          ),
          SizedBox(width: sizeContextOf(context, 12)),
          _buildSummaryCard(
            'In Review',
            inReview.toString(),
            Icons.assignment_outlined,
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(sizeContextOf(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(sizeContextOf(context, 8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: sizeContextOf(context, 12)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_business,
            size: 48,
            color: AppColors.outlineVariant,
          ),
          SizedBox(height: sizeContextOf(context, 16)),
          const Text(
            'No active projects matching filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: sizeContextOf(context, 16)),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 24), vertical: sizeContextOf(context, 12)),
              minimumSize: const Size(0, 0),
            ),
            child: const Text('Create New Project'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: EdgeInsets.only(bottom: sizeContextOf(context, 8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(
            context,
            icon: Icons.home_work,
            label: 'Projects',
            isActive: true,
            onTap: () {},
          ),
          _buildNavBarItem(
            context,
            icon: Icons.trending_up,
            label: 'Progress',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => sl<TaskProgressBloc>(),
                    child: const TaskProgressListPage(),
                  ),
                ),
              );
            },
          ),
          _buildNavBarItem(
            context,
            icon: Icons.analytics_outlined,
            label: 'Usage',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsagePage()),
              );
            },
          ),
          _buildNavBarItem(
            context,
            icon: Icons.account_circle,
            label: 'Profile',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 20), vertical: sizeContextOf(context, 8)),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.onSecondaryContainer
                  : AppColors.onSurfaceVariant,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(project.status);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectListPage(project: project),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 16), vertical: sizeContextOf(context, 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.projectName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 8)),
                _buildStatusBadge(context, project.status),
              ],
            ),
            if (project.projectType != null && project.projectType!.isNotEmpty) ...[
              SizedBox(height: sizeContextOf(context, 4)),
              Text(
                project.projectType!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            SizedBox(height: sizeContextOf(context, 8)),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(sizeContextOf(context, 4)),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      project.priority,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.flag,
                    size: 12,
                    color: _getPriorityColor(project.priority),
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 6)),
                Expanded(
                  child: Text(
                    project.priority ?? 'Medium',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getPriorityColor(project.priority),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 12)),
                Container(
                  padding: EdgeInsets.all(sizeContextOf(context, 4)),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 6)),
                Text(
                  project.expectedStartDate != null && project.expectedEndDate != null
                      ? '${DateFormat('MMM dd, yyyy').format(project.expectedStartDate!)} - ${DateFormat('MMM dd, yyyy').format(project.expectedEndDate!)}'
                      : project.expectedEndDate != null
                          ? 'Ends: ${DateFormat('MMM dd, yyyy').format(project.expectedEndDate!)}'
                          : project.expectedStartDate != null
                              ? 'Starts: ${DateFormat('MMM dd, yyyy').format(project.expectedStartDate!)}'
                              : 'No dates set',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            Row(
              children: [
                Text(
                  '${project.progress.toInt()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 12)),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: project.progress / 100,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
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
      case 'Draft':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    switch (status) {
      case 'Overdue':
        color = AppColors.error;
        break;
      case 'On Track':
        color = AppColors.success;
        break;
      case 'In Review':
        color = AppColors.secondary;
        break;
      case 'Delayed':
        color = AppColors.warning;
        break;
      case 'Completed':
        color = AppColors.success;
        break;
      case 'Draft':
        color = Colors.grey;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 10), vertical: sizeContextOf(context, 4)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
