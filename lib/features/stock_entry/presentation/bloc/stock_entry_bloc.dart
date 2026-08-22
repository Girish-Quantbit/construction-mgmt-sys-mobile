import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_stock_entries.dart';
import '../../domain/usecases/get_stock_entry_details.dart';
import '../../domain/usecases/download_stock_entry_pdf.dart';
import 'stock_entry_event.dart';
import 'stock_entry_state.dart';

class StockEntryBloc extends Bloc<StockEntryEvent, StockEntryState> {
  final GetStockEntries getStockEntries;
  final GetStockEntryDetails getStockEntryDetails;
  final DownloadStockEntryPdf downloadStockEntryPdf;

  StockEntryBloc({
    required this.getStockEntries,
    required this.getStockEntryDetails,
    required this.downloadStockEntryPdf,
  }) : super(const StockEntryState()) {
    on<LoadStockEntries>(_onLoadStockEntries);
    on<LoadStockEntryDetails>(_onLoadStockEntryDetails);
    on<DownloadStockEntryPdfEvent>(_onDownloadPdf);
  }

  Future<void> _onLoadStockEntries(
    LoadStockEntries event,
    Emitter<StockEntryState> emit,
  ) async {
    final project = event.project ?? state.project;
    if (event.isRefresh) {
      emit(state.copyWith(
        listStatus: StockEntryStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        entries: [],
        project: project,
      ));
    } else if (state.hasReachedMax) {
      return;
    } else {
      emit(state.copyWith(
        listStatus: StockEntryStatus.loading,
        project: project,
      ));
    }

    final result = await getStockEntries(
      page: state.currentPage,
      status: event.status,
      search: event.search,
      stockEntryType: event.stockEntryType,
      project: project,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        listStatus: StockEntryStatus.failure,
        errorMessage: failure.message,
      )),
      (newEntries) {
        final allEntries = List.from(state.entries)..addAll(newEntries);
        emit(state.copyWith(
          listStatus: StockEntryStatus.success,
          entries: allEntries.cast(),
          hasReachedMax: newEntries.length < 20,
          currentPage: state.currentPage + 1,
        ));
      },
    );
  }

  Future<void> _onLoadStockEntryDetails(
    LoadStockEntryDetails event,
    Emitter<StockEntryState> emit,
  ) async {
    emit(state.copyWith(detailStatus: StockEntryStatus.loading));

    final result = await getStockEntryDetails(event.name);

    result.fold(
      (failure) => emit(state.copyWith(
        detailStatus: StockEntryStatus.failure,
        errorMessage: failure.message,
      )),
      (entry) => emit(state.copyWith(
        detailStatus: StockEntryStatus.success,
        selectedEntry: entry,
      )),
    );
  }

  Future<void> _onDownloadPdf(
    DownloadStockEntryPdfEvent event,
    Emitter<StockEntryState> emit,
  ) async {
    emit(state.copyWith(
      pdfStatus: StockEntryPdfStatus.downloading,
      pdfEntryName: event.entryName,
    ));

    final result = await downloadStockEntryPdf(event.entryName);

    result.fold(
      (failure) => emit(state.copyWith(
        pdfStatus: StockEntryPdfStatus.failure,
        errorMessage: failure.message,
      )),
      (bytes) => emit(state.copyWith(
        pdfStatus: StockEntryPdfStatus.success,
        pdfBytes: bytes,
        pdfEntryName: event.entryName,
      )),
    );
  }
}
