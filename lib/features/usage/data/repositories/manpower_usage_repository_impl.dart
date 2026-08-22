import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/error/failures.dart';
import 'package:cms/core/services/project_selection_service.dart';
import '../../domain/entities/manpower_usage.dart';
import '../../domain/entities/manpower_usage_item.dart';
import '../../domain/repositories/manpower_usage_repository.dart';
import '../datasources/manpower_usage_remote_data_source.dart';

class ManpowerUsageRepositoryImpl implements ManpowerUsageRepository {
  final ManpowerUsageRemoteDataSource remoteDataSource;
  final ProjectSelectionService projectSelectionService;

  ManpowerUsageRepositoryImpl({
    required this.remoteDataSource,
    required this.projectSelectionService,
  });

  @override
  Future<Either<Failure, List<ManpowerUsage>>> getManpowerUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  }) async {
    try {
      final activeProject = project ?? projectSelectionService.selectedProject;
      final dataList = await remoteDataSource.getManpowerUsages(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
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

        return ManpowerUsage(
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
  Future<Either<Failure, ManpowerUsage>> getManpowerUsageDetails(
    String name,
  ) async {
    try {
      final Map<String, dynamic> data = await remoteDataSource.getManpowerUsageDetails(name);

      final List<dynamic> manpowerUsageData = data['manpower_usage'] ?? [];
      final manpowerUsage = manpowerUsageData.map((item) {
        return ManpowerUsageItem(
          task: item['task'] ?? '',
          subtask: item['subtask'] ?? '',
          quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
          rate: (item['rate'] as num?)?.toDouble() ?? 0.0,
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
          equipmentItem: item['equipment_item'] ?? '',
          contractor: item['contractor'] ?? '',
          uom: item['uom'] ?? '',
          skillType: item['skill_type'] ?? '',
          timeIn: item['time_in'],
          timeOut: item['time_out'],
          presenty: (item['presenty'] as num?)?.toDouble(),
          hours: (item['hours'] as num?)?.toDouble(),
          totalPresenty: (item['total_presenty'] as num?)?.toDouble(),
          billed: (item['amountbilled'] as num?) == 1,
          paid: (item['paid'] as num?) == 1,
          itemName: item['item_name'] ?? item['equipment_item_name'] ?? '',
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
        ManpowerUsage(
          name: data['name'] ?? '',
          project: data['project'] ?? '',
          siteDate: data['site_date'] != null
              ? DateTime.tryParse(data['site_date'])
              : null,
          status: resolvedStatus,
          manpowerUsage: manpowerUsage,
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
