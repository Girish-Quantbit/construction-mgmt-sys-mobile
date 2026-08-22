import 'package:equatable/equatable.dart';

class ApprovalItem extends Equatable {
  final String doctype; // 'Material Request' or 'Purchase Order'
  final String name; // e.g. PO-2026-00142 or MR-2026-00089
  final String? project; // Project name
  final String? owner; // Creator's name / ID
  final double amount; // Amount/grand total
  final String priority; // 'High Priority', 'Medium Priority', 'Low Priority'
  final String status; // e.g. Pending, Approved, Rejected, To Bill, etc.
  final DateTime? date; // Transaction/posting date

  const ApprovalItem({
    required this.doctype,
    required this.name,
    this.project,
    this.owner,
    required this.amount,
    required this.priority,
    required this.status,
    this.date,
  });

  @override
  List<Object?> get props => [
        doctype,
        name,
        project,
        owner,
        amount,
        priority,
        status,
        date,
      ];
}
