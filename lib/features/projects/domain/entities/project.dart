import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String name;
  final String projectName;
  final String status;
  final double progress;
  final String? description;
  final String? priority;
  final DateTime? expectedStartDate;
  final DateTime? expectedEndDate;
  final String? site;
  final String? projectType;
  final bool? isActive;
  final double? perGrossMargin;
  final String? department;

  const Project({
    required this.name,
    required this.projectName,
    required this.status,
    required this.progress,
    this.description,
    this.priority,
    this.expectedStartDate,
    this.expectedEndDate,
    this.site,
    this.projectType,
    this.isActive,
    this.perGrossMargin,
    this.department,
  });

  @override
  List<Object?> get props => [
    name,
    projectName,
    status,
    progress,
    description,
    priority,
    expectedStartDate,
    expectedEndDate,
    site,
    projectType,
    isActive,
    perGrossMargin,
    department,
  ];
}
