import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_manpower_usage_meta.dart';
import '../../domain/usecases/load_manpower_usage_document.dart';
import '../../domain/usecases/save_manpower_usage_document.dart';
import '../../domain/usecases/get_manpower_usage_base_url.dart';
import 'manpower_usage_form_event.dart';
import 'manpower_usage_form_state.dart';

class ManpowerUsageFormBloc
    extends Bloc<ManpowerUsageFormEvent, ManpowerUsageFormState> {
  final GetManpowerUsageMeta getMeta;
  final LoadManpowerUsageDocument loadDocument;
  final SaveManpowerUsageDocument saveDocument;
  final GetManpowerUsageBaseUrl getBaseUrl;

  ManpowerUsageFormBloc({
    required this.getMeta,
    required this.loadDocument,
    required this.saveDocument,
    required this.getBaseUrl,
  }) : super(const ManpowerUsageFormState()) {
    on<InitializeManpowerUsageFormEvent>(_onInitialize);
    on<SaveManpowerUsageFormEvent>(_onSave);
  }

  Future<void> _onInitialize(
    InitializeManpowerUsageFormEvent event,
    Emitter<ManpowerUsageFormState> emit,
  ) async {
    emit(state.copyWith(status: ManpowerUsageFormStatus.loading));

    final metaResult = await getMeta();
    final docResult = await loadDocument(event.usageName);
    final url = getBaseUrl();

    metaResult.fold(
      (failure) => emit(state.copyWith(
        status: ManpowerUsageFormStatus.loadFailure,
        error: failure.message,
      )),
      (meta) {
        docResult.fold(
          (failure) => emit(state.copyWith(
            status: ManpowerUsageFormStatus.loadFailure,
            error: failure.message,
          )),
          (docData) => emit(state.copyWith(
            status: ManpowerUsageFormStatus.loadSuccess,
            meta: meta,
            documentData: docData,
            baseUrl: url,
          )),
        );
      },
    );
  }

  Future<void> _onSave(
    SaveManpowerUsageFormEvent event,
    Emitter<ManpowerUsageFormState> emit,
  ) async {
    emit(state.copyWith(status: ManpowerUsageFormStatus.saving));

    final result = await saveDocument(
      existingServerId: event.existingServerId,
      payload: event.payload,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ManpowerUsageFormStatus.saveFailure,
        error: failure.message,
      )),
      (serverId) => emit(state.copyWith(
        status: ManpowerUsageFormStatus.saveSuccess,
        savedName: serverId,
      )),
    );
  }
}
