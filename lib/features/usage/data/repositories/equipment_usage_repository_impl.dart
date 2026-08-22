import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/error/failures.dart';
import 'package:cms/core/services/project_selection_service.dart';
import '../../domain/entities/equipment_usage.dart';
import '../../domain/entities/equipment_usage_item.dart';
import '../../domain/repositories/equipment_usage_repository.dart';
import '../datasources/equipment_usage_remote_data_source.dart';

class EquipmentUsageRepositoryImpl implements EquipmentUsageRepository {
  final EquipmentUsageRemoteDataSource remoteDataSource;
  final ProjectSelectionService projectSelectionService;

  EquipmentUsageRepositoryImpl({
    required this.remoteDataSource,
    required this.projectSelectionService,
  });

  @override
  Future<Either<Failure, List<EquipmentUsage>>> getEquipmentUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? project,
  }) async {
    try {
      final activeProject = project ?? projectSelectionService.selectedProject;
      final dataList = await remoteDataSource.getEquipmentUsages(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
        project: activeProject,
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
      final Map<String, dynamic> data = await remoteDataSource.getEquipmentUsageDetails(name);

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
          openingReading: (item['opening_reading'] as num?)?.toDouble(),
          closingReading: (item['closing_reading'] as num?)?.toDouble(),
          dieselFilledInLtr: (item['diesel_filledin_ltr'] as num?)?.toDouble(),
          billed: (item['billed'] as num?) == 1,
          paid: (item['paid'] as num?) == 1,
          workingHrs: (item['working_hrs'] as num?)?.toDouble(),
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

  @override
  Future<Either<Failure, DocTypeMeta>> getMeta() async {
    try {
      final meta = await remoteDataSource.getMeta();
      return Right(meta);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> loadDocument(
    String? usageName,
  ) async {
    try {
      final doc = await remoteDataSource.loadDocument(usageName);
      return Right(doc);
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
