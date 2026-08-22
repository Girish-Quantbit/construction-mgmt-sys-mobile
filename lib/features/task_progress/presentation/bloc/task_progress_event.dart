import 'package:equatable/equatable.dart';

abstract class TaskProgressEvent extends Equatable {
  const TaskProgressEvent();

  @override
  List<Object?> get props => [];
}

class GetTaskProgressesRequested extends TaskProgressEvent {
  final String? project;
  final String? search;

  const GetTaskProgressesRequested({this.project, this.search});

  @override
  List<Object?> get props => [project, search];
}

class GetTaskProgressDetailsRequested extends TaskProgressEvent {
  final String name;

  const GetTaskProgressDetailsRequested(this.name);

  @override
  List<Object?> get props => [name];
}

class DownloadTaskProgressPdfEvent extends TaskProgressEvent {
  final String entryName;

  const DownloadTaskProgressPdfEvent(this.entryName);

  @override
  List<Object?> get props => [entryName];
}

