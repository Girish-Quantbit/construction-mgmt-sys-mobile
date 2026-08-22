import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../repositories/manpower_usage_repository.dart';

class GetManpowerUsageMeta {
  final ManpowerUsageRepository repository;

  GetManpowerUsageMeta(this.repository);

  Future<Either<Failure, DocTypeMeta>> call() {
    return repository.getMeta();
  }
}
