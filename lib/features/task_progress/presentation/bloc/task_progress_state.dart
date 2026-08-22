import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task_progress.dart';

abstract class TaskProgressState extends Equatable {
  const TaskProgressState();

  @override
  List<Object?> get props => [];
}

class TaskProgressInitial extends TaskProgressState {}

class TaskProgressLoading extends TaskProgressState {}

class TaskProgressLoaded extends TaskProgressState {
  final List<TaskProgress> progressList;

  const TaskProgressLoaded(this.progressList);

  @override
  List<Object?> get props => [progressList];
}

enum TaskProgressPdfStatus { initial, downloading, success, failure }

class TaskProgressDetailLoaded extends TaskProgressState {
  final TaskProgress taskProgress;
  final String? baseUrl;
  final TaskProgressPdfStatus pdfStatus;
  final Uint8List? pdfBytes;
  final String? pdfEntryName;
  final String? pdfError;

  const TaskProgressDetailLoaded(
    this.taskProgress, {
    this.baseUrl,
    this.pdfStatus = TaskProgressPdfStatus.initial,
    this.pdfBytes,
    this.pdfEntryName,
    this.pdfError,
  });

  TaskProgressDetailLoaded copyWith({
    TaskProgress? taskProgress,
    String? baseUrl,
    TaskProgressPdfStatus? pdfStatus,
    Uint8List? pdfBytes,
    String? pdfEntryName,
    String? pdfError,
  }) {
    return TaskProgressDetailLoaded(
      taskProgress ?? this.taskProgress,
      baseUrl: baseUrl ?? this.baseUrl,
      pdfStatus: pdfStatus ?? this.pdfStatus,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      pdfEntryName: pdfEntryName ?? this.pdfEntryName,
      pdfError: pdfError ?? this.pdfError,
    );
  }

  @override
  List<Object?> get props => [taskProgress, baseUrl, pdfStatus, pdfBytes, pdfEntryName, pdfError];
}

class TaskProgressError extends TaskProgressState {
  final String message;

  const TaskProgressError(this.message);

  @override
  List<Object?> get props => [message];
}
