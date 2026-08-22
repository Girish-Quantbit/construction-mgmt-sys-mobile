import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/manpower_usage_repository.dart';

class DownloadManpowerUsagePdf {
  final ManpowerUsageRepository repository;

  DownloadManpowerUsagePdf(this.repository);

  Future<Either<Failure, Uint8List>> call(String entryName) {
    return repository.downloadPdf(entryName);
  }
}
