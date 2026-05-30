import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FrappeSDK sdk;

  TaskRepositoryImpl(this.sdk);

  @override
  Future<Either<Failure, List<ProjectTask>>> getTasks({String? project}) async {
    try {
      final List<List<dynamic>> filters = [];
      if (project != null) {
        filters.add(['Task', 'project', '=', project]);
      }

      final List<dynamic> dataList = await sdk.api.doctype.list(
        'Task',
        filters: filters,
        fields: [
          'name',
          'subject',
          'status',
          'project',
          'description',
          'exp_end_date',
          'progress',
          'priority',
          'task_weight',
          'parent_task',
          'is_group',
        ],
      );

      final tasks = dataList.map((data) {
        return ProjectTask(
          name: data['name'] ?? '',
          subject: data['subject'] ?? '',
          status: data['status'] ?? '',
          project: data['project'] ?? '',
          description: data['description'],
          expEndDate: data['exp_end_date'] != null
              ? DateTime.tryParse(data['exp_end_date'])
              : null,
          progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
          priority: data['priority'],
          weight: (data['task_weight'] as num?)?.toDouble(),
          parentTask: data['parent_task'],
          isGroup: data['is_group'] == 1,
        );
      }).toList();

      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProjectTask>> updateTaskStatus(
    String name,
    String status,
  ) async {
    try {
      final Map<String, dynamic> data = await sdk.api.document.updateDocument(
        'Task',
        name,
        {'status': status},
      );

      return Right(
        ProjectTask(
          name: data['name'] ?? '',
          subject: data['subject'] ?? '',
          status: data['status'] ?? '',
          project: data['project'] ?? '',
          description: data['description'],
          expEndDate: data['exp_end_date'] != null
              ? DateTime.tryParse(data['exp_end_date'])
              : null,
          progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
          priority: data['priority'],
          weight: (data['task_weight'] as num?)?.toDouble(),
          parentTask: data['parent_task'],
          isGroup: data['is_group'] == 1,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
