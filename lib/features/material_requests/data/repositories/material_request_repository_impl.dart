import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/material_request.dart';
import '../../domain/repositories/material_request_repository.dart';
import '../datasources/material_request_remote_data_source.dart';
import '../models/material_request_model.dart';
import 'package:cms/core/services/project_selection_service.dart';

class MaterialRequestRepositoryImpl implements MaterialRequestRepository {
  final MaterialRequestRemoteDataSource remoteDataSource;
  final ProjectSelectionService projectSelectionService;
  final FrappeSDK sdk; // Kept for helper values like sdk.baseUrl and sdk.api.requestHeaders

  MaterialRequestRepositoryImpl({
    required this.remoteDataSource,
    required this.projectSelectionService,
    required this.sdk,
  });

  @override
  Future<Either<Failure, List<MaterialRequest>>> getMaterialRequests({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
    String? materialRequestType,
    DateTimeRange? requiredByDateRange,
    DateTimeRange? transactionDateRange,
  }) async {
    try {
      final List<List<dynamic>> filters = [];
      if (status != null && status.isNotEmpty) {
        filters.add(['Material Request', 'status', '=', status]);
      }
      if (search != null && search.isNotEmpty) {
        filters.add(['Material Request', 'name', 'like', '%$search%']);
      }
      
      final activeProject = (project != null && project.isNotEmpty)
          ? project
          : projectSelectionService.selectedProject;
      if (activeProject != null && activeProject.isNotEmpty) {
        filters.add(['Material Request Item', 'project', '=', activeProject]);
      }
      if (materialRequestType != null && materialRequestType.isNotEmpty) {
        filters.add(['Material Request', 'material_request_type', '=', materialRequestType]);
      }
      if (requiredByDateRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(requiredByDateRange.start);
        final end = DateFormat('yyyy-MM-dd').format(requiredByDateRange.end);
        filters.add(['Material Request', 'schedule_date', '>=', start]);
        filters.add(['Material Request', 'schedule_date', '<=', end]);
      }
      if (transactionDateRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(transactionDateRange.start);
        final end = DateFormat('yyyy-MM-dd').format(transactionDateRange.end);
        filters.add(['Material Request', 'transaction_date', '>=', start]);
        filters.add(['Material Request', 'transaction_date', '<=', end]);
      }

      final List<dynamic> dataList = await remoteDataSource.getMaterialRequests(
        filters: filters,
        limitStart: (page - 1) * pageSize,
        limitPageLength: pageSize,
      );

      final requestsFuture = dataList.map((data) async {
        final name = data['name']?.toString() ?? '';
        if (name.isEmpty) {
          return MaterialRequestModel.fromJson(Map<String, dynamic>.from(data));
        }
        try {
          final Map<String, dynamic> fullData = await remoteDataSource.getMaterialRequestDetails(name);
          return MaterialRequestModel.fromJson(fullData);
        } catch (e) {
          debugPrint('Error fetching full details for $name: $e');
          return MaterialRequestModel.fromJson(Map<String, dynamic>.from(data));
        }
      }).toList();

      final List<MaterialRequest> requests = await Future.wait(requestsFuture);

      return Right(requests);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MaterialRequest>> getMaterialRequestDetails(
    String name,
  ) async {
    try {
      final Map<String, dynamic> data = await remoteDataSource.getMaterialRequestDetails(name);
      return Right(MaterialRequestModel.fromJson(data));
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
          '?doctype=Material%20Request'
          '&name=${Uri.encodeComponent(name)}'
          '&format=Standard'
          '&no_letterhead=0'
          '&letterhead=Company%20Letterhead%20-%20Grey'
          '&settings=%7B%7D'
          '&_lang=en'
          '&pdf_generator=wkhtmltopdf';

      final Map<String, String> headers = sdk.api.requestHeaders;

      final response = await remoteDataSource.downloadPDF(
        url: urlStr,
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
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
