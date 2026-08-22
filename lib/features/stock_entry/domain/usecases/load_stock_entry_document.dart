import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/stock_entry_repository.dart';

class LoadStockEntryDocument {
  final StockEntryRepository repository;

  LoadStockEntryDocument(this.repository);

  /// Returns the document data map for editing, or null when creating a new entry.
  Future<Either<Failure, Map<String, dynamic>?>> call(String? entryName) {
    return repository.loadDocument(entryName);
  }
}
