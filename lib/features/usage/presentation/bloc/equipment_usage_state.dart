import 'package:equatable/equatable.dart';
import '../../domain/entities/equipment_usage.dart';

enum EquipmentUsageStatus { initial, loading, success, failure }

class EquipmentUsageState extends Equatable {
  final EquipmentUsageStatus status;
  final List<EquipmentUsage> usages;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;
  final String? search;
  final String? filterStatus;
  final EquipmentUsage? selectedUsage;
  final EquipmentUsageStatus detailStatus;

  const EquipmentUsageState({
    this.status = EquipmentUsageStatus.initial,
    this.usages = const [],
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.search,
    this.filterStatus,
    this.selectedUsage,
    this.detailStatus = EquipmentUsageStatus.initial,
  });

  EquipmentUsageState copyWith({
    EquipmentUsageStatus? status,
    List<EquipmentUsage>? usages,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
    String? search,
    String? filterStatus,
    EquipmentUsage? selectedUsage,
    EquipmentUsageStatus? detailStatus,
  }) {
    return EquipmentUsageState(
      status: status ?? this.status,
      usages: usages ?? this.usages,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      search: search ?? this.search,
      filterStatus: filterStatus ?? this.filterStatus,
      selectedUsage: selectedUsage ?? this.selectedUsage,
      detailStatus: detailStatus ?? this.detailStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    usages,
    errorMessage,
    hasReachedMax,
    currentPage,
    search,
    filterStatus,
    selectedUsage,
    detailStatus,
  ];
}
