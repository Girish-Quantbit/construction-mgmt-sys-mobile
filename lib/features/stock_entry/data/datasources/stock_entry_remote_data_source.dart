import 'dart:typed_data';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/services/project_selection_service.dart';

abstract class StockEntryRemoteDataSource {
  Future<List<dynamic>> getStockEntries({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? stockEntryType,
    String? project,
  });

  Future<Map<String, dynamic>> getStockEntryDetails(String name);

  Future<Map<String, dynamic>?> loadDocument(String? entryName);

  Future<String> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  });

  String getBaseUrl();

  Future<Uint8List> downloadPdf(String entryName);
}

class StockEntryRemoteDataSourceImpl implements StockEntryRemoteDataSource {
  final FrappeSDK sdk;
  final ProjectSelectionService projectSelectionService;

  StockEntryRemoteDataSourceImpl({
    required this.sdk,
    required this.projectSelectionService,
  });

  @override
  Future<List<dynamic>> getStockEntries({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? stockEntryType,
    String? project,
  }) async {
    final List<List<dynamic>> filters = [];
    if (status != null && status.isNotEmpty) {
      filters.add(['Stock Entry', 'status', '=', status]);
    }
    if (stockEntryType != null && stockEntryType.isNotEmpty) {
      filters.add(['Stock Entry', 'stock_entry_type', '=', stockEntryType]);
    }
    if (search != null && search.isNotEmpty) {
      filters.add(['Stock Entry', 'name', 'like', '%$search%']);
    }

    final activeProject = (project != null && project.isNotEmpty)
        ? project
        : projectSelectionService.selectedProject;
    if (activeProject != null && activeProject.isNotEmpty) {
      filters.add(['Stock Entry', 'project', '=', activeProject]);
    }

    return sdk.api.doctype.list(
      'Stock Entry',
      fields: [
        'name',
        'stock_entry_type',
        'posting_date',
        'purpose',
        'docstatus',
        'from_warehouse',
        'to_warehouse',
        'total_incoming_value',
        'total_outgoing_value',
        'base_grand_total',
        'per_transferred',
      ],
      filters: filters,
      limitStart: (page - 1) * pageSize,
      limitPageLength: pageSize,
      orderBy: 'posting_date desc',
    );
  }

  @override
  Future<Map<String, dynamic>> getStockEntryDetails(String name) async {
    return sdk.api.doctype.getByName('Stock Entry', name);
  }

  @override
  Future<Map<String, dynamic>?> loadDocument(String? entryName) async {
    if (entryName == null) return null;
    try {
      final serverData = await sdk.api.doctype.getByName('Stock Entry', entryName);
      await sdk.repository.saveServerDocument(
        doctype: 'Stock Entry',
        serverId: entryName,
        data: serverData,
      );
      return serverData;
    } catch (_) {
      final doc = await sdk.repository.getDocumentByServerId(
        entryName,
        'Stock Entry',
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
      // Create new
      final result = await sdk.api.document.createDocument('Stock Entry', payload);
      final serverName =
          result['name']?.toString() ?? result['docname']?.toString() ?? '';
      if (serverName.isNotEmpty) {
        final merged = Map<String, dynamic>.from(payload)..['name'] = serverName;
        try {
          await sdk.api.document.submitDocument(
            'Stock Entry',
            serverName,
          );
          merged['docstatus'] = 1;
        } catch (e) {
          merged['docstatus'] = 0;
          await sdk.repository.saveServerDocument(
            doctype: 'Stock Entry',
            serverId: serverName,
            data: merged,
          );
          rethrow;
        }
        await sdk.repository.saveServerDocument(
          doctype: 'Stock Entry',
          serverId: serverName,
          data: merged,
        );
      }
      return serverName;
    } else {
      // Update existing
      final doc = await sdk.repository.getDocumentByServerId(
        existingServerId,
        'Stock Entry',
      );
      final existingData = Map<String, dynamic>.from(doc?.data ?? {})
        ..addAll(payload);
      await sdk.api.document.updateDocument(
        'Stock Entry',
        existingServerId,
        existingData,
      );
      final docstatus = int.tryParse(existingData['docstatus']?.toString() ?? '0') ?? 0;
      if (docstatus == 0) {
        try {
          await sdk.api.document.submitDocument(
            'Stock Entry',
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
  String getBaseUrl() {
    final url = sdk.baseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  @override
  Future<Uint8List> downloadPdf(String entryName) async {
    final baseUrl = getBaseUrl();
    final urlStr =
        '$baseUrl/api/method/frappe.utils.print_format.download_pdf'
        '?doctype=Stock%20Entry'
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
