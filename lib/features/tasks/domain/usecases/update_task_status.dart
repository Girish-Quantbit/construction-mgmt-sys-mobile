import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTaskStatus {
  final TaskRepository repository;

  UpdateTaskStatus(this.repository);

  Future<Either<Failure, ProjectTask>> call(String name, String status) {
    return repository.updateTaskStatus(name, status);
  }
}
