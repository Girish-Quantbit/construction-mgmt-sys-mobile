import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/stock_entry_repository.dart';

class SaveStockEntryDocument {
  final StockEntryRepository repository;

  SaveStockEntryDocument(this.repository);

  /// Creates a new or updates an existing Stock Entry. Returns the saved name.
  Future<Either<Failure, String>> call({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  }) {
    return repository.saveDocument(
      existingServerId: existingServerId,
      payload: payload,
    );
  }
}
