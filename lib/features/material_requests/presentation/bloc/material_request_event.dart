import 'package:equatable/equatable.dart';

abstract class MaterialRequestEvent extends Equatable {
  const MaterialRequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadMaterialRequests extends MaterialRequestEvent {
  final bool isRefresh;
  final String? project;
  const LoadMaterialRequests({this.isRefresh = false, this.project});

  @override
  List<Object?> get props => [isRefresh, project];
}

class SearchChanged extends MaterialRequestEvent {
  final String query;
  const SearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterChanged extends MaterialRequestEvent {
  final String? status;
  const FilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadMoreMaterialRequests extends MaterialRequestEvent {}

class LoadMaterialRequestDetails extends MaterialRequestEvent {
  final String name;
  const LoadMaterialRequestDetails(this.name);

  @override
  List<Object?> get props => [name];
}
