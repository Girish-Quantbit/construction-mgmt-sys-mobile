import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/material_request.dart';
import '../repositories/material_request_repository.dart';

class GetMaterialRequestDetails {
  final MaterialRequestRepository repository;

  GetMaterialRequestDetails(this.repository);

  Future<Either<Failure, MaterialRequest>> call(String name) {
    return repository.getMaterialRequestDetails(name);
  }
}
