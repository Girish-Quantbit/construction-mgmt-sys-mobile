import 'package:equatable/equatable.dart';

abstract class SiteDiaryEvent extends Equatable {
  const SiteDiaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadSiteDiaries extends SiteDiaryEvent {
  final bool isRefresh;
  final String? project;

  const LoadSiteDiaries({this.isRefresh = false, this.project});

  @override
  List<Object?> get props => [isRefresh, project];
}

class LoadMoreSiteDiaries extends SiteDiaryEvent {
  @override
  List<Object?> get props => [];
}

class SearchChanged extends SiteDiaryEvent {
  final String query;

  const SearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterChanged extends SiteDiaryEvent {
  final String? status;

  const FilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadSiteDiaryDetails extends SiteDiaryEvent {
  final String name;

  const LoadSiteDiaryDetails(this.name);

  @override
  List<Object?> get props => [name];
}
