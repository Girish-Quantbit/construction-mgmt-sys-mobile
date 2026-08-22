import '../../domain/entities/task.dart';

class TaskModel extends ProjectTask {
  const TaskModel({
    required super.name,
    required super.subject,
    required super.status,
    required super.project,
    super.description,
    super.expEndDate,
    required super.progress,
    super.priority,
    super.weight,
    super.parentTask,
    super.isGroup,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      status: json['status'] ?? '',
      project: json['project'] ?? '',
      description: json['description'],
      expEndDate: json['exp_end_date'] != null
          ? DateTime.tryParse(json['exp_end_date'])
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      priority: json['priority'],
      weight: (json['task_weight'] as num?)?.toDouble(),
      parentTask: json['parent_task'],
      isGroup: json['is_group'] == 1 || json['is_group'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subject': subject,
      'status': status,
      'project': project,
      'description': description,
      'exp_end_date': expEndDate?.toIso8601String(),
      'progress': progress,
      'priority': priority,
      'task_weight': weight,
      'parent_task': parentTask,
      'is_group': isGroup ? 1 : 0,
    };
  }
}
