import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final FrappeSDK sdk;

  ProjectRepositoryImpl(this.sdk);

  @override
  Future<Either<Failure, List<Project>>> getProjects() async {
    try {
      final List<dynamic> dataList = await sdk.api.doctype.list(
        'Project',
        fields: [
          'name',
          'project_name',
          'status',
          'priority',
          'percent_complete',
          'expected_start_date',
          'expected_end_date',
        ],
        limitPageLength: 100,
      );

      final projects = dataList.map((data) {
        return Project(
          name: data['name'] ?? '',
          projectName: data['project_name'] ?? '',
          status: data['status'] ?? '',
          priority: data['priority'],
          progress: (data['percent_complete'] as num?)?.toDouble() ?? 0.0,
          expectedStartDate: data['expected_start_date'] != null
              ? DateTime.tryParse(data['expected_start_date'])
              : null,
          expectedEndDate: data['expected_end_date'] != null
              ? DateTime.tryParse(data['expected_end_date'])
              : null,
        );
      }).toList();

      return Right(projects);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Project>> getProjectDetails(String name) async {
    try {
      final Map<String, dynamic> data = await sdk.api.doctype.getByName(
        'Project',
        name,
      );

      return Right(
        Project(
          name: data['name'] ?? '',
          projectName: data['project_name'] ?? '',
          status: data['status'] ?? '',
          priority: data['priority'],
          progress: (data['percent_complete'] as num?)?.toDouble() ?? 0.0,
          description: data['notes'],
          expectedStartDate: data['expected_start_date'] != null
              ? DateTime.tryParse(data['expected_start_date'])
              : null,
          expectedEndDate: data['expected_end_date'] != null
              ? DateTime.tryParse(data['expected_end_date'])
              : null,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
