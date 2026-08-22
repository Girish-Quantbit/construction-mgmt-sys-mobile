import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetTasksRequested extends TaskEvent {
  final String? project;
  GetTasksRequested({this.project});
  @override
  List<Object?> get props => [project];
}
