import 'package:equatable/equatable.dart';

enum StockEntryFormStatus {
  initial,
  loading,
  loadSuccess,
  loadFailure,
  saving,
  saveSuccess,
  saveFailure,
}

class StockEntryFormState extends Equatable {
  final StockEntryFormStatus status;
  final Map<String, dynamic>? documentData;
  final String? baseUrl;
  final String? savedName;
  final String? error;

  const StockEntryFormState({
    this.status = StockEntryFormStatus.initial,
    this.documentData,
    this.baseUrl,
    this.savedName,
    this.error,
  });

  StockEntryFormState copyWith({
    StockEntryFormStatus? status,
    Map<String, dynamic>? documentData,
    String? baseUrl,
    String? savedName,
    String? error,
  }) {
    return StockEntryFormState(
      status: status ?? this.status,
      documentData: documentData ?? this.documentData,
      baseUrl: baseUrl ?? this.baseUrl,
      savedName: savedName ?? this.savedName,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, documentData, baseUrl, savedName, error];
}
