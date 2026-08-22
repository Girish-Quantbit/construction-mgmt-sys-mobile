import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/error/failures.dart';
import '../../domain/entities/task_progress.dart';
import '../../domain/entities/task_progress_detail.dart';
import '../../domain/repositories/task_progress_repository.dart';
import '../datasources/task_progress_remote_data_source.dart';

class TaskProgressRepositoryImpl implements TaskProgressRepository {
  final TaskProgressRemoteDataSource remoteDataSource;

  TaskProgressRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<TaskProgress>>> getTaskProgresses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? project,
  }) async {
    try {
      final List<dynamic> dataList = await remoteDataSource.getTaskProgresses(
        page: page,
        pageSize: pageSize,
        search: search,
        project: project,
      );

      final progressList = dataList.map((data) {
        String resolvedStatus = 'Draft';
        final docstatus = data['docstatus'];
        if (docstatus == 1 || docstatus == 1.0 || docstatus == '1') {
          resolvedStatus = 'Submitted';
        } else if (docstatus == 2 || docstatus == 2.0 || docstatus == '2') {
          resolvedStatus = 'Cancelled';
        }

        return TaskProgress(
          name: data['name'] ?? '',
          task: '',
          progress: 0.0,
          date: data['site_date'] != null
              ? DateTime.tryParse(data['site_date'])
              : null,
          project: data['project'] ?? '',
          status: resolvedStatus,
        );
      }).toList();

      return Right(progressList);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskProgress>> getTaskProgressDetails(
    String name,
  ) async {
    try {
      final Map<String, dynamic> data = await remoteDataSource.getTaskProgressDetails(name);

      String resolvedStatus = 'Draft';
      final docstatus = data['docstatus'];
      if (docstatus == 1 || docstatus == 1.0 || docstatus == '1') {
        resolvedStatus = 'Submitted';
      } else if (docstatus == 2 || docstatus == 2.0 || docstatus == '2') {
        resolvedStatus = 'Cancelled';
      }

      final List<dynamic> detailsData = data['task_progress_details'] ?? [];
      final details = detailsData
          .map((detail) => TaskProgressDetail.fromJson(detail))
          .toList();

      return Right(
        TaskProgress(
          name: data['name'] ?? '',
          task: '',
          progress: 0.0,
          date: data['site_date'] != null
              ? DateTime.tryParse(data['site_date'])
              : null,
          description: data['remarks'],
          project: data['project'] ?? '',
          status: resolvedStatus,
          taskProgressDetails: details,
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
    String? progressName,
  ) async {
    try {
      final data = await remoteDataSource.loadDocument(progressName);
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
  Future<Either<Failure, void>> uploadFile({
    required String serverName,
    required String filePath,
  }) async {
    try {
      await remoteDataSource.uploadFile(
        serverName: serverName,
        filePath: filePath,
      );
      return const Right(null);
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
