import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/manpower_usage.dart';

abstract class ManpowerUsageRepository {
  Future<Either<Failure, List<ManpowerUsage>>> getManpowerUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  Future<Either<Failure, ManpowerUsage>> getManpowerUsageDetails(String name);
}
