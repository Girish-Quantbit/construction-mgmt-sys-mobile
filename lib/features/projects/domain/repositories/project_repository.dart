import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/project.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<Project>>> getProjects();
  Future<Either<Failure, Project>> getProjectDetails(String name);
}
