import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/material_request.dart';

enum MaterialRequestStatus { initial, loading, success, failure, loadingMore }

class MaterialRequestState extends Equatable {
  final List<MaterialRequest> requests;
  final MaterialRequest? selectedRequest;
  final MaterialRequestStatus status;
  final MaterialRequestStatus detailStatus;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;
  final String? filterStatus;
  final String? project;
  final String? materialRequestType;
  final DateTimeRange? requiredByDateRange;
  final DateTimeRange? transactionDateRange;
  final MaterialRequestStatus pdfStatus;
  final String? pdfPath;

  const MaterialRequestState({
    this.requests = const [],
    this.selectedRequest,
    this.status = MaterialRequestStatus.initial,
    this.detailStatus = MaterialRequestStatus.initial,
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery,
    this.filterStatus,
    this.project,
    this.materialRequestType,
    this.requiredByDateRange,
    this.transactionDateRange,
    this.pdfStatus = MaterialRequestStatus.initial,
    this.pdfPath,
  });

  MaterialRequestState copyWith({
    List<MaterialRequest>? requests,
    MaterialRequest? selectedRequest,
    MaterialRequestStatus? status,
    MaterialRequestStatus? detailStatus,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    String? filterStatus,
    String? project,
    String? materialRequestType,
    DateTimeRange? requiredByDateRange,
    DateTimeRange? transactionDateRange,
    MaterialRequestStatus? pdfStatus,
    String? pdfPath,
    bool clearFilters = false,
  }) {
    return MaterialRequestState(
      requests: requests ?? this.requests,
      selectedRequest: selectedRequest ?? this.selectedRequest,
      status: status ?? this.status,
      detailStatus: detailStatus ?? this.detailStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: clearFilters ? null : (filterStatus ?? this.filterStatus),
      project: project ?? this.project,
      materialRequestType: clearFilters ? null : (materialRequestType ?? this.materialRequestType),
      requiredByDateRange: clearFilters ? null : (requiredByDateRange ?? this.requiredByDateRange),
      transactionDateRange: clearFilters ? null : (transactionDateRange ?? this.transactionDateRange),
      pdfStatus: pdfStatus ?? this.pdfStatus,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }

  @override
  List<Object?> get props => [
    requests,
    selectedRequest,
    status,
    detailStatus,
    errorMessage,
    hasReachedMax,
    currentPage,
    searchQuery,
    filterStatus,
    project,
    materialRequestType,
    requiredByDateRange,
    transactionDateRange,
    pdfStatus,
    pdfPath,
  ];
}
