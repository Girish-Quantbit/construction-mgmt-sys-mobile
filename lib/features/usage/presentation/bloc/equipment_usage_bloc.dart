import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../domain/repositories/equipment_usage_repository.dart';
import 'equipment_usage_event.dart';
import 'equipment_usage_state.dart';

class EquipmentUsageBloc
    extends Bloc<EquipmentUsageEvent, EquipmentUsageState> {
  final EquipmentUsageRepository repository;
  static const int pageSize = 20;
  Timer? _debounce;

  EquipmentUsageBloc({required this.repository})
    : super(const EquipmentUsageState()) {
    on<LoadEquipmentUsages>(_onLoadEquipmentUsages);
    on<LoadMoreEquipmentUsages>(_onLoadMoreEquipmentUsages);
    on<LoadEquipmentUsageDetails>(_onLoadEquipmentUsageDetails);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoadEquipmentUsages(
    LoadEquipmentUsages event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EquipmentUsageStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        usages: event.isRefresh ? [] : state.usages,
      ),
    );

    final result = await repository.getEquipmentUsages(
      page: 1,
      pageSize: pageSize,
      search: state.search,
      status: state.filterStatus,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EquipmentUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (usages) => emit(
        state.copyWith(
          status: EquipmentUsageStatus.success,
          usages: usages,
          hasReachedMax: usages.length < pageSize,
          currentPage: 1,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreEquipmentUsages(
    LoadMoreEquipmentUsages event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    if (state.hasReachedMax || state.status == EquipmentUsageStatus.loading) {
      return;
    }

    final nextPage = state.currentPage + 1;
    final result = await repository.getEquipmentUsages(
      page: nextPage,
      pageSize: pageSize,
      search: state.search,
      status: state.filterStatus,
    );

    result.fold(
      (failure) => null, // Silently fail on pagination
      (usages) => emit(
        state.copyWith(
          usages: List.of(state.usages)..addAll(usages),
          hasReachedMax: usages.length < pageSize,
          currentPage: nextPage,
        ),
      ),
    );
  }

  Future<void> _onLoadEquipmentUsageDetails(
    LoadEquipmentUsageDetails event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    emit(state.copyWith(detailStatus: EquipmentUsageStatus.loading));

    final result = await repository.getEquipmentUsageDetails(event.name);

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: EquipmentUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (usage) => emit(
        state.copyWith(
          detailStatus: EquipmentUsageStatus.success,
          selectedUsage: usage,
        ),
      ),
    );
  }

  void _onSearchChanged(
    SearchChanged event,
    Emitter<EquipmentUsageState> emit,
  ) {
    emit(state.copyWith(search: event.search));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      add(const LoadEquipmentUsages(isRefresh: true));
    });
  }

  void _onFilterChanged(
    FilterChanged event,
    Emitter<EquipmentUsageState> emit,
  ) {
    emit(state.copyWith(filterStatus: event.status));
    add(const LoadEquipmentUsages(isRefresh: true));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
