import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/manpower_usage_repository.dart';
import 'manpower_usage_event.dart';
import 'manpower_usage_state.dart';

class ManpowerUsageBloc extends Bloc<ManpowerUsageEvent, ManpowerUsageState> {
  final ManpowerUsageRepository repository;

  ManpowerUsageBloc({required this.repository})
    : super(const ManpowerUsageState()) {
    on<LoadManpowerUsages>(_onLoadManpowerUsages);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<LoadMoreManpowerUsages>(_onLoadMoreManpowerUsages);
    on<LoadManpowerUsageDetails>(_onLoadManpowerUsageDetails);
  }

  Future<void> _onLoadManpowerUsages(
    LoadManpowerUsages event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ManpowerUsageStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
      ),
    );

    final result = await repository.getManpowerUsages(
      page: 1,
      search: state.searchQuery,
      status: state.filterStatus,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ManpowerUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (usages) => emit(
        state.copyWith(
          status: ManpowerUsageStatus.success,
          usages: usages,
          hasReachedMax: usages.length < 20,
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(
    SearchChanged event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(const LoadManpowerUsages());
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    emit(state.copyWith(filterStatus: event.status));
    add(const LoadManpowerUsages());
  }

  Future<void> _onLoadMoreManpowerUsages(
    LoadMoreManpowerUsages event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.status == ManpowerUsageStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: ManpowerUsageStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final result = await repository.getManpowerUsages(
      page: nextPage,
      search: state.searchQuery,
      status: state.filterStatus,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ManpowerUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (newUsages) => emit(
        state.copyWith(
          status: ManpowerUsageStatus.success,
          usages: List.of(state.usages)..addAll(newUsages),
          currentPage: nextPage,
          hasReachedMax: newUsages.length < 20,
        ),
      ),
    );
  }

  Future<void> _onLoadManpowerUsageDetails(
    LoadManpowerUsageDetails event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    emit(state.copyWith(detailStatus: ManpowerUsageStatus.loading));

    final result = await repository.getManpowerUsageDetails(event.name);

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: ManpowerUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (usage) => emit(
        state.copyWith(
          detailStatus: ManpowerUsageStatus.success,
          selectedUsage: usage,
        ),
      ),
    );
  }
}
