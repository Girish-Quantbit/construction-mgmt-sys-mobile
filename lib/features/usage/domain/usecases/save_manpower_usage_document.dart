import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/manpower_usage_repository.dart';

class SaveManpowerUsageDocument {
  final ManpowerUsageRepository repository;

  SaveManpowerUsageDocument(this.repository);

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
