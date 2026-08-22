import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/purchase_receipt_repository.dart';
import 'purchase_receipt_event.dart';
import 'purchase_receipt_state.dart';

class PurchaseReceiptBloc
    extends Bloc<PurchaseReceiptEvent, PurchaseReceiptState> {
  final PurchaseReceiptRepository repository;

  PurchaseReceiptBloc({required this.repository})
      : super(const PurchaseReceiptState()) {
    on<LoadPurchaseReceipts>(_onLoadPurchaseReceipts);
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<SortChanged>(_onSortChanged);
    on<ApplyFilters>(_onApplyFilters);
    on<ClearFilters>(_onClearFilters);
    on<LoadMorePurchaseReceipts>(_onLoadMorePurchaseReceipts);
    on<LoadPurchaseReceiptDetails>(_onLoadPurchaseReceiptDetails);
    on<DownloadPurchaseReceiptPDF>(_onDownloadPurchaseReceiptPDF);
  }

  Future<void> _onLoadPurchaseReceipts(
    LoadPurchaseReceipts event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    final project = event.project ?? state.project;
    emit(
      state.copyWith(
        status: PurchaseReceiptStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        project: project,
      ),
    );

    final result = await repository.getPurchaseReceipts(
      page: 1,
      search: state.searchQuery,
      status: state.filterStatus,
      project: project,
      sortBy: state.sortBy,
      sortOrder: state.sortOrder,
      fromDate: state.filterFromDate,
      toDate: state.filterToDate,
      supplier: state.filterSupplier,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PurchaseReceiptStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (receipts) => emit(
        state.copyWith(
          status: PurchaseReceiptStatus.success,
          receipts: receipts,
          hasReachedMax: receipts.length < 20,
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(
    SearchChanged event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(LoadPurchaseReceipts(project: state.project));
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    emit(state.copyWith(filterStatus: event.status));
    add(LoadPurchaseReceipts(project: state.project));
  }

  Future<void> _onSortChanged(
    SortChanged event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    emit(state.copyWith(sortBy: event.sortBy, sortOrder: event.sortOrder));
    add(LoadPurchaseReceipts(project: state.project));
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    emit(state.copyWith(
      filterStatus: event.status,
      filterSupplier: event.supplier,
      filterFromDate: event.fromDate,
      filterToDate: event.toDate,
    ));
    add(LoadPurchaseReceipts(project: state.project));
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    emit(state.copyWith(clearFilters: true));
    add(LoadPurchaseReceipts(project: state.project));
  }

  Future<void> _onLoadMorePurchaseReceipts(
    LoadMorePurchaseReceipts event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.status == PurchaseReceiptStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: PurchaseReceiptStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final result = await repository.getPurchaseReceipts(
      page: nextPage,
      search: state.searchQuery,
      status: state.filterStatus,
      project: state.project,
      sortBy: state.sortBy,
      sortOrder: state.sortOrder,
      fromDate: state.filterFromDate,
      toDate: state.filterToDate,
      supplier: state.filterSupplier,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PurchaseReceiptStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (newReceipts) => emit(
        state.copyWith(
          status: PurchaseReceiptStatus.success,
          receipts: List.of(state.receipts)..addAll(newReceipts),
          currentPage: nextPage,
          hasReachedMax: newReceipts.length < 20,
        ),
      ),
    );
  }

  Future<void> _onLoadPurchaseReceiptDetails(
    LoadPurchaseReceiptDetails event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    emit(state.copyWith(detailStatus: PurchaseReceiptStatus.loading));

    final result = await repository.getPurchaseReceiptDetails(event.name);

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: PurchaseReceiptStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (receipt) => emit(
        state.copyWith(
          detailStatus: PurchaseReceiptStatus.success,
          selectedReceipt: receipt,
        ),
      ),
    );
  }

  Future<void> _onDownloadPurchaseReceiptPDF(
    DownloadPurchaseReceiptPDF event,
    Emitter<PurchaseReceiptState> emit,
  ) async {
    emit(state.copyWith(pdfStatus: PurchaseReceiptStatus.loading, pdfPath: null));

    final result = await repository.downloadPDF(event.name);

    result.fold(
      (failure) => emit(
        state.copyWith(
          pdfStatus: PurchaseReceiptStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (path) => emit(
        state.copyWith(
          pdfStatus: PurchaseReceiptStatus.success,
          pdfPath: path,
        ),
      ),
    );
  }
}
