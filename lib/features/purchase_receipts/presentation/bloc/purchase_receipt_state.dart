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
  final String sortBy;
  final String sortOrder;
  final String? filterSupplier;
  final DateTime? filterFromDate;
  final DateTime? filterToDate;
  final PurchaseReceiptStatus pdfStatus;
  final String? pdfPath;

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
    this.sortBy = 'posting_date',
    this.sortOrder = 'desc',
    this.filterSupplier,
    this.filterFromDate,
    this.filterToDate,
    this.pdfStatus = PurchaseReceiptStatus.initial,
    this.pdfPath,
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
    String? sortBy,
    String? sortOrder,
    String? filterSupplier,
    DateTime? filterFromDate,
    DateTime? filterToDate,
    PurchaseReceiptStatus? pdfStatus,
    String? pdfPath,
    bool clearFilters = false,
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
      filterStatus: clearFilters ? null : (filterStatus ?? this.filterStatus),
      project: project ?? this.project,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      filterSupplier: clearFilters ? null : (filterSupplier ?? this.filterSupplier),
      filterFromDate: clearFilters ? null : (filterFromDate ?? this.filterFromDate),
      filterToDate: clearFilters ? null : (filterToDate ?? this.filterToDate),
      pdfStatus: pdfStatus ?? this.pdfStatus,
      pdfPath: pdfPath ?? this.pdfPath,
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
    sortBy,
    sortOrder,
    filterSupplier,
    filterFromDate,
    filterToDate,
    pdfStatus,
    pdfPath,
  ];
}

