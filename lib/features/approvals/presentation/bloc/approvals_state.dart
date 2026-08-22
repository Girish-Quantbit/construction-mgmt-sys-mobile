import 'package:equatable/equatable.dart';
import '../../domain/entities/approval_item.dart';

enum ApprovalsStatus { initial, loading, success, failure }

class ApprovalsState extends Equatable {
  final List<ApprovalItem> pendingItems;
  final List<ApprovalItem> approvedItems;
  final List<ApprovalItem> rejectedItems;
  final String selectedFilter; // 'Pending', 'Approved', 'Rejected'
  final ApprovalsStatus status;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final String? project;
  final String? errorMessage;

  const ApprovalsState({
    this.pendingItems = const [],
    this.approvedItems = const [],
    this.rejectedItems = const [],
    this.selectedFilter = 'Pending',
    this.status = ApprovalsStatus.initial,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.project,
    this.errorMessage,
  });

  ApprovalsState copyWith({
    List<ApprovalItem>? pendingItems,
    List<ApprovalItem>? approvedItems,
    List<ApprovalItem>? rejectedItems,
    String? selectedFilter,
    ApprovalsStatus? status,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
    String? project,
    String? errorMessage,
  }) {
    return ApprovalsState(
      pendingItems: pendingItems ?? this.pendingItems,
      approvedItems: approvedItems ?? this.approvedItems,
      rejectedItems: rejectedItems ?? this.rejectedItems,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      project: project ?? this.project,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        pendingItems,
        approvedItems,
        rejectedItems,
        selectedFilter,
        status,
        pendingCount,
        approvedCount,
        rejectedCount,
        project,
        errorMessage,
      ];
}
