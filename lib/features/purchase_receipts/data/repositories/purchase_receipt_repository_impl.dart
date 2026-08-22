import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase_receipt.dart';
import '../../domain/entities/purchase_receipt_item.dart';
import '../../domain/repositories/purchase_receipt_repository.dart';

import 'package:cms/core/services/project_selection_service.dart';
import 'package:cms/core/di/injection_container.dart';

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
    String? sortBy,
    String? sortOrder,
    DateTime? fromDate,
    DateTime? toDate,
    String? supplier,
  }) async {
    try {
      final List<List<dynamic>> filters = [];
      if (status != null && status.isNotEmpty) {
        filters.add(['Purchase Receipt', 'status', '=', status]);
      }
      if (search != null && search.isNotEmpty) {
        filters.add(['Purchase Receipt', 'name', 'like', '%$search%']);
      }
      
      final activeProject = (project != null && project.isNotEmpty)
          ? project
          : sl<ProjectSelectionService>().selectedProject;
      if (activeProject != null && activeProject.isNotEmpty) {
        filters.add(['Purchase Receipt', 'project', '=', activeProject]);
      }

      final activeSite = sl<ProjectSelectionService>().selectedSite;
      if (activeSite != null && activeSite.isNotEmpty) {
        filters.add(['Purchase Receipt', 'site', '=', activeSite]);
      }

      if (supplier != null && supplier.isNotEmpty) {
        filters.add(['Purchase Receipt', 'supplier', 'like', '%$supplier%']);
      }
      if (fromDate != null) {
        final fromStr = "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
        filters.add(['Purchase Receipt', 'posting_date', '>=', fromStr]);
      }
      if (toDate != null) {
        final toStr = "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";
        filters.add(['Purchase Receipt', 'posting_date', '<=', toStr]);
      }

      final sortField = sortBy ?? 'posting_date';
      final order = sortOrder ?? 'desc';

      final List<dynamic> dataList = await sdk.api.doctype.list(
        'Purchase Receipt',
        fields: ['name', 'supplier', 'supplier_name', 'total_qty', 'posting_date', 'grand_total', 'status'],
        filters: filters,
        limitStart: (page - 1) * pageSize,
        limitPageLength: pageSize,
        orderBy: '$sortField $order',
      );

      final receipts = dataList.map((data) {
        return PurchaseReceipt(
          name: data['name'] ?? '',
          supplier: data['supplier'] ?? '',
          supplierName: data['supplier_name'] ?? '',
          totalQty: (data['total_qty'] as num?)?.toDouble(),
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
          supplierName: data['supplier_name'] ?? '',
          totalQty: (data['total_qty'] as num?)?.toDouble(),
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

  @override
  Future<Either<Failure, String>> downloadPDF(String name) async {
    try {
      final String baseUrl = sdk.baseUrl.endsWith('/')
          ? sdk.baseUrl.substring(0, sdk.baseUrl.length - 1)
          : sdk.baseUrl;

      final String urlStr =
          '$baseUrl/api/method/frappe.utils.print_format.download_pdf'
          '?doctype=Purchase%20Receipt'
          '&name=${Uri.encodeComponent(name)}'
          '&format=Standard'
          '&no_letterhead=0'
          '&letterhead=Company%20Letterhead%20-%20Grey'
          '&settings=%7B%7D'
          '&_lang=en'
          '&pdf_generator=wkhtmltopdf';

      final Map<String, String> headers = sdk.api.requestHeaders;

      final response = await sdk.api.rest.client.get(
        Uri.parse(urlStr),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final String sanitizedName = name.replaceAll(
          RegExp(r'[/\\]'),
          '_',
        );
        final file = File('${tempDir.path}/$sanitizedName.pdf');
        await file.writeAsBytes(response.bodyBytes);
        return Right(file.path);
      } else {
        return Left(ServerFailure('Server returned status code: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
