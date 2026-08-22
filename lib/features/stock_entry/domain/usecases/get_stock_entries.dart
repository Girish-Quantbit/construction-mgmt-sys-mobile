import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/stock_entry.dart';
import '../repositories/stock_entry_repository.dart';

class GetStockEntries {
  final StockEntryRepository repository;

  GetStockEntries(this.repository);

  Future<Either<Failure, List<StockEntry>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? stockEntryType,
    String? project,
  }) {
    return repository.getStockEntries(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      stockEntryType: stockEntryType,
      project: project,
    );
  }
}
