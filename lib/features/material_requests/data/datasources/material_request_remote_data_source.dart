import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/services/api_handler.dart';

abstract class MaterialRequestRemoteDataSource {
  Future<List<dynamic>> getMaterialRequests({
    required List<List<dynamic>> filters,
    required int limitStart,
    required int limitPageLength,
  });

  Future<List<dynamic>> getMaterialRequestItems({
    required List<String> parentNames,
  });

  Future<Map<String, dynamic>> getMaterialRequestDetails(String name);

  Future<dynamic> downloadPDF({
    required String url,
    required Map<String, String> headers,
  });
}

class MaterialRequestRemoteDataSourceImpl implements MaterialRequestRemoteDataSource {
  final FrappeSDK sdk;

  MaterialRequestRemoteDataSourceImpl(this.sdk);

  @override
  Future<List<dynamic>> getMaterialRequests({
    required List<List<dynamic>> filters,
    required int limitStart,
    required int limitPageLength,
  }) async {
    return ApiHandler.call(() => sdk.api.doctype.list(
      'Material Request',
      fields: [
        'name',
        'title',
        'transaction_date',
        'material_request_type',
        'status',
        'schedule_date',
        'per_ordered',
        'per_received',
      ],
      filters: filters,
      limitStart: limitStart,
      limitPageLength: limitPageLength,
      orderBy: 'transaction_date desc',
    ));
  }

  @override
  Future<List<dynamic>> getMaterialRequestItems({
    required List<String> parentNames,
  }) async {
    return ApiHandler.call(() => sdk.api.doctype.list(
      'Material Request Item',
      fields: [
        'parent',
        'amount',
        'qty',
        'rate',
        'item_code',
        'item_name',
        'uom',
        'schedule_date',
        'warehouse',
      ],
      filters: [['parent', 'in', parentNames]],
      limitPageLength: 1000,
    ));
  }

  @override
  Future<Map<String, dynamic>> getMaterialRequestDetails(String name) async {
    return ApiHandler.call(() => sdk.api.doctype.getByName(
      'Material Request',
      name,
    ));
  }

  @override
  Future<dynamic> downloadPDF({
    required String url,
    required Map<String, String> headers,
  }) async {
    return ApiHandler.call(() => sdk.api.rest.client.get(
      Uri.parse(url),
      headers: headers,
    ));
  }
}
