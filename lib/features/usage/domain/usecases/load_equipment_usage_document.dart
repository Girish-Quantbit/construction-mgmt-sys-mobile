import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/equipment_usage_repository.dart';

class LoadEquipmentUsageDocument {
  final EquipmentUsageRepository repository;

  LoadEquipmentUsageDocument(this.repository);

  Future<Either<Failure, Map<String, dynamic>?>> call(String? usageName) {
    return repository.loadDocument(usageName);
  }
}
