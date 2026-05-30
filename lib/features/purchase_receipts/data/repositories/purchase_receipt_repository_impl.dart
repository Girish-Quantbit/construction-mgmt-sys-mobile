import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase_receipt.dart';
import '../../domain/entities/purchase_receipt_item.dart';
import '../../domain/repositories/purchase_receipt_repository.dart';

class PurchaseReceiptRepositoryImpl implements PurchaseReceiptRepository {
  final FrappeSDK sdk;

  PurchaseReceiptRepositoryImpl(this.sdk);

  @override
  Future<Either<Failure, List<PurchaseReceipt>>> getPurchaseReceipts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  }) async {
    try {
      final List<List<dynamic>> filters = [];
      if (status != null && status.isNotEmpty) {
        filters.add(['Purchase Receipt', 'status', '=', status]);
      }
      if (search != null && search.isNotEmpty) {
        filters.add(['Purchase Receipt', 'name', 'like', '%$search%']);
      }
      if (project != null && project.isNotEmpty) {
        filters.add(['Purchase Receipt', 'project', '=', project]);
      }

      final List<dynamic> dataList = await sdk.api.doctype.list(
        'Purchase Receipt',
        fields: ['name', 'supplier', 'posting_date', 'grand_total', 'status'],
        filters: filters,
        limitStart: (page - 1) * pageSize,
        limitPageLength: pageSize,
        orderBy: 'posting_date desc',
      );

      final receipts = dataList.map((data) {
        return PurchaseReceipt(
          name: data['name'] ?? '',
          supplier: data['supplier'] ?? '',
          postingDate: data['posting_date'] != null
              ? DateTime.tryParse(data['posting_date'])
              : null,
          grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0.0,
          status: data['status'] ?? '',
        );
      }).toList();

      return Right(receipts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseReceipt>> getPurchaseReceiptDetails(
    String name,
  ) async {
    try {
      final Map<String, dynamic> data = await sdk.api.doctype.getByName(
        'Purchase Receipt',
        name,
      );

      final List<dynamic> itemsData = data['items'] ?? [];
      final items = itemsData.map((item) {
        return PurchaseReceiptItem(
          itemName: item['item_name'] ?? '',
          itemCode: item['item_code'] ?? '',
          qty: (item['qty'] as num?)?.toDouble() ?? 0.0,
          rate: (item['rate'] as num?)?.toDouble() ?? 0.0,
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      return Right(
        PurchaseReceipt(
          name: data['name'] ?? '',
          supplier: data['supplier'] ?? '',
          postingDate: data['posting_date'] != null
              ? DateTime.tryParse(data['posting_date'])
              : null,
          grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0.0,
          status: data['status'] ?? '',
          supplierAddress: data['supplier_address'],
          contactPerson: data['contact_person'],
          items: items,
          taxesAndCharges:
              (data['total_taxes_and_charges'] as num?)?.toDouble() ?? 0.0,
          baseGrandTotal: (data['base_grand_total'] as num?)?.toDouble() ?? 0.0,
          rawData: data,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
