import 'package:flutter/material.dart';
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
    String? materialRequestType,
    DateTimeRange? requiredByDateRange,
    DateTimeRange? transactionDateRange,
  });

  Future<Either<Failure, MaterialRequest>> getMaterialRequestDetails(
    String name,
  );

  Future<Either<Failure, String>> downloadPDF(String name);
}
