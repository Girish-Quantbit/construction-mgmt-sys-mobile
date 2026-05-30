import 'package:equatable/equatable.dart';
import '../../domain/entities/manpower_usage.dart';

enum ManpowerUsageStatus { initial, loading, success, failure, loadingMore }

class ManpowerUsageState extends Equatable {
  final ManpowerUsageStatus status;
  final ManpowerUsageStatus detailStatus;
  final List<ManpowerUsage> usages;
  final ManpowerUsage? selectedUsage;
  final String? errorMessage;
  final String? searchQuery;
  final String? filterStatus;
  final int currentPage;
  final bool hasReachedMax;

  const ManpowerUsageState({
    this.status = ManpowerUsageStatus.initial,
    this.detailStatus = ManpowerUsageStatus.initial,
    this.usages = const [],
    this.selectedUsage,
    this.errorMessage,
    this.searchQuery,
    this.filterStatus,
    this.currentPage = 1,
    this.hasReachedMax = false,
  });

  ManpowerUsageState copyWith({
    ManpowerUsageStatus? status,
    ManpowerUsageStatus? detailStatus,
    List<ManpowerUsage>? usages,
    ManpowerUsage? selectedUsage,
    String? errorMessage,
    String? searchQuery,
    String? filterStatus,
    int? currentPage,
    bool? hasReachedMax,
  }) {
    return ManpowerUsageState(
      status: status ?? this.status,
      detailStatus: detailStatus ?? this.detailStatus,
      usages: usages ?? this.usages,
      selectedUsage: selectedUsage ?? this.selectedUsage,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
    status,
    detailStatus,
    usages,
    selectedUsage,
    errorMessage,
    searchQuery,
    filterStatus,
    currentPage,
    hasReachedMax,
  ];
}
