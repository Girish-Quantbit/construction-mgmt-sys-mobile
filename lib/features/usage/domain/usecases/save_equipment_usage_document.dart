import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/equipment_usage_repository.dart';

class SaveEquipmentUsageDocument {
  final EquipmentUsageRepository repository;

  SaveEquipmentUsageDocument(this.repository);

  Future<Either<Failure, String>> call({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  }) {
    return repository.saveDocument(
      existingServerId: existingServerId,
      payload: payload,
    );
  }
}
