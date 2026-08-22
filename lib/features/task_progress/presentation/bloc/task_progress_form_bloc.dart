import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_task_progress_meta.dart';
import '../../domain/usecases/load_task_progress_document.dart';
import '../../domain/usecases/save_task_progress_document.dart';
import '../../domain/usecases/upload_task_progress_file.dart';
import '../../domain/usecases/get_task_progress_base_url.dart';
import 'task_progress_form_event.dart';
import 'task_progress_form_state.dart';

class TaskProgressFormBloc
    extends Bloc<TaskProgressFormEvent, TaskProgressFormState> {
  final GetTaskProgressMeta getMeta;
  final LoadTaskProgressDocument loadDocument;
  final SaveTaskProgressDocument saveDocument;
  final UploadTaskProgressFile uploadFile;
  final GetTaskProgressBaseUrl getBaseUrl;

  TaskProgressFormBloc({
    required this.getMeta,
    required this.loadDocument,
    required this.saveDocument,
    required this.uploadFile,
    required this.getBaseUrl,
  }) : super(const TaskProgressFormState()) {
    on<InitializeTaskProgressFormEvent>(_onInitialize);
    on<SaveTaskProgressFormEvent>(_onSave);
  }

  Future<void> _onInitialize(
    InitializeTaskProgressFormEvent event,
    Emitter<TaskProgressFormState> emit,
  ) async {
    emit(state.copyWith(status: TaskProgressFormStatus.loading));

    final metaResult = await getMeta();
    final docResult = await loadDocument(event.progressName);
    final url = getBaseUrl();

    metaResult.fold(
      (failure) => emit(state.copyWith(
        status: TaskProgressFormStatus.loadFailure,
        error: failure.message,
      )),
      (meta) {
        docResult.fold(
          (failure) => emit(state.copyWith(
            status: TaskProgressFormStatus.loadFailure,
            error: failure.message,
          )),
          (docData) => emit(state.copyWith(
            status: TaskProgressFormStatus.loadSuccess,
            meta: meta,
            documentData: docData,
            baseUrl: url,
          )),
        );
      },
    );
  }

  Future<void> _onSave(
    SaveTaskProgressFormEvent event,
    Emitter<TaskProgressFormState> emit,
  ) async {
    emit(state.copyWith(status: TaskProgressFormStatus.saving));

    // Save document details first
    final saveResult = await saveDocument(
      existingServerId: event.existingServerId,
      payload: event.payload,
    );

    await saveResult.fold(
      (failure) async {
        emit(state.copyWith(
          status: TaskProgressFormStatus.saveFailure,
          error: failure.message,
        ));
      },
      (serverId) async {
        try {
          // Upload general parent-level files if any
          for (final path in event.parentImagesPaths) {
            await uploadFile(serverName: serverId, filePath: path);
          }

          // Upload per-row child files if any
          if (event.childImagesPaths.isNotEmpty) {
            // Need to fetch details to map row IDs
            final detailsResult = await loadDocument(serverId);
            await detailsResult.fold(
              (failure) => throw Exception(failure.message),
              (data) async {
                final List<dynamic> savedRows = data?['task_progress_details'] ?? [];
                
                // Map the child images upload
                for (final entry in event.childImagesPaths.entries) {
                  final itemIndex = entry.key;
                  final filePaths = entry.value;
                  if (itemIndex < savedRows.length) {
                    final rowName = savedRows[itemIndex]['name']?.toString();
                    if (rowName != null && rowName.isNotEmpty) {
                      for (final filePath in filePaths) {
                        await uploadFile(serverName: rowName, filePath: filePath);
                      }
                    }
                  }
                }
              },
            );
          }

          emit(state.copyWith(
            status: TaskProgressFormStatus.saveSuccess,
            savedName: serverId,
          ));
        } catch (e) {
          emit(state.copyWith(
            status: TaskProgressFormStatus.saveFailure,
            error: 'Failed to upload attachments: ${e.toString()}',
          ));
        }
      },
    );
  }
}
