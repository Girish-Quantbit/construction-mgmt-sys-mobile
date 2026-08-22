import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/approval_item.dart';
import '../../domain/usecases/get_approvals.dart';
import 'approvals_event.dart';
import 'approvals_state.dart';

class ApprovalsBloc extends Bloc<ApprovalsEvent, ApprovalsState> {
  final GetApprovals getApprovals;

  ApprovalsBloc({
    required this.getApprovals,
  }) : super(const ApprovalsState()) {
    on<LoadApprovals>(_onLoadApprovals);
    on<ChangeApprovalsFilter>(_onChangeApprovalsFilter);
    on<RefreshApprovals>(_onRefreshApprovals);
  }

  Future<void> _onLoadApprovals(
    LoadApprovals event,
    Emitter<ApprovalsState> emit,
  ) async {
    final activeProject = event.project ?? state.project;
    emit(state.copyWith(
      status: ApprovalsStatus.loading,
      project: activeProject,
    ));

    final result = await getApprovals(project: activeProject);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ApprovalsStatus.failure,
        errorMessage: failure.message,
      )),
      (allItems) => _emitFilteredState(allItems, emit),
    );
  }

  Future<void> _onChangeApprovalsFilter(
    ChangeApprovalsFilter event,
    Emitter<ApprovalsState> emit,
  ) async {
    // Client-side instant filter switch (no network calls!)
    emit(state.copyWith(
      selectedFilter: event.filter,
    ));
  }

  Future<void> _onRefreshApprovals(
    RefreshApprovals event,
    Emitter<ApprovalsState> emit,
  ) async {
    final result = await getApprovals(project: state.project);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ApprovalsStatus.failure,
        errorMessage: failure.message,
      )),
      (allItems) => _emitFilteredState(allItems, emit),
    );
  }

  void _emitFilteredState(List<ApprovalItem> allItems, Emitter<ApprovalsState> emit) {
    // 1. Group items client-side
    final List<ApprovalItem> pending = [];
    final List<ApprovalItem> approved = [];
    final List<ApprovalItem> rejected = [];

    final pendingPOStatuses = ['to bill', 'to receive', 'to receive & bill', 'to receive and bill'];
    final approvedMRStatuses = ['submitted', 'ordered', 'issued', 'transferred', 'received', 'partially ordered'];
    final approvedPOStatuses = ['completed', 'closed'];

    for (final item in allItems) {
      final doctype = item.doctype;
      final status = item.status;
      final lowerStatus = status.toLowerCase();

      if (doctype == 'Material Request') {
        if (lowerStatus == 'pending') {
          pending.add(item);
        } else if (approvedMRStatuses.contains(lowerStatus)) {
          approved.add(item);
        } else if (lowerStatus == 'cancelled') {
          rejected.add(item);
        }
      } else if (doctype == 'Purchase Order') {
        if (pendingPOStatuses.contains(lowerStatus)) {
          pending.add(item);
        } else if (approvedPOStatuses.contains(lowerStatus)) {
          approved.add(item);
        } else if (lowerStatus == 'cancelled') {
          rejected.add(item);
        }
      }
    }

    emit(state.copyWith(
      status: ApprovalsStatus.success,
      pendingItems: pending,
      approvedItems: approved,
      rejectedItems: rejected,
      pendingCount: pending.length,
      approvedCount: approved.length,
      rejectedCount: rejected.length,
    ));
  }
}
