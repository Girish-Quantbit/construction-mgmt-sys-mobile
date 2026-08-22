import 'package:equatable/equatable.dart';

abstract class ApprovalsEvent extends Equatable {
  const ApprovalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadApprovals extends ApprovalsEvent {
  final String? project;

  const LoadApprovals({this.project});

  @override
  List<Object?> get props => [project];
}

class ChangeApprovalsFilter extends ApprovalsEvent {
  final String filter;

  const ChangeApprovalsFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class RefreshApprovals extends ApprovalsEvent {
  const RefreshApprovals();
}
