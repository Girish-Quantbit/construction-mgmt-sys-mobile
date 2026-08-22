import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/services/api_handler.dart';

abstract class ProjectRemoteDataSource {
  Future<List<dynamic>> getProjects();
  Future<Map<String, dynamic>> getProjectDetails(String name);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final FrappeSDK sdk;

  ProjectRemoteDataSourceImpl(this.sdk);

  @override
  Future<List<dynamic>> getProjects() async {
    return ApiHandler.call(() => sdk.api.doctype.list(
      'Project',
      fields: [
        'name',
        'project_name',
        'status',
        'priority',
        'project_type',
        'percent_complete',
        'expected_start_date',
        'expected_end_date',
        'custom_site',
        'is_active',
        'per_gross_margin',
        'department',
      ],
      limitPageLength: 100,
    ));
  }

  @override
  Future<Map<String, dynamic>> getProjectDetails(String name) async {
    return ApiHandler.call(() => sdk.api.doctype.getByName(
      'Project',
      name,
    ));
  }
}
