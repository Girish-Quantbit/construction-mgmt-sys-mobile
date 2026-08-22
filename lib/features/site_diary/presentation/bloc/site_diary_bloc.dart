import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_site_diaries.dart';
import '../../domain/usecases/get_site_diary_details.dart';
import 'site_diary_event.dart';
import 'site_diary_state.dart';

class SiteDiaryBloc extends Bloc<SiteDiaryEvent, SiteDiaryState> {
  final GetSiteDiaries getSiteDiaries;
  final GetSiteDiaryDetails getSiteDiaryDetails;

  SiteDiaryBloc({
    required this.getSiteDiaries,
    required this.getSiteDiaryDetails,
  }) : super(const SiteDiaryState()) {
    on<LoadSiteDiaries>(_onLoadSiteDiaries);
    on<LoadMoreSiteDiaries>(_onLoadMoreSiteDiaries);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<LoadSiteDiaryDetails>(_onLoadSiteDiaryDetails);
  }

  Future<void> _onLoadSiteDiaryDetails(
    LoadSiteDiaryDetails event,
    Emitter<SiteDiaryState> emit,
  ) async {
    emit(state.copyWith(detailStatus: SiteDiaryStatus.loading));

    final result = await getSiteDiaryDetails(event.name);

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: SiteDiaryStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (diary) => emit(
        state.copyWith(
          detailStatus: SiteDiaryStatus.success,
          selectedDiary: diary,
        ),
      ),
    );
  }

  Future<void> _onLoadSiteDiaries(
    LoadSiteDiaries event,
    Emitter<SiteDiaryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SiteDiaryStatus.loading,
        page: 1,
        hasReachedMax: false,
      ),
    );

    final result = await getSiteDiaries(
      page: 1,
      search: state.searchQuery,
      status: state.filterStatus,
      project: event.project,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SiteDiaryStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (diaries) => emit(
        state.copyWith(
          status: SiteDiaryStatus.success,
          diaries: diaries,
          hasReachedMax: diaries.length < 20,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreSiteDiaries(
    LoadMoreSiteDiaries event,
    Emitter<SiteDiaryState> emit,
  ) async {
    if (state.hasReachedMax) return;

    final nextPage = state.page + 1;
    final result = await getSiteDiaries(
      page: nextPage,
      search: state.searchQuery,
      status: state.filterStatus,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SiteDiaryStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (diaries) => emit(
        state.copyWith(
          status: SiteDiaryStatus.success,
          diaries: List.of(state.diaries)..addAll(diaries),
          page: nextPage,
          hasReachedMax: diaries.length < 20,
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(
    SearchChanged event,
    Emitter<SiteDiaryState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(const LoadSiteDiaries());
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<SiteDiaryState> emit,
  ) async {
    emit(state.copyWith(filterStatus: event.status));
    add(const LoadSiteDiaries());
  }
}
