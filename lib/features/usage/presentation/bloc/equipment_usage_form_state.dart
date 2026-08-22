import 'package:equatable/equatable.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';

enum EquipmentUsageFormStatus {
  initial,
  loading,
  loadSuccess,
  loadFailure,
  saving,
  saveSuccess,
  saveFailure,
}

class EquipmentUsageFormState extends Equatable {
  final EquipmentUsageFormStatus status;
  final Map<String, dynamic>? documentData;
  final DocTypeMeta? meta;
  final String? baseUrl;
  final String? savedName;
  final String? error;

  const EquipmentUsageFormState({
    this.status = EquipmentUsageFormStatus.initial,
    this.documentData,
    this.meta,
    this.baseUrl,
    this.savedName,
    this.error,
  });

  EquipmentUsageFormState copyWith({
    EquipmentUsageFormStatus? status,
    Map<String, dynamic>? documentData,
    DocTypeMeta? meta,
    String? baseUrl,
    String? savedName,
    String? error,
  }) {
    return EquipmentUsageFormState(
      status: status ?? this.status,
      documentData: documentData ?? this.documentData,
      meta: meta ?? this.meta,
      baseUrl: baseUrl ?? this.baseUrl,
      savedName: savedName ?? this.savedName,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, documentData, meta, baseUrl, savedName, error];
}
