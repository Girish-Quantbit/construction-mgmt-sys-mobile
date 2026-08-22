import 'package:equatable/equatable.dart';
import 'approval_item.dart';

class ApprovalResult extends Equatable {
  final List<ApprovalItem> items;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const ApprovalResult({
    required this.items,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  @override
  List<Object?> get props => [items, pendingCount, approvedCount, rejectedCount];
}
