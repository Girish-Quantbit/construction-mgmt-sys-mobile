import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/equipment_usage.dart';

abstract class EquipmentUsageRepository {
  Future<Either<Failure, List<EquipmentUsage>>> getEquipmentUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  Future<Either<Failure, EquipmentUsage>> getEquipmentUsageDetails(String name);
}
