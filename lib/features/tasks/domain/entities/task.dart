import 'package:equatable/equatable.dart';

class ProjectTask extends Equatable {
  final String name;
  final String subject;
  final String status;
  final String project;
  final String? description;
  final DateTime? expEndDate;
  final double progress;
  final String? priority;
  final double? weight;
  final String? parentTask;
  final bool isGroup;

  const ProjectTask({
    required this.name,
    required this.subject,
    required this.status,
    required this.project,
    this.description,
    this.expEndDate,
    required this.progress,
    this.priority,
    this.weight,
    this.parentTask,
    this.isGroup = false,
  });

  @override
  List<Object?> get props => [
    name,
    subject,
    status,
    project,
    description,
    expEndDate,
    progress,
    priority,
    weight,
    parentTask,
    isGroup,
  ];
}
