import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_progress.dart';
import '../repositories/task_progress_repository.dart';

class GetTaskProgressDetails {
  final TaskProgressRepository repository;

  GetTaskProgressDetails(this.repository);

  Future<Either<Failure, TaskProgress>> call(String name) {
    return repository.getTaskProgressDetails(name);
  }
}
