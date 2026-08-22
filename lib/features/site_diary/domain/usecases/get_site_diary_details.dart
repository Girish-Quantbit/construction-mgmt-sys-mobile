import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/site_diary.dart';
import '../repositories/site_diary_repository.dart';

class GetSiteDiaryDetails {
  final SiteDiaryRepository repository;

  GetSiteDiaryDetails(this.repository);

  Future<Either<Failure, SiteDiary>> call(String name) {
    return repository.getSiteDiaryDetails(name);
  }
}
