import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/project_selection_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final ProjectSelectionService projectSelectionService;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.projectSelectionService,
  });

  @override
  Future<Either<Failure, List<ProjectTask>>> getTasks({String? project}) async {
    try {
      final List<List<dynamic>> filters = [];
      
      final activeProject = (project != null && project.isNotEmpty)
          ? project
          : projectSelectionService.selectedProject;
      if (activeProject != null && activeProject.isNotEmpty) {
        filters.add(['Task', 'project', '=', activeProject]);
      }

      final List<dynamic> dataList = await remoteDataSource.getTasks(filters: filters);
      final tasks = dataList.map((data) => TaskModel.fromJson(data)).toList();
      return Right(tasks);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProjectTask>> updateTaskStatus(
    String name,
    String status,
  ) async {
    try {
      final Map<String, dynamic> data = await remoteDataSource.updateTaskStatus(name, status);
      return Right(TaskModel.fromJson(data));
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
