import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/site_diary_repository.dart';

class UploadSiteDiaryFile {
  final SiteDiaryRepository repository;

  UploadSiteDiaryFile(this.repository);

  Future<Either<Failure, String?>> call({
    required String filePath,
    required String docName,
    required String doctype,
    required String docfield,
  }) {
    return repository.uploadFile(
      filePath: filePath,
      docName: docName,
      doctype: doctype,
      docfield: docfield,
    );
  }
}
