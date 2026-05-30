import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/entities/stock_entry_item.dart';
import '../../domain/repositories/stock_entry_repository.dart';

class StockEntryRepositoryImpl implements StockEntryRepository {
  final FrappeSDK sdk;

  StockEntryRepositoryImpl(this.sdk);

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
      final List<List<dynamic>> filters = [];
      if (status != null && status.isNotEmpty) {
        filters.add(['Stock Entry', 'status', '=', status]);
      }
      if (stockEntryType != null && stockEntryType.isNotEmpty) {
        filters.add(['Stock Entry', 'stock_entry_type', '=', stockEntryType]);
      }
      if (search != null && search.isNotEmpty) {
        filters.add(['Stock Entry', 'name', 'like', '%$search%']);
      }
      if (project != null && project.isNotEmpty) {
        filters.add(['Stock Entry', 'project', '=', project]);
      }

      final List<dynamic> dataList = await sdk.api.doctype.list(
        'Stock Entry',
        fields: [
          'name',
          'stock_entry_type',
          'posting_date',
          'purpose',
          'docstatus',
          'from_warehouse',
          'to_warehouse',
        ],
        filters: filters,
        limitStart: (page - 1) * pageSize,
        limitPageLength: pageSize,
        orderBy: 'posting_date desc',
      );

      final entries = dataList.map((data) {
        String status = 'Draft';
        if (data['docstatus'] == 1) {
          status = 'Submitted';
        } else if (data['docstatus'] == 2) {
          status = 'Cancelled';
        }

        return StockEntry(
          name: data['name'] ?? '',
          stockEntryType: data['stock_entry_type'] ?? '',
          postingDate: data['posting_date'] != null
              ? DateTime.tryParse(data['posting_date'])
              : null,
          purpose: data['purpose'] ?? '',
          status: status,
          fromWarehouse: data['from_warehouse'],
          toWarehouse: data['to_warehouse'],
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
      final Map<String, dynamic> data = await sdk.api.doctype.getByName(
        'Stock Entry',
        name,
      );

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

      String status = 'Draft';
      if (data['docstatus'] == 1) {
        status = 'Submitted';
      } else if (data['docstatus'] == 2) {
        status = 'Cancelled';
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
          status: status,
          items: items,
          rawData: data,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
