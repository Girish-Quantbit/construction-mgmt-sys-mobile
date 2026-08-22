import 'package:equatable/equatable.dart';

abstract class PurchaseReceiptEvent extends Equatable {
  const PurchaseReceiptEvent();

  @override
  List<Object?> get props => [];
}

class LoadPurchaseReceipts extends PurchaseReceiptEvent {
  final bool isRefresh;
  final String? project;
  const LoadPurchaseReceipts({this.isRefresh = false, this.project});

  @override
  List<Object?> get props => [isRefresh, project];
}

class SearchChanged extends PurchaseReceiptEvent {
  final String query;
  const SearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterChanged extends PurchaseReceiptEvent {
  final String? status;
  const FilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadMorePurchaseReceipts extends PurchaseReceiptEvent {}

class SortChanged extends PurchaseReceiptEvent {
  final String sortBy;
  final String sortOrder;
  const SortChanged({required this.sortBy, required this.sortOrder});

  @override
  List<Object?> get props => [sortBy, sortOrder];
}

class ApplyFilters extends PurchaseReceiptEvent {
  final String? status;
  final String? supplier;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ApplyFilters({this.status, this.supplier, this.fromDate, this.toDate});

  @override
  List<Object?> get props => [status, supplier, fromDate, toDate];
}

class ClearFilters extends PurchaseReceiptEvent {}

class LoadPurchaseReceiptDetails extends PurchaseReceiptEvent {
  final String name;
  const LoadPurchaseReceiptDetails(this.name);

  @override
  List<Object?> get props => [name];
}

class DownloadPurchaseReceiptPDF extends PurchaseReceiptEvent {
  final String name;
  const DownloadPurchaseReceiptPDF(this.name);

  @override
  List<Object?> get props => [name];
}

