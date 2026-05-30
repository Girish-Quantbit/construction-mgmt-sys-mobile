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
      filterStatus: filterStatus ?? this.filterStatus,
      project: project ?? this.project,
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
  ];
}
