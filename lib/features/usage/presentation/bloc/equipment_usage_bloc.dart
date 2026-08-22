import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_equipment_usages.dart';
import '../../domain/usecases/get_equipment_usage_details.dart';
import '../../domain/usecases/download_equipment_usage_pdf.dart';
import '../../domain/usecases/get_equipment_usage_base_url.dart';
import 'equipment_usage_event.dart';
import 'equipment_usage_state.dart';

class EquipmentUsageBloc extends Bloc<EquipmentUsageEvent, EquipmentUsageState> {
  final GetEquipmentUsages getEquipmentUsages;
  final GetEquipmentUsageDetails getEquipmentUsageDetails;
  final DownloadEquipmentUsagePdf downloadEquipmentUsagePdf;
  final GetEquipmentUsageBaseUrl getEquipmentUsageBaseUrl;

  EquipmentUsageBloc({
    required this.getEquipmentUsages,
    required this.getEquipmentUsageDetails,
    required this.downloadEquipmentUsagePdf,
    required this.getEquipmentUsageBaseUrl,
  }) : super(const EquipmentUsageState()) {
    on<LoadEquipmentUsages>(_onLoadEquipmentUsages);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<LoadMoreEquipmentUsages>(_onLoadMoreEquipmentUsages);
    on<LoadEquipmentUsageDetails>(_onLoadEquipmentUsageDetails);
    on<DownloadEquipmentUsagePdfEvent>(_onDownloadPdf);
  }

  Future<void> _onLoadEquipmentUsages(
    LoadEquipmentUsages event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    final activeProject = event.project ?? state.project;
    emit(
      state.copyWith(
        status: EquipmentUsageStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        project: activeProject,
      ),
    );

    final result = await getEquipmentUsages(
      page: 1,
      search: state.searchQuery,
      status: state.filterStatus,
      fromDate: state.filterFromDate,
      toDate: state.filterToDate,
      project: activeProject,
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
          hasReachedMax: usages.length < 20,
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(
    SearchChanged event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.search));
    add(LoadEquipmentUsages(project: state.project));
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    emit(state.copyWith(
      filterStatus: event.status,
      filterFromDate: event.fromDate,
      filterToDate: event.toDate,
    ));
    add(LoadEquipmentUsages(project: state.project));
  }

  Future<void> _onLoadMoreEquipmentUsages(
    LoadMoreEquipmentUsages event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.status == EquipmentUsageStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: EquipmentUsageStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final result = await getEquipmentUsages(
      page: nextPage,
      search: state.searchQuery,
      status: state.filterStatus,
      fromDate: state.filterFromDate,
      toDate: state.filterToDate,
      project: state.project,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EquipmentUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (newUsages) => emit(
        state.copyWith(
          status: EquipmentUsageStatus.success,
          usages: List.of(state.usages)..addAll(newUsages),
          currentPage: nextPage,
          hasReachedMax: newUsages.length < 20,
        ),
      ),
    );
  }

  Future<void> _onLoadEquipmentUsageDetails(
    LoadEquipmentUsageDetails event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    emit(state.copyWith(status: EquipmentUsageStatus.loading));
    final result = await getEquipmentUsageDetails(event.name);
    final baseUrl = getEquipmentUsageBaseUrl();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EquipmentUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (usage) => emit(
        state.copyWith(
          status: EquipmentUsageStatus.success,
          selectedUsage: usage,
          baseUrl: baseUrl,
        ),
      ),
    );
  }

  Future<void> _onDownloadPdf(
    DownloadEquipmentUsagePdfEvent event,
    Emitter<EquipmentUsageState> emit,
  ) async {
    emit(state.copyWith(pdfStatus: EquipmentUsagePdfStatus.downloading));
    final result = await downloadEquipmentUsagePdf(event.entryName);
    result.fold(
      (failure) => emit(state.copyWith(
        pdfStatus: EquipmentUsagePdfStatus.failure,
        pdfError: failure.message,
      )),
      (bytes) => emit(state.copyWith(
        pdfStatus: EquipmentUsagePdfStatus.success,
        pdfBytes: bytes,
        pdfEntryName: event.entryName,
      )),
    );
  }
}
