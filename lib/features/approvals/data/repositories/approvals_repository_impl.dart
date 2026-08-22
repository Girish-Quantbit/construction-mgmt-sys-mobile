import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/api_handler.dart';
import '../../../../core/services/project_selection_service.dart';
import '../../../material_requests/domain/entities/material_request.dart';
import '../../../material_requests/domain/repositories/material_request_repository.dart';
import '../../domain/entities/approval_item.dart';
import '../../domain/repositories/approvals_repository.dart';

class ApprovalsRepositoryImpl implements ApprovalsRepository {
  final FrappeSDK sdk;
  final MaterialRequestRepository materialRequestRepository;
  final ProjectSelectionService projectSelectionService;

  ApprovalsRepositoryImpl({
    required this.sdk,
    required this.materialRequestRepository,
    required this.projectSelectionService,
  });

  @override
  Future<Either<Failure, List<ApprovalItem>>> getApprovals({
    String? project,
  }) async {
    try {
      final activeProject = (project != null && project.isNotEmpty)
          ? project
          : projectSelectionService.selectedProject;

      // Fetch Material Requests and Purchase Orders in parallel (only 2 API calls!)
      final futures = await Future.wait([
        _fetchMaterialRequests(activeProject),
        _fetchPurchaseOrders(activeProject),
      ]);

      final materialRequests = futures[0] as List<MaterialRequest>;
      final purchaseOrders = futures[1] as List<Map<String, dynamic>>;

      // Map Material Requests to ApprovalItems
      final List<ApprovalItem> mrItems = materialRequests.map((mr) {
        // Calculate amount by summing item amounts
        double totalAmount = 0.0;
        if (mr.rawData.containsKey('items')) {
          final items = mr.rawData['items'] as List<dynamic>;
          for (final item in items) {
            if (item is Map) {
              final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
              final rate = (item['rate'] as num?)?.toDouble() ?? 0.0;
              final amt = (item['amount'] as num?)?.toDouble() ?? (qty * rate);
              totalAmount += amt;
            }
          }
        }

        // Project name from child items
        String? mrProject;
        if (mr.items.isNotEmpty) {
          mrProject = mr.rawData['items']?[0]?['project']?.toString();
        }
        mrProject ??= mr.rawData['project']?.toString() ?? activeProject ?? 'No Project';

        final owner = mr.rawData['owner']?.toString() ?? 'System';

        // Calculate priority
        String priority = 'Low Priority';
        if (totalAmount > 100000) {
          priority = 'High Priority';
        } else if (totalAmount > 20000) {
          priority = 'Medium Priority';
        }

        return ApprovalItem(
          doctype: 'Material Request',
          name: mr.name,
          project: mrProject,
          owner: _formatOwner(owner, mr.transactionDate),
          amount: totalAmount,
          priority: priority,
          status: mr.status,
          date: mr.transactionDate,
        );
      }).toList();

      // Map Purchase Orders to ApprovalItems
      final List<ApprovalItem> poItems = purchaseOrders.map((po) {
        final name = po['name']?.toString() ?? '';
        final status = po['status']?.toString() ?? '';
        final amount = (po['grand_total'] as num?)?.toDouble() ?? 0.0;
        final poProject = po['project']?.toString() ?? activeProject ?? 'No Project';
        final owner = po['owner']?.toString() ?? 'System';
        final dateStr = po['transaction_date']?.toString();
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

        // Calculate priority
        String priority = 'Low Priority';
        if (amount > 500000) {
          priority = 'High Priority';
        } else if (amount > 100000) {
          priority = 'Medium Priority';
        }

        return ApprovalItem(
          doctype: 'Purchase Order',
          name: name,
          project: poProject,
          owner: _formatOwner(owner, date),
          amount: amount,
          priority: priority,
          status: status,
          date: date,
        );
      }).toList();

      // Combine and sort items by date descending
      final List<ApprovalItem> combinedItems = [...mrItems, ...poItems];
      combinedItems.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

      return Right(combinedItems);
    } catch (e) {
      debugPrint('Error in getApprovals: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<List<MaterialRequest>> _fetchMaterialRequests(String? project) async {
    final List<MaterialRequest> results = [];
    final mrResult = await materialRequestRepository.getMaterialRequests(
      project: project,
      pageSize: 50,
    );
    mrResult.fold(
      (failure) => debugPrint('Error fetching MRs: ${failure.message}'),
      (requests) => results.addAll(requests),
    );
    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchPurchaseOrders(String? project) async {
    final List<List<dynamic>> filters = [];
    filters.add([
      'Purchase Order',
      'status',
      'in',
      ['To Bill', 'To Receive', 'To Receive & Bill', 'To Receive and Bill', 'Completed', 'Closed', 'Cancelled']
    ]);

    if (project != null && project.isNotEmpty) {
      filters.add(['Purchase Order', 'project', '=', project]);
    }

    final List<dynamic> rawList = await ApiHandler.call(() => sdk.api.doctype.list(
          'Purchase Order',
          fields: ['name', 'supplier', 'transaction_date', 'status', 'grand_total', 'project', 'owner'],
          filters: filters,
          limitPageLength: 50,
          orderBy: 'transaction_date desc',
        ));

    return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _formatOwner(String rawOwner, DateTime? date) {
    String name = 'System';
    if (rawOwner.isNotEmpty) {
      final part = rawOwner.split('@').first;
      name = part.split(RegExp(r'[._]')).map((s) {
        if (s.isEmpty) return '';
        return s[0].toUpperCase() + s.substring(1);
      }).join(' ');
    }
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : '';
    return 'By $name${dateStr.isNotEmpty ? ' • $dateStr' : ''}';
  }
}
