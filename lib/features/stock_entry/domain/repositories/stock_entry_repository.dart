import 'dart:typed_data';
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

  /// Returns the raw data map for an existing entry, or null for a new entry.
  Future<Either<Failure, Map<String, dynamic>?>> loadDocument(String? entryName);

  /// Creates or updates a Stock Entry. Returns the saved document name.
  Future<Either<Failure, String>> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  });

  String getBaseUrl();

  Future<Either<Failure, Uint8List>> downloadPdf(String entryName);
}
