import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/manpower_usage.dart';
import '../repositories/manpower_usage_repository.dart';

class GetManpowerUsageDetails {
  final ManpowerUsageRepository repository;

  GetManpowerUsageDetails(this.repository);

  Future<Either<Failure, ManpowerUsage>> call(String name) {
    return repository.getManpowerUsageDetails(name);
  }
}
