import '../repositories/stock_entry_repository.dart';

class GetStockEntryBaseUrl {
  final StockEntryRepository repository;

  GetStockEntryBaseUrl(this.repository);

  String call() => repository.getBaseUrl();
}
