import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/stock_entry.dart';

abstract class StockEntryRepository {
  Future<Either<Failure, List<StockEntry>>> getStockEntries({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? stockEntryType,
    String? project,
  });

  Future<Either<Failure, StockEntry>> getStockEntryDetails(String name);
}
