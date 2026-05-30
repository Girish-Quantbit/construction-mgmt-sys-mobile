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

  const Project({
    required this.name,
    required this.projectName,
    required this.status,
    required this.progress,
    this.description,
    this.priority,
    this.expectedStartDate,
    this.expectedEndDate,
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
  ];
}
