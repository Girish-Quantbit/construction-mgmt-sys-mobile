import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/site_diary.dart';
import '../repositories/site_diary_repository.dart';

class GetSiteDiaries {
  final SiteDiaryRepository repository;

  GetSiteDiaries(this.repository);

  Future<Either<Failure, List<SiteDiary>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  }) {
    return repository.getSiteDiaries(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      project: project,
    );
  }
}
