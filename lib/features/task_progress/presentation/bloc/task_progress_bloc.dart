import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_task_progresses.dart';
import '../../domain/usecases/get_task_progress_details.dart';
import '../../domain/usecases/download_task_progress_pdf.dart';
import '../../domain/usecases/get_task_progress_base_url.dart';
import 'task_progress_event.dart';
import 'task_progress_state.dart';

class TaskProgressBloc extends Bloc<TaskProgressEvent, TaskProgressState> {
  final GetTaskProgresses getTaskProgresses;
  final GetTaskProgressDetails getTaskProgressDetails;
  final DownloadTaskProgressPdf downloadTaskProgressPdf;
  final GetTaskProgressBaseUrl getTaskProgressBaseUrl;

  TaskProgressBloc({
    required this.getTaskProgresses,
    required this.getTaskProgressDetails,
    required this.downloadTaskProgressPdf,
    required this.getTaskProgressBaseUrl,
  }) : super(TaskProgressInitial()) {
    
    on<GetTaskProgressesRequested>((event, emit) async {
      emit(TaskProgressLoading());
      final result = await getTaskProgresses(
        project: event.project,
        search: event.search,
      );
      result.fold(
        (failure) => emit(TaskProgressError(failure.message)),
        (progressList) => emit(TaskProgressLoaded(progressList)),
      );
    });

    on<GetTaskProgressDetailsRequested>((event, emit) async {
      emit(TaskProgressLoading());
      final result = await getTaskProgressDetails(event.name);
      final baseUrl = getTaskProgressBaseUrl();
      result.fold(
        (failure) => emit(TaskProgressError(failure.message)),
        (taskProgress) => emit(TaskProgressDetailLoaded(
          taskProgress,
          baseUrl: baseUrl,
        )),
      );
    });

    on<DownloadTaskProgressPdfEvent>((event, emit) async {
      final currentState = state;
      if (currentState is TaskProgressDetailLoaded) {
        emit(currentState.copyWith(pdfStatus: TaskProgressPdfStatus.downloading));
        final result = await downloadTaskProgressPdf(event.entryName);
        result.fold(
          (failure) => emit(currentState.copyWith(
            pdfStatus: TaskProgressPdfStatus.failure,
            pdfError: failure.message,
          )),
          (bytes) => emit(currentState.copyWith(
            pdfStatus: TaskProgressPdfStatus.success,
            pdfBytes: bytes,
            pdfEntryName: event.entryName,
          )),
        );
      }
    });
  }
}
