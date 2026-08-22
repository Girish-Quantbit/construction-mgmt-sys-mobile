import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/features/projects/domain/entities/project.dart';

class ProjectSelectionDropdown extends StatefulWidget {
  final List<Project> projects;
  final List<String> sites;
  final Project? initialProject;
  final String? initialSite;
  final bool isLoadingSites;
  final Function(String site, Project project) onSelected;

  const ProjectSelectionDropdown({
    super.key,
    required this.projects,
    required this.sites,
    this.initialProject,
    this.initialSite,
    required this.isLoadingSites,
    required this.onSelected,
  });

  @override
  State<ProjectSelectionDropdown> createState() =>
      _ProjectSelectionDropdownState();
}

class _ProjectSelectionDropdownState extends State<ProjectSelectionDropdown> {
  String? _tempSelectedSite;

  @override
  void initState() {
    super.initState();
    _tempSelectedSite = widget.initialSite;
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
        return AppColors.primaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = widget.projects
        .where((p) => (p.site ?? 'Unspecified Site') == _tempSelectedSite)
        .toList();

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top:
                MediaQuery.of(context).padding.top +
                sizeContextOf(context, AppSizes.s16),
            left: sizeContextOf(context, AppSizes.s20),
            right: sizeContextOf(context, AppSizes.s20),
            bottom: sizeContextOf(context, AppSizes.s24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tempSelectedSite == null
                              ? 'Select Site'
                              : 'Select Project',
                          style: TextStyle(
                            fontSize: sizeContextOf(context, 20),
                            fontWeight: FontWeight.w800,
                            fontFamily: 'HankenGrotesk',
                            color: AppColors.primaryText,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, AppSizes.s4)),
                        Text(
                          _tempSelectedSite == null
                              ? 'Step 1 of 2'
                              : 'Step 2 of 2: $_tempSelectedSite',
                          style: TextStyle(
                            fontSize: sizeContextOf(context, 12),
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: sizeContextOf(context, AppSizes.s12)),
              const Divider(color: AppColors.divider, height: 1),
              SizedBox(height: sizeContextOf(context, AppSizes.s12)),

              // Back button when inside Project list
              if (_tempSelectedSite != null)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: sizeContextOf(context, AppSizes.s8),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _tempSelectedSite = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: sizeContextOf(context, 10),
                        horizontal: sizeContextOf(context, AppSizes.s12),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: AppColors.primaryText,
                          ),
                          SizedBox(width: sizeContextOf(context, AppSizes.s8)),
                          Text(
                            'Back to Sites list',
                            style: TextStyle(
                              fontSize: sizeContextOf(context, 13),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: widget.isLoadingSites
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(
                            sizeContextOf(context, AppSizes.s32),
                          ),
                          child: const CircularProgressIndicator(),
                        ),
                      )
                    : _tempSelectedSite == null
                    ? ListView.separated(
                        shrinkWrap: true,
                        itemCount: widget.sites.length,
                        separatorBuilder: (context, index) => SizedBox(
                          height: sizeContextOf(context, AppSizes.s8),
                        ),
                        itemBuilder: (context, index) {
                          final site = widget.sites[index];
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: sizeContextOf(
                                  context,
                                  AppSizes.s16,
                                ),
                                vertical: sizeContextOf(context, AppSizes.s4),
                              ),
                              leading: Container(
                                padding: EdgeInsets.all(
                                  sizeContextOf(context, AppSizes.s8),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                site,
                                style: TextStyle(
                                  fontSize: sizeContextOf(context, 14),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.secondaryText,
                              ),
                              onTap: () {
                                setState(() {
                                  _tempSelectedSite = site;
                                });
                              },
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredProjects.length,
                        separatorBuilder: (context, index) => SizedBox(
                          height: sizeContextOf(context, AppSizes.s8),
                        ),
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          final isSelected =
                              widget.initialProject?.name == project.name;
                          final statusColor = _getStatusColor(project.status);

                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: sizeContextOf(
                                  context,
                                  AppSizes.s16,
                                ),
                                vertical: sizeContextOf(context, AppSizes.s16),
                              ),
                              leading: Container(
                                padding: EdgeInsets.all(
                                  sizeContextOf(context, AppSizes.s8),
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: 0.08,
                                        )
                                      : AppColors.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                project.projectName,
                                style: TextStyle(
                                  fontSize: sizeContextOf(context, 14),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(
                                  top: sizeContextOf(context, AppSizes.s4),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: sizeContextOf(context, 6),
                                      height: sizeContextOf(context, 6),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: sizeContextOf(context, 6)),
                                    Text(
                                      project.status,
                                      style: TextStyle(
                                        fontSize: sizeContextOf(context, 11),
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    )
                                  : null,
                              onTap: () {
                                widget.onSelected(_tempSelectedSite!, project);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
