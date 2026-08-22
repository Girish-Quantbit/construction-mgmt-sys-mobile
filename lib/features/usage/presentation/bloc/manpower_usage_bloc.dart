import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_manpower_usages.dart';
import '../../domain/usecases/get_manpower_usage_details.dart';
import '../../domain/usecases/download_manpower_usage_pdf.dart';
import '../../domain/usecases/get_manpower_usage_base_url.dart';
import 'manpower_usage_event.dart';
import 'manpower_usage_state.dart';

class ManpowerUsageBloc extends Bloc<ManpowerUsageEvent, ManpowerUsageState> {
  final GetManpowerUsages getManpowerUsages;
  final GetManpowerUsageDetails getManpowerUsageDetails;
  final DownloadManpowerUsagePdf downloadManpowerUsagePdf;
  final GetManpowerUsageBaseUrl getManpowerUsageBaseUrl;

  ManpowerUsageBloc({
    required this.getManpowerUsages,
    required this.getManpowerUsageDetails,
    required this.downloadManpowerUsagePdf,
    required this.getManpowerUsageBaseUrl,
  }) : super(const ManpowerUsageState()) {
    on<LoadManpowerUsages>(_onLoadManpowerUsages);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<LoadMoreManpowerUsages>(_onLoadMoreManpowerUsages);
    on<LoadManpowerUsageDetails>(_onLoadManpowerUsageDetails);
    on<DownloadManpowerUsagePdfEvent>(_onDownloadPdf);
  }

  Future<void> _onLoadManpowerUsages(
    LoadManpowerUsages event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    final activeProject = event.project ?? state.project;
    emit(
      state.copyWith(
        status: ManpowerUsageStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        project: activeProject,
      ),
    );

    final result = await getManpowerUsages(
      page: 1,
      search: state.searchQuery,
      status: state.filterStatus,
      project: activeProject,
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
    add(LoadManpowerUsages(project: state.project));
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    emit(state.copyWith(filterStatus: event.status));
    add(LoadManpowerUsages(project: state.project));
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
    final result = await getManpowerUsages(
      page: nextPage,
      search: state.searchQuery,
      status: state.filterStatus,
      project: state.project,
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
    emit(state.copyWith(status: ManpowerUsageStatus.loading));
    final result = await getManpowerUsageDetails(event.name);
    final baseUrl = getManpowerUsageBaseUrl();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ManpowerUsageStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (usage) => emit(
        state.copyWith(
          status: ManpowerUsageStatus.success,
          selectedUsage: usage,
          baseUrl: baseUrl,
        ),
      ),
    );
  }

  Future<void> _onDownloadPdf(
    DownloadManpowerUsagePdfEvent event,
    Emitter<ManpowerUsageState> emit,
  ) async {
    emit(state.copyWith(pdfStatus: ManpowerUsagePdfStatus.downloading));
    final result = await downloadManpowerUsagePdf(event.entryName);
    result.fold(
      (failure) => emit(state.copyWith(
        pdfStatus: ManpowerUsagePdfStatus.failure,
        pdfError: failure.message,
      )),
      (bytes) => emit(state.copyWith(
        pdfStatus: ManpowerUsagePdfStatus.success,
        pdfBytes: bytes,
        pdfEntryName: event.entryName,
      )),
    );
  }
}
