import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/stock_entry_repository.dart';

class DownloadStockEntryPdf {
  final StockEntryRepository repository;

  DownloadStockEntryPdf(this.repository);

  Future<Either<Failure, Uint8List>> call(String entryName) {
    return repository.downloadPdf(entryName);
  }
}
