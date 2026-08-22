import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/manpower_usage_repository.dart';

class LoadManpowerUsageDocument {
  final ManpowerUsageRepository repository;

  LoadManpowerUsageDocument(this.repository);

  Future<Either<Failure, Map<String, dynamic>?>> call(String? usageName) {
    return repository.loadDocument(usageName);
  }
}
