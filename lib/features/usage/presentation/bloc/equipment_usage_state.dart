import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/equipment_usage.dart';

enum EquipmentUsageStatus { initial, loading, loadingMore, success, failure }

enum EquipmentUsagePdfStatus { initial, downloading, success, failure }

class EquipmentUsageState extends Equatable {
  final EquipmentUsageStatus status;
  final List<EquipmentUsage> usages;
  final EquipmentUsage? selectedUsage;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final String searchQuery;
  final String? filterStatus;
  final DateTime? filterFromDate;
  final DateTime? filterToDate;
  final String? project;
  
  final String? baseUrl;
  final EquipmentUsagePdfStatus pdfStatus;
  final Uint8List? pdfBytes;
  final String? pdfEntryName;
  final String? pdfError;

  const EquipmentUsageState({
    this.status = EquipmentUsageStatus.initial,
    this.usages = const [],
    this.selectedUsage,
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery = '',
    this.filterStatus,
    this.filterFromDate,
    this.filterToDate,
    this.project,
    this.baseUrl,
    this.pdfStatus = EquipmentUsagePdfStatus.initial,
    this.pdfBytes,
    this.pdfEntryName,
    this.pdfError,
  });

  EquipmentUsageState copyWith({
    EquipmentUsageStatus? status,
    List<EquipmentUsage>? usages,
    EquipmentUsage? selectedUsage,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    String? filterStatus,
    DateTime? filterFromDate,
    DateTime? filterToDate,
    String? project,
    String? baseUrl,
    EquipmentUsagePdfStatus? pdfStatus,
    Uint8List? pdfBytes,
    String? pdfEntryName,
    String? pdfError,
  }) {
    return EquipmentUsageState(
      status: status ?? this.status,
      usages: usages ?? this.usages,
      selectedUsage: selectedUsage ?? this.selectedUsage,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      filterFromDate: filterFromDate ?? this.filterFromDate,
      filterToDate: filterToDate ?? this.filterToDate,
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
        filterFromDate,
        filterToDate,
        project,
        baseUrl,
        pdfStatus,
        pdfBytes,
        pdfEntryName,
        pdfError,
      ];
}
