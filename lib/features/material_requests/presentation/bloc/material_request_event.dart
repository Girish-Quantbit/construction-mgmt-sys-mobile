import 'package:flutter/material.dart';
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
  final String? materialRequestType;
  final DateTimeRange? requiredByDateRange;
  final DateTimeRange? transactionDateRange;

  const FilterChanged({
    this.status,
    this.materialRequestType,
    this.requiredByDateRange,
    this.transactionDateRange,
  });

  @override
  List<Object?> get props => [
        status,
        materialRequestType,
        requiredByDateRange,
        transactionDateRange,
      ];
}

class LoadMoreMaterialRequests extends MaterialRequestEvent {}

class LoadMaterialRequestDetails extends MaterialRequestEvent {
  final String name;
  const LoadMaterialRequestDetails(this.name);

  @override
  List<Object?> get props => [name];
}

class DownloadMaterialRequestPDF extends MaterialRequestEvent {
  final String name;
  const DownloadMaterialRequestPDF(this.name);

  @override
  List<Object?> get props => [name];
}

