import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.name,
    required super.projectName,
    required super.status,
    required super.progress,
    super.description,
    super.priority,
    super.expectedStartDate,
    super.expectedEndDate,
    super.site,
    super.projectType,
    super.isActive,
    super.perGrossMargin,
    super.department,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      name: json['name'] ?? '',
      projectName: json['project_name'] ?? '',
      status: json['status'] ?? '',
      progress: (json['percent_complete'] as num?)?.toDouble() ?? 0.0,
      description: json['notes'],
      priority: json['priority'],
      expectedStartDate: json['expected_start_date'] != null
          ? DateTime.tryParse(json['expected_start_date'])
          : null,
      expectedEndDate: json['expected_end_date'] != null
          ? DateTime.tryParse(json['expected_end_date'])
          : null,
      site: json['custom_site']?.toString(),
      projectType: json['project_type']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == "Yes",
      perGrossMargin: (json['per_gross_margin'] as num?)?.toDouble(),
      department: json['department']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'project_name': projectName,
      'status': status,
      'percent_complete': progress,
      'notes': description,
      'priority': priority,
      'expected_start_date': expectedStartDate?.toIso8601String(),
      'expected_end_date': expectedEndDate?.toIso8601String(),
      'custom_site': site,
      'project_type': projectType,
      'is_active': isActive == true ? 1 : 0,
      'per_gross_margin': perGrossMargin,
      'department': department,
    };
  }
}
