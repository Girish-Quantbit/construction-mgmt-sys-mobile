import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../repositories/equipment_usage_repository.dart';

class GetEquipmentUsageMeta {
  final EquipmentUsageRepository repository;

  GetEquipmentUsageMeta(this.repository);

  Future<Either<Failure, DocTypeMeta>> call() {
    return repository.getMeta();
  }
}
