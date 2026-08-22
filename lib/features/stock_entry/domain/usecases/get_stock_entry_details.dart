import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/stock_entry.dart';
import '../repositories/stock_entry_repository.dart';

class GetStockEntryDetails {
  final StockEntryRepository repository;

  GetStockEntryDetails(this.repository);

  Future<Either<Failure, StockEntry>> call(String name) {
    return repository.getStockEntryDetails(name);
  }
}
