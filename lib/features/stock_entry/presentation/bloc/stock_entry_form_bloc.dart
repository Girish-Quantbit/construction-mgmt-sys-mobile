import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/load_stock_entry_document.dart';
import '../../domain/usecases/save_stock_entry_document.dart';
import '../../domain/usecases/get_stock_entry_base_url.dart';
import 'stock_entry_form_event.dart';
import 'stock_entry_form_state.dart';

class StockEntryFormBloc
    extends Bloc<StockEntryFormEvent, StockEntryFormState> {
  final LoadStockEntryDocument loadStockEntryDocument;
  final SaveStockEntryDocument saveStockEntryDocument;
  final GetStockEntryBaseUrl getStockEntryBaseUrl;

  StockEntryFormBloc({
    required this.loadStockEntryDocument,
    required this.saveStockEntryDocument,
    required this.getStockEntryBaseUrl,
  }) : super(const StockEntryFormState()) {
    on<InitializeStockEntryFormEvent>(_onInitialize);
    on<SaveStockEntryFormEvent>(_onSave);
  }

  Future<void> _onInitialize(
    InitializeStockEntryFormEvent event,
    Emitter<StockEntryFormState> emit,
  ) async {
    emit(state.copyWith(status: StockEntryFormStatus.loading));

    final baseUrl = getStockEntryBaseUrl();

    final result = await loadStockEntryDocument(event.entryName);
    result.fold(
      (failure) => emit(state.copyWith(
        status: StockEntryFormStatus.loadFailure,
        error: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: StockEntryFormStatus.loadSuccess,
        documentData: data, // null = new entry, non-null = edit
        baseUrl: baseUrl,
      )),
    );
  }

  Future<void> _onSave(
    SaveStockEntryFormEvent event,
    Emitter<StockEntryFormState> emit,
  ) async {
    emit(state.copyWith(status: StockEntryFormStatus.saving));

    final result = await saveStockEntryDocument(
      existingServerId: event.existingServerId,
      payload: event.payload,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: StockEntryFormStatus.saveFailure,
        error: failure.message,
      )),
      (savedName) => emit(state.copyWith(
        status: StockEntryFormStatus.saveSuccess,
        savedName: savedName,
      )),
    );
  }
}
