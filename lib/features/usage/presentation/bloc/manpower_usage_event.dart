import 'package:equatable/equatable.dart';

abstract class ManpowerUsageEvent extends Equatable {
  const ManpowerUsageEvent();

  @override
  List<Object?> get props => [];
}

class LoadManpowerUsages extends ManpowerUsageEvent {
  final bool isRefresh;
  const LoadManpowerUsages({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class LoadMoreManpowerUsages extends ManpowerUsageEvent {}

class SearchChanged extends ManpowerUsageEvent {
  final String query;
  const SearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterChanged extends ManpowerUsageEvent {
  final String? status;
  const FilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadManpowerUsageDetails extends ManpowerUsageEvent {
  final String name;
  const LoadManpowerUsageDetails(this.name);

  @override
  List<Object?> get props => [name];
}
