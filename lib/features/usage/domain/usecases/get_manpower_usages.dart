import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/manpower_usage.dart';
import '../repositories/manpower_usage_repository.dart';

class GetManpowerUsages {
  final ManpowerUsageRepository repository;

  GetManpowerUsages(this.repository);

  Future<Either<Failure, List<ManpowerUsage>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  }) {
    return repository.getManpowerUsages(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      project: project,
    );
  }
}
