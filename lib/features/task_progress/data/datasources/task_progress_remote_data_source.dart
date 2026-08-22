import 'dart:io';
import 'dart:typed_data';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/services/project_selection_service.dart';
import 'package:http/http.dart' as http;

abstract class TaskProgressRemoteDataSource {
  Future<List<dynamic>> getTaskProgresses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? project,
  });

  Future<Map<String, dynamic>> getTaskProgressDetails(String name);

  Future<DocTypeMeta> getMeta();

  Future<Map<String, dynamic>?> loadDocument(String? progressName);

  Future<String> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  });

  Future<void> uploadFile({
    required String serverName,
    required String filePath,
  });

  String getBaseUrl();

  Future<Uint8List> downloadPdf(String entryName);
}

class TaskProgressRemoteDataSourceImpl implements TaskProgressRemoteDataSource {
  final FrappeSDK sdk;
  final ProjectSelectionService projectSelectionService;

  TaskProgressRemoteDataSourceImpl({
    required this.sdk,
    required this.projectSelectionService,
  });

  @override
  Future<List<dynamic>> getTaskProgresses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? project,
  }) async {
    final List<List<dynamic>> filters = [];
    if (search != null && search.isNotEmpty) {
      filters.add(['Task Progress', 'name', 'like', '%$search%']);
    }

    final activeProject = (project != null && project.isNotEmpty)
        ? project
        : projectSelectionService.selectedProject;
    if (activeProject != null && activeProject.isNotEmpty) {
      filters.add(['Task Progress', 'project', '=', activeProject]);
    }

    return sdk.api.doctype.list(
      'Task Progress',
      fields: ['name', 'project', 'site_date', 'docstatus'],
      filters: filters,
      limitStart: (page - 1) * pageSize,
      limitPageLength: pageSize,
      orderBy: 'site_date desc',
    );
  }

  @override
  Future<Map<String, dynamic>> getTaskProgressDetails(String name) async {
    return sdk.api.doctype.getByName('Task Progress', name);
  }

  @override
  Future<DocTypeMeta> getMeta() async {
    return sdk.meta.getMeta('Task Progress', forceRefresh: true);
  }

  @override
  Future<Map<String, dynamic>?> loadDocument(String? progressName) async {
    if (progressName == null) return null;
    try {
      final serverData = await sdk.api.doctype.getByName(
        'Task Progress',
        progressName,
      );
      await sdk.repository.saveServerDocument(
        doctype: 'Task Progress',
        serverId: progressName,
        data: serverData,
      );
      return serverData;
    } catch (_) {
      final doc = await sdk.repository.getDocumentByServerId(
        progressName,
        'Task Progress',
      );
      return doc?.data;
    }
  }

  @override
  Future<String> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  }) async {
    if (existingServerId == null) {
      final result = await sdk.api.document.createDocument(
        'Task Progress',
        payload,
      );
      final serverName =
          result['name']?.toString() ?? result['docname']?.toString() ?? '';
      if (serverName.isNotEmpty) {
        final merged = Map<String, dynamic>.from(payload)
          ..['name'] = serverName;
        try {
          await sdk.api.document.submitDocument('Task Progress', serverName);
          merged['docstatus'] = 1;
        } catch (e) {
          merged['docstatus'] = 0;
          await sdk.repository.saveServerDocument(
            doctype: 'Task Progress',
            serverId: serverName,
            data: merged,
          );
          rethrow;
        }
        await sdk.repository.saveServerDocument(
          doctype: 'Task Progress',
          serverId: serverName,
          data: merged,
        );
      }
      return serverName;
    } else {
      final doc = await sdk.repository.getDocumentByServerId(
        existingServerId,
        'Task Progress',
      );
      final existingData = Map<String, dynamic>.from(doc?.data ?? {})
        ..addAll(payload);
      await sdk.api.document.updateDocument(
        'Task Progress',
        existingServerId,
        existingData,
      );
      final docstatus =
          int.tryParse(existingData['docstatus']?.toString() ?? '0') ?? 0;
      if (docstatus == 0) {
        try {
          await sdk.api.document.submitDocument(
            'Task Progress',
            existingServerId,
          );
          existingData['docstatus'] = 1;
        } catch (e) {
          existingData['docstatus'] = 0;
          if (doc != null) {
            await sdk.repository.updateDocumentData(doc.localId, existingData);
          }
          rethrow;
        }
      }
      if (doc != null) {
        await sdk.repository.updateDocumentData(doc.localId, existingData);
      }
      return existingServerId;
    }
  }

  @override
  Future<void> uploadFile({
    required String serverName,
    required String filePath,
  }) async {
    final baseUrl = getBaseUrl();
    final uploadUrl = '$baseUrl/api/method/upload_file';
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.headers.addAll(sdk.api.requestHeaders);
    request.fields['doctype'] = 'Task Progress';
    request.fields['docname'] = serverName;
    request.fields['is_private'] = '0';
    final file = File(filePath);
    final fileName = filePath.split('/').last;
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path, filename: fileName),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.body}');
    }
  }

  @override
  String getBaseUrl() {
    final url = sdk.baseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  @override
  Future<Uint8List> downloadPdf(String entryName) async {
    final baseUrl = getBaseUrl();
    final urlStr =
        '$baseUrl/api/method/frappe.utils.print_format.download_pdf'
        '?doctype=Task%20Progress'
        '&name=${Uri.encodeComponent(entryName)}'
        '&format=Standard'
        '&no_letterhead=0'
        '&letterhead=Company%20Letterhead%20-%20Grey'
        '&settings=%7B%7D'
        '&_lang=en'
        '&pdf_generator=wkhtmltopdf';

    final headers = sdk.api.requestHeaders;
    final response = await sdk.api.rest.client.get(
      Uri.parse(urlStr),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Server returned status ${response.statusCode}');
  }
}
