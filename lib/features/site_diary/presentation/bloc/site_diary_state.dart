import 'package:equatable/equatable.dart';
import '../../domain/entities/site_diary.dart';

enum SiteDiaryStatus { initial, loading, success, failure }

class SiteDiaryState extends Equatable {
  final SiteDiaryStatus status;
  final SiteDiaryStatus detailStatus;
  final List<SiteDiary> diaries;
  final SiteDiary? selectedDiary;
  final bool hasReachedMax;
  final String? errorMessage;
  final String searchQuery;
  final String? filterStatus;
  final int page;

  const SiteDiaryState({
    this.status = SiteDiaryStatus.initial,
    this.detailStatus = SiteDiaryStatus.initial,
    this.diaries = const [],
    this.selectedDiary,
    this.hasReachedMax = false,
    this.errorMessage,
    this.searchQuery = '',
    this.filterStatus,
    this.page = 1,
  });

  SiteDiaryState copyWith({
    SiteDiaryStatus? status,
    SiteDiaryStatus? detailStatus,
    List<SiteDiary>? diaries,
    SiteDiary? selectedDiary,
    bool? hasReachedMax,
    String? errorMessage,
    String? searchQuery,
    String? filterStatus,
    int? page,
  }) {
    return SiteDiaryState(
      status: status ?? this.status,
      detailStatus: detailStatus ?? this.detailStatus,
      diaries: diaries ?? this.diaries,
      selectedDiary: selectedDiary ?? this.selectedDiary,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [
    status,
    detailStatus,
    diaries,
    selectedDiary,
    hasReachedMax,
    errorMessage,
    searchQuery,
    filterStatus,
    page,
  ];
}
