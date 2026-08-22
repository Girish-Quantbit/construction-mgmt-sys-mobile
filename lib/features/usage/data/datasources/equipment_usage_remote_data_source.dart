import 'dart:typed_data';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';

abstract class EquipmentUsageRemoteDataSource {
  Future<List<dynamic>> getEquipmentUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? project,
  });

  Future<Map<String, dynamic>> getEquipmentUsageDetails(String name);

  Future<DocTypeMeta> getMeta();

  Future<Map<String, dynamic>?> loadDocument(String? usageName);

  Future<String> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  });

  String getBaseUrl();

  Future<Uint8List> downloadPdf(String entryName);
}

class EquipmentUsageRemoteDataSourceImpl implements EquipmentUsageRemoteDataSource {
  final FrappeSDK sdk;

  EquipmentUsageRemoteDataSourceImpl({required this.sdk});

  @override
  Future<List<dynamic>> getEquipmentUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? project,
  }) async {
    final List<List<dynamic>> filters = [];
    if (search != null && search.isNotEmpty) {
      filters.add(['Equipment Usage', 'name', 'like', '%$search%']);
    }
    if (status != null && status.isNotEmpty) {
      filters.add(['Equipment Usage', 'status', '=', status]);
    }
    if (project != null && project.isNotEmpty) {
      filters.add(['Equipment Usage', 'project', '=', project]);
    }

    return sdk.api.doctype.list(
      'Equipment Usage',
      fields: ['name', 'project', 'site_date', 'docstatus'],
      filters: filters,
      limitStart: (page - 1) * pageSize,
      limitPageLength: pageSize,
      orderBy: 'site_date desc',
    );
  }

  @override
  Future<Map<String, dynamic>> getEquipmentUsageDetails(String name) async {
    return sdk.api.doctype.getByName('Equipment Usage', name);
  }

  @override
  Future<DocTypeMeta> getMeta() async {
    return sdk.meta.getMeta('Equipment Usage', forceRefresh: true);
  }

  @override
  Future<Map<String, dynamic>?> loadDocument(String? usageName) async {
    if (usageName == null) return null;
    try {
      final serverData = await sdk.api.doctype.getByName('Equipment Usage', usageName);
      await sdk.repository.saveServerDocument(
        doctype: 'Equipment Usage',
        serverId: usageName,
        data: serverData,
      );
      return serverData;
    } catch (_) {
      final doc = await sdk.repository.getDocumentByServerId(
        usageName,
        'Equipment Usage',
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
      final result = await sdk.api.document.createDocument('Equipment Usage', payload);
      final serverName =
          result['name']?.toString() ?? result['docname']?.toString() ?? '';
      if (serverName.isNotEmpty) {
        final merged = Map<String, dynamic>.from(payload)..['name'] = serverName;
        await sdk.repository.saveServerDocument(
          doctype: 'Equipment Usage',
          serverId: serverName,
          data: merged,
        );
      }
      return serverName;
    } else {
      final doc = await sdk.repository.getDocumentByServerId(
        existingServerId,
        'Equipment Usage',
      );
      final existingData = Map<String, dynamic>.from(doc?.data ?? {})
        ..addAll(payload);
      await sdk.api.document.updateDocument(
        'Equipment Usage',
        existingServerId,
        existingData,
      );
      if (doc != null) {
        await sdk.repository.updateDocumentData(doc.localId, existingData);
      }
      return existingServerId;
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
        '?doctype=Equipment%20Usage'
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
