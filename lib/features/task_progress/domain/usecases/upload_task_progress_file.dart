import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/task_progress_repository.dart';

class UploadTaskProgressFile {
  final TaskProgressRepository repository;

  UploadTaskProgressFile(this.repository);

  Future<Either<Failure, void>> call({
    required String serverName,
    required String filePath,
  }) {
    return repository.uploadFile(
      serverName: serverName,
      filePath: filePath,
    );
  }
}
