import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/material_request_repository.dart';

class DownloadMaterialRequestPDFUsecase {
  final MaterialRequestRepository repository;

  DownloadMaterialRequestPDFUsecase(this.repository);

  Future<Either<Failure, String>> call(String name) {
    return repository.downloadPDF(name);
  }
}
