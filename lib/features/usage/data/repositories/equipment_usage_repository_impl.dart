import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/equipment_usage.dart';
import '../../domain/entities/equipment_usage_item.dart';
import '../../domain/repositories/equipment_usage_repository.dart';

class EquipmentUsageRepositoryImpl implements EquipmentUsageRepository {
  final FrappeSDK sdk;

  EquipmentUsageRepositoryImpl(this.sdk);

  @override
  Future<Either<Failure, List<EquipmentUsage>>> getEquipmentUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    try {
      final List<List<dynamic>> filters = [];
      if (search != null && search.isNotEmpty) {
        filters.add(['Equipment Usage', 'name', 'like', '%$search%']);
      }

      final List<dynamic> dataList = await sdk.api.doctype.list(
        'Equipment Usage',
        fields: ['name', 'project', 'site_date', 'docstatus'],
        filters: filters,
        limitStart: (page - 1) * pageSize,
        limitPageLength: pageSize,
        orderBy: 'site_date desc',
      );

      final usages = dataList.map((data) {
        String resolvedStatus = 'Draft';
        final docstatus = data['docstatus'];
        if (docstatus == 1 || docstatus == 1.0 || docstatus == '1') {
          resolvedStatus = 'Submitted';
        } else if (docstatus == 2 || docstatus == 2.0 || docstatus == '2') {
          resolvedStatus = 'Cancelled';
        } else if (data['status'] != null) {
          resolvedStatus = data['status'].toString();
        }

        return EquipmentUsage(
          name: data['name'] ?? '',
          project: data['project'] ?? '',
          siteDate: data['site_date'] != null
              ? DateTime.tryParse(data['site_date'])
              : null,
          status: resolvedStatus,
        );
      }).toList();

      return Right(usages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EquipmentUsage>> getEquipmentUsageDetails(
    String name,
  ) async {
    try {
      final Map<String, dynamic> data = await sdk.api.doctype.getByName(
        'Equipment Usage',
        name,
      );

      final List<dynamic> itemsData = data['equipment_usage_details'] ?? [];
      final items = itemsData.map((item) {
        return EquipmentUsageItem(
          task: item['task'] ?? '',
          subtask: item['subtask'] ?? '',
          quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
          rate: (item['rate'] as num?)?.toDouble() ?? 0.0,
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
          equipmentItem: item['equipment_item'] ?? '',
          contractor: item['contractor'] ?? '',
          uom: item['uom'] ?? '',
        );
      }).toList();

      String resolvedStatus = 'Draft';
      final docstatus = data['docstatus'];
      if (docstatus == 1 || docstatus == 1.0 || docstatus == '1') {
        resolvedStatus = 'Submitted';
      } else if (docstatus == 2 || docstatus == 2.0 || docstatus == '2') {
        resolvedStatus = 'Cancelled';
      } else if (data['status'] != null) {
        resolvedStatus = data['status'].toString();
      }

      return Right(
        EquipmentUsage(
          name: data['name'] ?? '',
          project: data['project'] ?? '',
          siteDate: data['site_date'] != null
              ? DateTime.tryParse(data['site_date'])
              : null,
          status: resolvedStatus,
          equipmentUsageDetails: items,
          rawData: data,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
