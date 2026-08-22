import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/equipment_usage.dart';
import '../repositories/equipment_usage_repository.dart';

class GetEquipmentUsageDetails {
  final EquipmentUsageRepository repository;

  GetEquipmentUsageDetails(this.repository);

  Future<Either<Failure, EquipmentUsage>> call(String name) {
    return repository.getEquipmentUsageDetails(name);
  }
}
