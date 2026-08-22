import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/manpower_usage.dart';

enum ManpowerUsageStatus { initial, loading, loadingMore, success, failure }

enum ManpowerUsagePdfStatus { initial, downloading, success, failure }

class ManpowerUsageState extends Equatable {
  final ManpowerUsageStatus status;
  final List<ManpowerUsage> usages;
  final ManpowerUsage? selectedUsage;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final String searchQuery;
  final String? filterStatus;
  final String? project;
  
  final String? baseUrl;
  final ManpowerUsagePdfStatus pdfStatus;
  final Uint8List? pdfBytes;
  final String? pdfEntryName;
  final String? pdfError;

  const ManpowerUsageState({
    this.status = ManpowerUsageStatus.initial,
    this.usages = const [],
    this.selectedUsage,
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery = '',
    this.filterStatus,
    this.project,
    this.baseUrl,
    this.pdfStatus = ManpowerUsagePdfStatus.initial,
    this.pdfBytes,
    this.pdfEntryName,
    this.pdfError,
  });

  ManpowerUsageState copyWith({
    ManpowerUsageStatus? status,
    List<ManpowerUsage>? usages,
    ManpowerUsage? selectedUsage,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    String? filterStatus,
    String? project,
    String? baseUrl,
    ManpowerUsagePdfStatus? pdfStatus,
    Uint8List? pdfBytes,
    String? pdfEntryName,
    String? pdfError,
  }) {
    return ManpowerUsageState(
      status: status ?? this.status,
      usages: usages ?? this.usages,
      selectedUsage: selectedUsage ?? this.selectedUsage,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      project: project ?? this.project,
      baseUrl: baseUrl ?? this.baseUrl,
      pdfStatus: pdfStatus ?? this.pdfStatus,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      pdfEntryName: pdfEntryName ?? this.pdfEntryName,
      pdfError: pdfError ?? this.pdfError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        usages,
        selectedUsage,
        errorMessage,
        hasReachedMax,
        currentPage,
        searchQuery,
        filterStatus,
        project,
        baseUrl,
        pdfStatus,
        pdfBytes,
        pdfEntryName,
        pdfError,
      ];
}
