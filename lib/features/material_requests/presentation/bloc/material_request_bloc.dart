import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_material_requests.dart';
import '../../domain/usecases/get_material_request_details.dart';
import '../../domain/usecases/download_material_request_pdf.dart';
import 'material_request_event.dart';
import 'material_request_state.dart';

class MaterialRequestBloc
    extends Bloc<MaterialRequestEvent, MaterialRequestState> {
  final GetMaterialRequests getMaterialRequests;
  final GetMaterialRequestDetails getMaterialRequestDetails;
  final DownloadMaterialRequestPDFUsecase downloadPDF;

  Timer? _searchDebounceTimer;

  MaterialRequestBloc({
    required this.getMaterialRequests,
    required this.getMaterialRequestDetails,
    required this.downloadPDF,
  }) : super(const MaterialRequestState()) {
    on<LoadMaterialRequests>(_onLoadMaterialRequests);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<LoadMoreMaterialRequests>(_onLoadMoreMaterialRequests);
    on<LoadMaterialRequestDetails>(_onLoadMaterialRequestDetails);
    on<DownloadMaterialRequestPDF>(_onDownloadMaterialRequestPDF);
  }

  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
  }

  Future<void> _fetchRequests({
    required Emitter<MaterialRequestState> emit,
    String? project,
    String? search,
    String? status,
    String? materialRequestType,
  }) async {
    final activeProject = project ?? state.project;
    emit(
      state.copyWith(
        status: MaterialRequestStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        project: activeProject,
      ),
    );

    final result = await getMaterialRequests(
      page: 1,
      search: search ?? state.searchQuery,
      status: status ?? state.filterStatus,
      project: activeProject,
      materialRequestType: materialRequestType ?? state.materialRequestType,
      requiredByDateRange: state.requiredByDateRange,
      transactionDateRange: state.transactionDateRange,
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

  Future<void> _onLoadMaterialRequests(
    LoadMaterialRequests event,
    Emitter<MaterialRequestState> emit,
  ) async {
    await _fetchRequests(
      emit: emit,
      project: event.project,
    );
  }

  Future<void> _onSearchChanged(
    SearchChanged event,
    Emitter<MaterialRequestState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    
    final completer = Completer<void>();
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) {
        add(LoadMaterialRequests(project: state.project));
      }
      completer.complete();
    });
    
    await completer.future;
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<MaterialRequestState> emit,
  ) async {
    final clear = event.status == null &&
        event.materialRequestType == null &&
        event.requiredByDateRange == null &&
        event.transactionDateRange == null;
        
    emit(state.copyWith(
      filterStatus: event.status,
      materialRequestType: event.materialRequestType,
      requiredByDateRange: event.requiredByDateRange,
      transactionDateRange: event.transactionDateRange,
      clearFilters: clear,
    ));

    await _fetchRequests(
      emit: emit,
      project: state.project,
    );
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
    final result = await getMaterialRequests(
      page: nextPage,
      search: state.searchQuery,
      status: state.filterStatus,
      project: state.project,
      materialRequestType: state.materialRequestType,
      requiredByDateRange: state.requiredByDateRange,
      transactionDateRange: state.transactionDateRange,
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

    final result = await getMaterialRequestDetails(event.name);

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

  Future<void> _onDownloadMaterialRequestPDF(
    DownloadMaterialRequestPDF event,
    Emitter<MaterialRequestState> emit,
  ) async {
    emit(state.copyWith(pdfStatus: MaterialRequestStatus.loading, pdfPath: null));

    final result = await downloadPDF(event.name);

    result.fold(
      (failure) => emit(
        state.copyWith(
          pdfStatus: MaterialRequestStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (path) => emit(
        state.copyWith(
          pdfStatus: MaterialRequestStatus.success,
          pdfPath: path,
        ),
      ),
    );
  }
}
