import 'package:equatable/equatable.dart';
import 'stock_entry_item.dart';

class StockEntry extends Equatable {
  final String name;
  final String stockEntryType;
  final DateTime? postingDate;
  final String purpose;
  final String? fromWarehouse;
  final String? toWarehouse;
  final double totalIncomingValue;
  final double totalOutgoingValue;
  final String status;
  final List<StockEntryItem> items;
  final Map<String, dynamic> rawData;

  const StockEntry({
    required this.name,
    required this.stockEntryType,
    this.postingDate,
    required this.purpose,
    this.fromWarehouse,
    this.toWarehouse,
    this.totalIncomingValue = 0.0,
    this.totalOutgoingValue = 0.0,
    required this.status,
    this.items = const [],
    this.rawData = const {},
  });

  @override
  List<Object?> get props => [
    name,
    stockEntryType,
    postingDate,
    purpose,
    fromWarehouse,
    toWarehouse,
    totalIncomingValue,
    totalOutgoingValue,
    status,
    items,
    rawData,
  ];
}
