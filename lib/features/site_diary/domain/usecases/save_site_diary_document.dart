import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../repositories/site_diary_repository.dart';

class SaveSiteDiaryDocument {
  final SiteDiaryRepository repository;

  SaveSiteDiaryDocument(this.repository);

  Future<Either<Failure, dynamic>> call({
    required String? name,
    required Map<String, dynamic> payload,
    required Document? existingDocument,
  }) {
    return repository.saveDocument(
      name: name,
      payload: payload,
      existingDocument: existingDocument,
    );
  }
}
