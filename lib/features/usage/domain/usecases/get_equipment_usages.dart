import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/equipment_usage.dart';
import '../repositories/equipment_usage_repository.dart';

class GetEquipmentUsages {
  final EquipmentUsageRepository repository;

  GetEquipmentUsages(this.repository);

  Future<Either<Failure, List<EquipmentUsage>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? project,
  }) {
    return repository.getEquipmentUsages(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      project: project,
    );
  }
}
