import 'package:equatable/equatable.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';

enum SiteDiaryFormStatus {
  initial,
  loading,
  loadSuccess,
  loadFailure,
  processing, // for Get Details, upload, save
  saveSuccess,
  saveFailure,
  employeeNameLoaded,
}

class SiteDiaryFormState extends Equatable {
  final SiteDiaryFormStatus status;
  final String? error;
  final DocTypeMeta? meta;
  final Document? document;
  final bool? detailsFetched;
  final String? employeeName;
  final String? baseUrl;

  const SiteDiaryFormState({
    this.status = SiteDiaryFormStatus.initial,
    this.error,
    this.meta,
    this.document,
    this.detailsFetched,
    this.employeeName,
    this.baseUrl,
  });

  SiteDiaryFormState copyWith({
    SiteDiaryFormStatus? status,
    String? error,
    DocTypeMeta? meta,
    Document? document,
    bool? detailsFetched,
    String? employeeName,
    String? baseUrl,
  }) {
    return SiteDiaryFormState(
      status: status ?? this.status,
      error: error ?? this.error,
      meta: meta ?? this.meta,
      document: document ?? this.document,
      detailsFetched: detailsFetched ?? this.detailsFetched,
      employeeName: employeeName ?? this.employeeName,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  @override
  List<Object?> get props => [
    status,
    error,
    meta,
    document,
    detailsFetched,
    employeeName,
    baseUrl,
  ];
}
