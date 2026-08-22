import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_equipment_usage_meta.dart';
import '../../domain/usecases/load_equipment_usage_document.dart';
import '../../domain/usecases/save_equipment_usage_document.dart';
import '../../domain/usecases/get_equipment_usage_base_url.dart';
import 'equipment_usage_form_event.dart';
import 'equipment_usage_form_state.dart';

class EquipmentUsageFormBloc
    extends Bloc<EquipmentUsageFormEvent, EquipmentUsageFormState> {
  final GetEquipmentUsageMeta getMeta;
  final LoadEquipmentUsageDocument loadDocument;
  final SaveEquipmentUsageDocument saveDocument;
  final GetEquipmentUsageBaseUrl getBaseUrl;

  EquipmentUsageFormBloc({
    required this.getMeta,
    required this.loadDocument,
    required this.saveDocument,
    required this.getBaseUrl,
  }) : super(const EquipmentUsageFormState()) {
    on<InitializeEquipmentUsageFormEvent>(_onInitialize);
    on<SaveEquipmentUsageFormEvent>(_onSave);
  }

  Future<void> _onInitialize(
    InitializeEquipmentUsageFormEvent event,
    Emitter<EquipmentUsageFormState> emit,
  ) async {
    emit(state.copyWith(status: EquipmentUsageFormStatus.loading));

    final metaResult = await getMeta();
    final docResult = await loadDocument(event.usageName);
    final url = getBaseUrl();

    metaResult.fold(
      (failure) => emit(state.copyWith(
        status: EquipmentUsageFormStatus.loadFailure,
        error: failure.message,
      )),
      (meta) {
        docResult.fold(
          (failure) => emit(state.copyWith(
            status: EquipmentUsageFormStatus.loadFailure,
            error: failure.message,
          )),
          (docData) => emit(state.copyWith(
            status: EquipmentUsageFormStatus.loadSuccess,
            meta: meta,
            documentData: docData,
            baseUrl: url,
          )),
        );
      },
    );
  }

  Future<void> _onSave(
    SaveEquipmentUsageFormEvent event,
    Emitter<EquipmentUsageFormState> emit,
  ) async {
    emit(state.copyWith(status: EquipmentUsageFormStatus.saving));

    final result = await saveDocument(
      existingServerId: event.existingServerId,
      payload: event.payload,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: EquipmentUsageFormStatus.saveFailure,
        error: failure.message,
      )),
      (serverId) => emit(state.copyWith(
        status: EquipmentUsageFormStatus.saveSuccess,
        savedName: serverId,
      )),
    );
  }
}
