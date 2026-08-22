import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/equipment_usage_repository.dart';

class DownloadEquipmentUsagePdf {
  final EquipmentUsageRepository repository;

  DownloadEquipmentUsagePdf(this.repository);

  Future<Either<Failure, Uint8List>> call(String entryName) {
    return repository.downloadPdf(entryName);
  }
}
