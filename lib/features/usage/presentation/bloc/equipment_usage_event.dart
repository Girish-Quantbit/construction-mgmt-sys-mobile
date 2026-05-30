import 'package:equatable/equatable.dart';

abstract class EquipmentUsageEvent extends Equatable {
  const EquipmentUsageEvent();

  @override
  List<Object?> get props => [];
}

class LoadEquipmentUsages extends EquipmentUsageEvent {
  final bool isRefresh;
  const LoadEquipmentUsages({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class LoadMoreEquipmentUsages extends EquipmentUsageEvent {}

class LoadEquipmentUsageDetails extends EquipmentUsageEvent {
  final String name;
  const LoadEquipmentUsageDetails(this.name);

  @override
  List<Object?> get props => [name];
}

class SearchChanged extends EquipmentUsageEvent {
  final String search;
  const SearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

class FilterChanged extends EquipmentUsageEvent {
  final String? status;
  const FilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}
