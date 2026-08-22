import 'package:equatable/equatable.dart';

abstract class StockEntryFormEvent extends Equatable {
  const StockEntryFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeStockEntryFormEvent extends StockEntryFormEvent {
  final String? entryName;
  final String? stockEntryType;

  const InitializeStockEntryFormEvent({this.entryName, this.stockEntryType});

  @override
  List<Object?> get props => [entryName, stockEntryType];
}

class SaveStockEntryFormEvent extends StockEntryFormEvent {
  final String? existingServerId;
  final Map<String, dynamic> payload;

  const SaveStockEntryFormEvent({
    required this.existingServerId,
    required this.payload,
  });

  @override
  List<Object?> get props => [existingServerId, payload];
}
