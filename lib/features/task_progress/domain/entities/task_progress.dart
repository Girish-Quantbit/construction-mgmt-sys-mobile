import 'package:equatable/equatable.dart';
import 'task_progress_detail.dart';

class TaskProgress extends Equatable {
  final String name;
  final String? task;
  final String? taskSubject;
  final double progress;
  final DateTime? date;
  final String? description;
  final String project;
  final String status;
  final List<TaskProgressDetail> taskProgressDetails;
  final Map<String, dynamic> rawData;

  const TaskProgress({
    required this.name,
    this.task,
    this.taskSubject,
    this.progress = 0.0,
    this.date,
    this.description,
    required this.project,
    required this.status,
    this.taskProgressDetails = const [],
    this.rawData = const {},
  });

  @override
  List<Object?> get props => [
    name,
    task,
    taskSubject,
    progress,
    date,
    description,
    project,
    status,
    taskProgressDetails,
    rawData,
  ];
}
