import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/task_progress_repository.dart';

class SaveTaskProgressDocument {
  final TaskProgressRepository repository;

  SaveTaskProgressDocument(this.repository);

  Future<Either<Failure, String>> call({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  }) {
    return repository.saveDocument(
      existingServerId: existingServerId,
      payload: payload,
    );
  }
}
