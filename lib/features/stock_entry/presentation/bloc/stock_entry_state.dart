import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/stock_entry.dart';

enum StockEntryStatus { initial, loading, success, failure }

enum StockEntryPdfStatus { initial, downloading, success, failure }

class StockEntryState extends Equatable {
  final StockEntryStatus listStatus;
  final StockEntryStatus detailStatus;
  final List<StockEntry> entries;
  final StockEntry? selectedEntry;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final String? project;
  final StockEntryPdfStatus pdfStatus;
  final Uint8List? pdfBytes;
  final String? pdfEntryName;

  const StockEntryState({
    this.listStatus = StockEntryStatus.initial,
    this.detailStatus = StockEntryStatus.initial,
    this.entries = const [],
    this.selectedEntry,
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.project,
    this.pdfStatus = StockEntryPdfStatus.initial,
    this.pdfBytes,
    this.pdfEntryName,
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
    StockEntryPdfStatus? pdfStatus,
    Uint8List? pdfBytes,
    String? pdfEntryName,
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
      pdfStatus: pdfStatus ?? this.pdfStatus,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      pdfEntryName: pdfEntryName ?? this.pdfEntryName,
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
    pdfStatus,
    pdfBytes,
    pdfEntryName,
  ];
}
