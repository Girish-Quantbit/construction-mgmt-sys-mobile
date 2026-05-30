import 'package:equatable/equatable.dart';
import '../../domain/entities/purchase_receipt.dart';

enum PurchaseReceiptStatus { initial, loading, success, failure, loadingMore }

class PurchaseReceiptState extends Equatable {
  final List<PurchaseReceipt> receipts;
  final PurchaseReceipt? selectedReceipt;
  final PurchaseReceiptStatus status;
  final PurchaseReceiptStatus detailStatus;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;
  final String? filterStatus;
  final String? project;

  const PurchaseReceiptState({
    this.receipts = const [],
    this.selectedReceipt,
    this.status = PurchaseReceiptStatus.initial,
    this.detailStatus = PurchaseReceiptStatus.initial,
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery,
    this.filterStatus,
    this.project,
  });

  PurchaseReceiptState copyWith({
    List<PurchaseReceipt>? receipts,
    PurchaseReceipt? selectedReceipt,
    PurchaseReceiptStatus? status,
    PurchaseReceiptStatus? detailStatus,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    String? filterStatus,
    String? project,
  }) {
    return PurchaseReceiptState(
      receipts: receipts ?? this.receipts,
      selectedReceipt: selectedReceipt ?? this.selectedReceipt,
      status: status ?? this.status,
      detailStatus: detailStatus ?? this.detailStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      project: project ?? this.project,
    );
  }

  @override
  List<Object?> get props => [
    receipts,
    selectedReceipt,
    status,
    detailStatus,
    errorMessage,
    hasReachedMax,
    currentPage,
    searchQuery,
    filterStatus,
    project,
  ];
}
