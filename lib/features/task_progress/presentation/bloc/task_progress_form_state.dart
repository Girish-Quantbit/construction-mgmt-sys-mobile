import 'package:equatable/equatable.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';

enum TaskProgressFormStatus {
  initial,
  loading,
  loadSuccess,
  loadFailure,
  saving,
  saveSuccess,
  saveFailure,
}

class TaskProgressFormState extends Equatable {
  final TaskProgressFormStatus status;
  final Map<String, dynamic>? documentData;
  final DocTypeMeta? meta;
  final String? baseUrl;
  final String? savedName;
  final String? error;

  const TaskProgressFormState({
    this.status = TaskProgressFormStatus.initial,
    this.documentData,
    this.meta,
    this.baseUrl,
    this.savedName,
    this.error,
  });

  TaskProgressFormState copyWith({
    TaskProgressFormStatus? status,
    Map<String, dynamic>? documentData,
    DocTypeMeta? meta,
    String? baseUrl,
    String? savedName,
    String? error,
  }) {
    return TaskProgressFormState(
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
