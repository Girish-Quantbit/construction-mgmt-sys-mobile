import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/material_request_repository.dart';
import 'material_request_event.dart';
import 'material_request_state.dart';

class MaterialRequestBloc
    extends Bloc<MaterialRequestEvent, MaterialRequestState> {
  final MaterialRequestRepository repository;

  MaterialRequestBloc({required this.repository})
      : super(const MaterialRequestState()) {
    on<LoadMaterialRequests>(_onLoadMaterialRequests);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<LoadMoreMaterialRequests>(_onLoadMoreMaterialRequests);
    on<LoadMaterialRequestDetails>(_onLoadMaterialRequestDetails);
  }

  Future<void> _onLoadMaterialRequests(
    LoadMaterialRequests event,
    Emitter<MaterialRequestState> emit,
  ) async {
    final project = event.project ?? state.project;
    emit(
      state.copyWith(
        status: MaterialRequestStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        project: project,
      ),
    );

    final result = await repository.getMaterialRequests(
      page: 1,
      search: state.searchQuery,
      status: state.filterStatus,
      project: project,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MaterialRequestStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (requests) => emit(
        state.copyWith(
          status: MaterialRequestStatus.success,
          requests: requests,
          hasReachedMax: requests.length < 20,
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(
    SearchChanged event,
    Emitter<MaterialRequestState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(LoadMaterialRequests(project: state.project));
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<MaterialRequestState> emit,
  ) async {
    emit(state.copyWith(filterStatus: event.status));
    add(LoadMaterialRequests(project: state.project));
  }

  Future<void> _onLoadMoreMaterialRequests(
    LoadMoreMaterialRequests event,
    Emitter<MaterialRequestState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.status == MaterialRequestStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: MaterialRequestStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final result = await repository.getMaterialRequests(
      page: nextPage,
      search: state.searchQuery,
      status: state.filterStatus,
      project: state.project,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MaterialRequestStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (newRequests) => emit(
        state.copyWith(
          status: MaterialRequestStatus.success,
          requests: List.of(state.requests)..addAll(newRequests),
          currentPage: nextPage,
          hasReachedMax: newRequests.length < 20,
        ),
      ),
    );
  }

  Future<void> _onLoadMaterialRequestDetails(
    LoadMaterialRequestDetails event,
    Emitter<MaterialRequestState> emit,
  ) async {
    emit(state.copyWith(detailStatus: MaterialRequestStatus.loading));

    final result = await repository.getMaterialRequestDetails(event.name);

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: MaterialRequestStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (request) => emit(
        state.copyWith(
          detailStatus: MaterialRequestStatus.success,
          selectedRequest: request,
        ),
      ),
    );
  }
}
