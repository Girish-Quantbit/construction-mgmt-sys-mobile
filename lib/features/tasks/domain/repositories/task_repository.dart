import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<ProjectTask>>> getTasks({String? project});
  Future<Either<Failure, ProjectTask>> updateTaskStatus(
    String name,
    String status,
  );
}
