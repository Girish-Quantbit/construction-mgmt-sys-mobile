import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/project_selection_service.dart';
import '../../domain/entities/site_diary.dart';
import '../../domain/repositories/site_diary_repository.dart';
import '../datasources/site_diary_remote_data_source.dart';
import '../models/site_diary_model.dart';

class SiteDiaryRepositoryImpl implements SiteDiaryRepository {
  final SiteDiaryRemoteDataSource remoteDataSource;
  final ProjectSelectionService projectSelectionService;

  SiteDiaryRepositoryImpl({
    required this.remoteDataSource,
    required this.projectSelectionService,
  });

  @override
  Future<Either<Failure, List<SiteDiary>>> getSiteDiaries({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  }) async {
    try {
      final List<List<dynamic>> filters = [];
      if (status != null && status.isNotEmpty) {
        filters.add(['Site Diary', 'status', '=', status]);
      }
      if (search != null && search.isNotEmpty) {
        filters.add(['Site Diary', 'name', 'like', '%$search%']);
      }
      
      final activeProject = (project != null && project.isNotEmpty)
          ? project
          : projectSelectionService.selectedProject;
      if (activeProject != null && activeProject.isNotEmpty) {
        filters.add(['Site Diary', 'project', '=', activeProject]);
      }

      final List<dynamic> dataList = await remoteDataSource.getSiteDiaries(
        filters: filters,
        limitStart: (page - 1) * pageSize,
        limitPageLength: pageSize,
      );

      final diaries = dataList.map((data) => SiteDiaryModel.fromJson(data)).toList();
      return Right(diaries);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SiteDiary>> getSiteDiaryDetails(String name) async {
    try {
      final Map<String, dynamic> data = await remoteDataSource.getSiteDiaryDetails(name);
      return Right(SiteDiaryModel.fromJson(data));
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DocTypeMeta>> getMeta() async {
    try {
      final meta = await remoteDataSource.getMeta();
      return Right(meta);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Document>> loadDocument(String? name, String? project) async {
    try {
      final doc = await remoteDataSource.loadDocument(name, project);
      return Right(doc);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> callApiMethod(String method, Map<String, dynamic> args) async {
    try {
      final result = await remoteDataSource.callApiMethod(method, args);
      return Right(result);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> uploadFile({
    required String filePath,
    required String docName,
    required String doctype,
    required String docfield,
  }) async {
    try {
      final result = await remoteDataSource.uploadFile(
        filePath: filePath,
        docName: docName,
        doctype: doctype,
        docfield: docfield,
      );
      return Right(result);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> saveDocument({
    required String? name,
    required Map<String, dynamic> payload,
    required Document? existingDocument,
  }) async {
    try {
      final result = await remoteDataSource.saveDocument(
        name: name,
        payload: payload,
        existingDocument: existingDocument,
      );
      return Right(result);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getEmployeeName(String employeeId) async {
    try {
      final name = await remoteDataSource.getEmployeeName(employeeId);
      return Right(name);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  String getBaseUrl() => remoteDataSource.getBaseUrl();
}
