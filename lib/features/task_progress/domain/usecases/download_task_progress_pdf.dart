import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/task_progress_repository.dart';

class DownloadTaskProgressPdf {
  final TaskProgressRepository repository;

  DownloadTaskProgressPdf(this.repository);

  Future<Either<Failure, Uint8List>> call(String entryName) {
    return repository.downloadPdf(entryName);
  }
}
