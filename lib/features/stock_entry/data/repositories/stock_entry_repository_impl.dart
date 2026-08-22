import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/entities/stock_entry_item.dart';
import '../../domain/repositories/stock_entry_repository.dart';
import '../datasources/stock_entry_remote_data_source.dart';

class StockEntryRepositoryImpl implements StockEntryRepository {
  final StockEntryRemoteDataSource remoteDataSource;

  StockEntryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<StockEntry>>> getStockEntries({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? stockEntryType,
    String? project,
  }) async {
    try {
      final dataList = await remoteDataSource.getStockEntries(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        stockEntryType: stockEntryType,
        project: project,
      );

      final entries = dataList.map((data) {
        String entryStatus = 'Draft';
        if (data['docstatus'] == 1) {
          entryStatus = 'Submitted';
        } else if (data['docstatus'] == 2) {
          entryStatus = 'Cancelled';
        }
        return StockEntry(
          name: data['name'] ?? '',
          stockEntryType: data['stock_entry_type'] ?? '',
          postingDate: data['posting_date'] != null
              ? DateTime.tryParse(data['posting_date'])
              : null,
          purpose: data['purpose'] ?? '',
          status: entryStatus,
          fromWarehouse: data['from_warehouse'],
          toWarehouse: data['to_warehouse'],
          totalIncomingValue:
              (data['total_incoming_value'] as num?)?.toDouble() ?? 0.0,
          totalOutgoingValue:
              (data['total_outgoing_value'] as num?)?.toDouble() ?? 0.0,
          rawData: Map<String, dynamic>.from(data is Map ? data : {}),
        );
      }).toList();

      return Right(entries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockEntry>> getStockEntryDetails(String name) async {
    try {
      final data = await remoteDataSource.getStockEntryDetails(name);

      final List<dynamic> itemsData = data['items'] ?? [];
      final items = itemsData.map((item) {
        return StockEntryItem(
          itemCode: item['item_code'] ?? '',
          itemName: item['item_name'] ?? '',
          qty: (item['qty'] as num?)?.toDouble() ?? 0.0,
          uom: item['uom'] ?? '',
          sWarehouse: item['s_warehouse'],
          tWarehouse: item['t_warehouse'],
          basicRate: (item['basic_rate'] as num?)?.toDouble() ?? 0.0,
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      String entryStatus = 'Draft';
      if (data['docstatus'] == 1) {
        entryStatus = 'Submitted';
      } else if (data['docstatus'] == 2) {
        entryStatus = 'Cancelled';
      }

      return Right(
        StockEntry(
          name: data['name'] ?? '',
          stockEntryType: data['stock_entry_type'] ?? '',
          postingDate: data['posting_date'] != null
              ? DateTime.tryParse(data['posting_date'])
              : null,
          purpose: data['purpose'] ?? '',
          fromWarehouse: data['from_warehouse'],
          toWarehouse: data['to_warehouse'],
          totalIncomingValue:
              (data['total_incoming_value'] as num?)?.toDouble() ?? 0.0,
          totalOutgoingValue:
              (data['total_outgoing_value'] as num?)?.toDouble() ?? 0.0,
          status: entryStatus,
          items: items,
          rawData: data,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> loadDocument(
    String? entryName,
  ) async {
    try {
      final data = await remoteDataSource.loadDocument(entryName);
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final name = await remoteDataSource.saveDocument(
        existingServerId: existingServerId,
        payload: payload,
      );
      return Right(name);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  String getBaseUrl() => remoteDataSource.getBaseUrl();

  @override
  Future<Either<Failure, Uint8List>> downloadPdf(String entryName) async {
    try {
      final bytes = await remoteDataSource.downloadPdf(entryName);
      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
