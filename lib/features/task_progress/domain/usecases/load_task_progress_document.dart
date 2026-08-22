import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/task_progress_repository.dart';

class LoadTaskProgressDocument {
  final TaskProgressRepository repository;

  LoadTaskProgressDocument(this.repository);

  Future<Either<Failure, Map<String, dynamic>?>> call(String? progressName) {
    return repository.loadDocument(progressName);
  }
}
