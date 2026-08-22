import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/services/api_handler.dart';

abstract class TaskRemoteDataSource {
  Future<List<dynamic>> getTasks({required List<List<dynamic>> filters});
  Future<Map<String, dynamic>> updateTaskStatus(String name, String status);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FrappeSDK sdk;

  TaskRemoteDataSourceImpl(this.sdk);

  @override
  Future<List<dynamic>> getTasks({required List<List<dynamic>> filters}) async {
    return ApiHandler.call(() => sdk.api.doctype.list(
      'Task',
      filters: filters,
      fields: [
        'name',
        'subject',
        'status',
        'project',
        'description',
        'exp_end_date',
        'progress',
        'priority',
        'task_weight',
        'parent_task',
        'is_group',
      ],
    ));
  }

  @override
  Future<Map<String, dynamic>> updateTaskStatus(String name, String status) async {
    return ApiHandler.call(() => sdk.api.document.updateDocument(
      'Task',
      name,
      {'status': status},
    ));
  }
}
