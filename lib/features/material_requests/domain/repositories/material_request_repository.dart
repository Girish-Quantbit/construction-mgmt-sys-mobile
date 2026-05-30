import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/material_request.dart';

abstract class MaterialRequestRepository {
  Future<Either<Failure, List<MaterialRequest>>> getMaterialRequests({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  });

  Future<Either<Failure, MaterialRequest>> getMaterialRequestDetails(
    String name,
  );
}
