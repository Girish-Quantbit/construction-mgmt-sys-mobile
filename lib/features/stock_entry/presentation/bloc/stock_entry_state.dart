import 'package:equatable/equatable.dart';
import '../../domain/entities/stock_entry.dart';

enum StockEntryStatus { initial, loading, success, failure }

class StockEntryState extends Equatable {
  final StockEntryStatus listStatus;
  final StockEntryStatus detailStatus;
  final List<StockEntry> entries;
  final StockEntry? selectedEntry;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final String? project;

  const StockEntryState({
    this.listStatus = StockEntryStatus.initial,
    this.detailStatus = StockEntryStatus.initial,
    this.entries = const [],
    this.selectedEntry,
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.project,
  });

  StockEntryState copyWith({
    StockEntryStatus? listStatus,
    StockEntryStatus? detailStatus,
    List<StockEntry>? entries,
    StockEntry? selectedEntry,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
    String? project,
  }) {
    return StockEntryState(
      listStatus: listStatus ?? this.listStatus,
      detailStatus: detailStatus ?? this.detailStatus,
      entries: entries ?? this.entries,
      selectedEntry: selectedEntry ?? this.selectedEntry,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      project: project ?? this.project,
    );
  }

  @override
  List<Object?> get props => [
    listStatus,
    detailStatus,
    entries,
    selectedEntry,
    errorMessage,
    hasReachedMax,
    currentPage,
    project,
  ];
}
