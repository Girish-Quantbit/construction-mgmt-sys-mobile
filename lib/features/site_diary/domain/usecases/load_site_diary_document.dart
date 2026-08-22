import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../repositories/site_diary_repository.dart';

class LoadSiteDiaryDocument {
  final SiteDiaryRepository repository;

  LoadSiteDiaryDocument(this.repository);

  Future<Either<Failure, Document>> call({
    String? diaryName,
    String? project,
  }) {
    return repository.loadDocument(diaryName, project);
  }
}
