import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/material_request.dart';
import '../../domain/entities/material_request_item.dart';
import '../../domain/repositories/material_request_repository.dart';

class MaterialRequestRepositoryImpl implements MaterialRequestRepository {
  final FrappeSDK sdk;

  MaterialRequestRepositoryImpl(this.sdk);

  @override
  Future<Either<Failure, List<MaterialRequest>>> getMaterialRequests({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  }) async {
    try {
      final List<List<dynamic>> filters = [];
      if (status != null && status.isNotEmpty) {
        filters.add(['Material Request', 'status', '=', status]);
      }
      if (search != null && search.isNotEmpty) {
        filters.add(['Material Request', 'name', 'like', '%$search%']);
      }
      if (project != null && project.isNotEmpty) {
        filters.add(['Material Request Item', 'project', '=', project]);
      }

      final List<dynamic> dataList = await sdk.api.doctype.list(
        'Material Request',
        fields: ['name', 'title', 'transaction_date', 'material_request_type', 'status'],
        filters: filters,
        limitStart: (page - 1) * pageSize,
        limitPageLength: pageSize,
        orderBy: 'transaction_date desc',
      );

      final requests = dataList.map((data) {
        return MaterialRequest(
          name: data['name'] ?? '',
          title: data['title'] ?? data['name'] ?? '',
          transactionDate: data['transaction_date'] != null
              ? DateTime.tryParse(data['transaction_date'])
              : null,
          materialRequestType: data['material_request_type'] ?? '',
          status: data['status'] ?? '',
        );
      }).toList();

      return Right(requests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MaterialRequest>> getMaterialRequestDetails(
    String name,
  ) async {
    try {
      final Map<String, dynamic> data = await sdk.api.doctype.getByName(
        'Material Request',
        name,
      );

      final List<dynamic> itemsData = data['items'] ?? [];
      final items = itemsData.map((item) {
        return MaterialRequestItem(
          itemName: item['item_name'] ?? '',
          itemCode: item['item_code'] ?? '',
          qty: (item['qty'] as num?)?.toDouble() ?? 0.0,
          uom: item['uom'],
          requiredByDate: item['required_by_date'] != null
              ? DateTime.tryParse(item['required_by_date'])
              : null,
          scheduleDate: item['schedule_date'] != null
              ? DateTime.tryParse(item['schedule_date'])
              : null,
          warehouse: item['warehouse'],
        );
      }).toList();

      return Right(
        MaterialRequest(
          name: data['name'] ?? '',
          title: data['title'] ?? data['name'] ?? '',
          transactionDate: data['transaction_date'] != null
              ? DateTime.tryParse(data['transaction_date'])
              : null,
          materialRequestType: data['material_request_type'] ?? '',
          status: data['status'] ?? '',
          items: items,
          scheduleDate: data['schedule_date'] != null
              ? DateTime.tryParse(data['schedule_date'])
              : null,
          buyingPriceList: data['buying_price_list'],
          setWarehouse: data['set_warehouse'],
          perOrdered: (data['per_ordered'] as num?)?.toDouble(),
          perReceived: (data['per_received'] as num?)?.toDouble(),
          rawData: data,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
