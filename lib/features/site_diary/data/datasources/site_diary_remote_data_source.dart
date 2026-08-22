import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:http/http.dart' show MultipartRequest, MultipartFile, Response;
import 'dart:convert' show jsonDecode;
import '../../../../core/error/failures.dart';
import '../../../../core/services/api_handler.dart';

abstract class SiteDiaryRemoteDataSource {
  Future<List<dynamic>> getSiteDiaries({
    required List<List<dynamic>> filters,
    required int limitStart,
    required int limitPageLength,
  });

  Future<Map<String, dynamic>> getSiteDiaryDetails(String name);

  Future<DocTypeMeta> getMeta();

  Future<Document> loadDocument(String? name, String? project);

  Future<dynamic> callApiMethod(String method, Map<String, dynamic> args);

  Future<String?> uploadFile({
    required String filePath,
    required String docName,
    required String doctype,
    required String docfield,
  });

  Future<dynamic> saveDocument({
    required String? name,
    required Map<String, dynamic> payload,
    required Document? existingDocument,
  });

  Future<String> getEmployeeName(String employeeId);

  String getBaseUrl();
}

class SiteDiaryRemoteDataSourceImpl implements SiteDiaryRemoteDataSource {
  final FrappeSDK sdk;

  SiteDiaryRemoteDataSourceImpl(this.sdk);

  @override
  Future<List<dynamic>> getSiteDiaries({
    required List<List<dynamic>> filters,
    required int limitStart,
    required int limitPageLength,
  }) async {
    return ApiHandler.call(() => sdk.api.doctype.list(
      'Site Diary',
      fields: [
        'name',
        'site_date',
        'status',
        'project',
        'weather_am',
        'weather_pm',
      ],
      filters: filters,
      limitStart: limitStart,
      limitPageLength: limitPageLength,
      orderBy: 'site_date desc',
    ));
  }

  @override
  Future<Map<String, dynamic>> getSiteDiaryDetails(String name) async {
    return ApiHandler.call(() => sdk.api.doctype.getByName(
      'Site Diary',
      name,
    ));
  }

  @override
  Future<DocTypeMeta> getMeta() async {
    return ApiHandler.call(() => sdk.meta.getMeta('Site Diary', forceRefresh: true));
  }

  @override
  Future<Document> loadDocument(String? name, String? project) async {
    if (name != null) {
      try {
        final serverData = await ApiHandler.call(() => sdk.api.doctype.getByName(
          'Site Diary',
          name,
        ));
        return await sdk.repository.saveServerDocument(
          doctype: 'Site Diary',
          serverId: name,
          data: serverData,
        );
      } catch (_) {
        final localDoc = await sdk.repository.getDocumentByServerId(
          name,
          'Site Diary',
        );
        if (localDoc == null) {
          throw Exception('Document not found locally or on server');
        }
        return localDoc;
      }
    } else {
      return await sdk.repository.createDocument(
        doctype: 'Site Diary',
        data: {'project': project},
      );
    }
  }

  @override
  Future<dynamic> callApiMethod(String method, Map<String, dynamic> args) async {
    return ApiHandler.call(() => sdk.api.call(method, args: args));
  }

  @override
  Future<String> getEmployeeName(String employeeId) async {
    final data = await ApiHandler.call(
      () => sdk.api.doctype.getByName('Employee', employeeId),
    );
    return data['employee_name']?.toString() ?? employeeId;
  }

  @override
  String getBaseUrl() {
    final url = sdk.baseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  @override
  Future<String?> uploadFile({
    required String filePath,
    required String docName,
    required String doctype,
    required String docfield,
  }) async {
    // We import http and convert to MultipartRequest
    final String baseUrl = sdk.baseUrl.endsWith('/')
        ? sdk.baseUrl.substring(0, sdk.baseUrl.length - 1)
        : sdk.baseUrl;
    final String uploadUrl = '$baseUrl/api/method/upload_file';
    
    // We use a custom call to ensure we wrap HTTP library exceptions
    try {
      final request = MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers.addAll(sdk.api.requestHeaders);
      request.fields['doctype'] = doctype;
      request.fields['docname'] = docName;
      request.fields['docfield'] = docfield;
      request.fields['is_private'] = '0';
      final fileName = filePath.split('/').last;
      request.files.add(
        await MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
        ),
      );
      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['message']?['file_url']?.toString();
      } else {
        throw Exception('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      throw ServerException('File upload failed: $e');
    }
  }

  @override
  Future<dynamic> saveDocument({
    required String? name,
    required Map<String, dynamic> payload,
    required Document? existingDocument,
  }) async {
    if (name == null) {
      final result = await ApiHandler.call(() => sdk.api.document.createDocument(
        'Site Diary',
        payload,
      ));
      final serverName = result['name']?.toString() ?? result['docname']?.toString();
      if (serverName != null) {
        final merged = Map<String, dynamic>.from(payload)..['name'] = serverName;
        try {
          await ApiHandler.call(() => sdk.api.document.submitDocument(
            'Site Diary',
            serverName,
          ));
          merged['docstatus'] = 1;
        } catch (e) {
          merged['docstatus'] = 0;
          await sdk.repository.saveServerDocument(
            doctype: 'Site Diary',
            serverId: serverName,
            data: merged,
          );
          rethrow;
        }
        await sdk.repository.saveServerDocument(
          doctype: 'Site Diary',
          serverId: serverName,
          data: merged,
        );
      }
      return result;
    } else {
      final existingData = Map<String, dynamic>.from(existingDocument?.data ?? {})..addAll(payload);
      final result = await ApiHandler.call(() => sdk.api.document.updateDocument(
        'Site Diary',
        name,
        existingData,
      ));
      final docstatus = int.tryParse(existingData['docstatus']?.toString() ?? '0') ?? 0;
      if (docstatus == 0) {
        try {
          await ApiHandler.call(() => sdk.api.document.submitDocument(
            'Site Diary',
            name,
          ));
          existingData['docstatus'] = 1;
        } catch (e) {
          existingData['docstatus'] = 0;
          if (existingDocument != null) {
            await sdk.repository.updateDocumentData(
              existingDocument.localId,
              existingData,
            );
          }
          rethrow;
        }
      }
      if (existingDocument != null) {
        await sdk.repository.updateDocumentData(
          existingDocument.localId,
          existingData,
        );
      }
      return result;
    }
  }
}
