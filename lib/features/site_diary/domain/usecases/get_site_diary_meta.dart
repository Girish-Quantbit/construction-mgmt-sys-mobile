import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../repositories/site_diary_repository.dart';

class GetSiteDiaryMeta {
  final SiteDiaryRepository repository;

  GetSiteDiaryMeta(this.repository);

  Future<Either<Failure, DocTypeMeta>> call() {
    return repository.getMeta();
  }
}
