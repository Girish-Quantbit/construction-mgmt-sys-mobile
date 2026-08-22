import 'package:equatable/equatable.dart';

abstract class EquipmentUsageEvent extends Equatable {
  const EquipmentUsageEvent();

  @override
  List<Object?> get props => [];
}

class LoadEquipmentUsages extends EquipmentUsageEvent {
  final bool isRefresh;
  final String? project;
  const LoadEquipmentUsages({this.isRefresh = false, this.project});

  @override
  List<Object?> get props => [isRefresh, project];
}

class LoadMoreEquipmentUsages extends EquipmentUsageEvent {}

class LoadEquipmentUsageDetails extends EquipmentUsageEvent {
  final String name;
  const LoadEquipmentUsageDetails(this.name);

  @override
  List<Object?> get props => [name];
}

class DownloadEquipmentUsagePdfEvent extends EquipmentUsageEvent {
  final String entryName;

  const DownloadEquipmentUsagePdfEvent(this.entryName);

  @override
  List<Object?> get props => [entryName];
}

class SearchChanged extends EquipmentUsageEvent {
  final String search;
  const SearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

class FilterChanged extends EquipmentUsageEvent {
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  const FilterChanged({this.status, this.fromDate, this.toDate});

  @override
  List<Object?> get props => [status, fromDate, toDate];
}
