import 'package:equatable/equatable.dart';

abstract class StockEntryEvent extends Equatable {
  const StockEntryEvent();

  @override
  List<Object?> get props => [];
}

class LoadStockEntries extends StockEntryEvent {
  final bool isRefresh;
  final String? status;
  final String? search;
  final String? stockEntryType;
  final String? project;

  const LoadStockEntries({
    this.isRefresh = false,
    this.status,
    this.search,
    this.stockEntryType,
    this.project,
  });

  @override
  List<Object?> get props => [isRefresh, status, search, stockEntryType, project];
}

class LoadStockEntryDetails extends StockEntryEvent {
  final String name;

  const LoadStockEntryDetails(this.name);

  @override
  List<Object?> get props => [name];
}
