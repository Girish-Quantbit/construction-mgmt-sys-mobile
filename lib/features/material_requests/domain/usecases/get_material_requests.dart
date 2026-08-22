import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/material_request.dart';
import '../repositories/material_request_repository.dart';

class GetMaterialRequests {
  final MaterialRequestRepository repository;

  GetMaterialRequests(this.repository);

  Future<Either<Failure, List<MaterialRequest>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
    String? materialRequestType,
    DateTimeRange? requiredByDateRange,
    DateTimeRange? transactionDateRange,
  }) {
    return repository.getMaterialRequests(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      project: project,
      materialRequestType: materialRequestType,
      requiredByDateRange: requiredByDateRange,
      transactionDateRange: transactionDateRange,
    );
  }
}
