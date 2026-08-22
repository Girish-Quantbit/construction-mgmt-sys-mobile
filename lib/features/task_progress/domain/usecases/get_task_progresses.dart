import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_progress.dart';
import '../repositories/task_progress_repository.dart';

class GetTaskProgresses {
  final TaskProgressRepository repository;

  GetTaskProgresses(this.repository);

  Future<Either<Failure, List<TaskProgress>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? project,
  }) {
    return repository.getTaskProgresses(
      page: page,
      pageSize: pageSize,
      search: search,
      project: project,
    );
  }
}
