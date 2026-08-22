import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_site_diary_meta.dart';
import '../../domain/usecases/load_site_diary_document.dart';
import '../../domain/usecases/call_site_diary_api.dart';
import '../../domain/usecases/upload_site_diary_file.dart';
import '../../domain/usecases/save_site_diary_document.dart';
import '../../domain/usecases/get_employee_name.dart';
import '../../domain/usecases/get_site_diary_base_url.dart';
import 'site_diary_form_event.dart';
import 'site_diary_form_state.dart';

class SiteDiaryFormBloc extends Bloc<SiteDiaryFormEvent, SiteDiaryFormState> {
  final GetSiteDiaryMeta getSiteDiaryMeta;
  final LoadSiteDiaryDocument loadSiteDiaryDocument;
  final CallSiteDiaryApi callSiteDiaryApi;
  final UploadSiteDiaryFile uploadSiteDiaryFile;
  final SaveSiteDiaryDocument saveSiteDiaryDocument;
  final GetEmployeeName getEmployeeName;
  final GetSiteDiaryBaseUrl getSiteDiaryBaseUrl;

  SiteDiaryFormBloc({
    required this.getSiteDiaryMeta,
    required this.loadSiteDiaryDocument,
    required this.callSiteDiaryApi,
    required this.uploadSiteDiaryFile,
    required this.saveSiteDiaryDocument,
    required this.getEmployeeName,
    required this.getSiteDiaryBaseUrl,
  }) : super(const SiteDiaryFormState()) {
    on<InitializeFormEvent>(_onInitializeForm);
    on<GetDetailsEvent>(_onGetDetails);
    on<UpdateDocumentDataEvent>(_onUpdateDocumentData);
    on<SaveFormEvent>(_onSaveForm);
    on<FetchEmployeeNameEvent>(_onFetchEmployeeName);
  }

  Future<void> _onInitializeForm(
    InitializeFormEvent event,
    Emitter<SiteDiaryFormState> emit,
  ) async {
    emit(state.copyWith(status: SiteDiaryFormStatus.loading));

    // Resolve base URL synchronously — no async needed
    final baseUrl = getSiteDiaryBaseUrl();

    final metaResult = await getSiteDiaryMeta();
    final docResult = await loadSiteDiaryDocument(
      diaryName: event.diaryName,
      project: event.project,
    );

    metaResult.fold(
      (failure) => emit(state.copyWith(
        status: SiteDiaryFormStatus.loadFailure,
        error: failure.message,
      )),
      (meta) {
        docResult.fold(
          (failure) => emit(state.copyWith(
            status: SiteDiaryFormStatus.loadFailure,
            error: failure.message,
          )),
          (doc) {
            final allowedFields = [
              'site_date',
              'day_no_of_contract',
              'shift',
              'site_engineer',
              'site_engineer_name',
              'weather_am',
              'weather_pm',
              'max_temp',
              'min_temp',
              'wind_speed_kmh',
              'general_remarks',
              'site_photos',
              'status',
              'work_stopped',
              'get_site_diary_details',
              'task',
              'activity_progress',
              'material_received',
              'material_deliveries',
              'manpower_log',
              'equipment_log',
              'visitors',
            ];

            meta.fields.retainWhere((f) => allowedFields.contains(f.fieldname));
            meta.fields.sort((a, b) {
              final indexA = allowedFields.indexOf(a.fieldname ?? '');
              final indexB = allowedFields.indexOf(b.fieldname ?? '');
              return indexA.compareTo(indexB);
            });

            emit(state.copyWith(
              status: SiteDiaryFormStatus.loadSuccess,
              meta: meta,
              document: doc,
              baseUrl: baseUrl,
            ));
          },
        );
      },
    );
  }

  Future<void> _onGetDetails(
    GetDetailsEvent event,
    Emitter<SiteDiaryFormState> emit,
  ) async {
    if (state.document == null) return;
    emit(state.copyWith(status: SiteDiaryFormStatus.processing));

    try {
      final responses = await Future.wait([
        callSiteDiaryApi(
          'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_site_diary_details',
          {'project': event.project, 'site_date': event.dateStr},
        ),
        callSiteDiaryApi(
          'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_latest_task_progress',
          {'project': event.project, 'site_date': event.dateStr},
        ).then((r) => r, onError: (_) => null),
        callSiteDiaryApi(
          'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_material_deliveries',
          {'project': event.project, 'site_date': event.dateStr},
        ).then((r) => r, onError: (_) => null),
        callSiteDiaryApi(
          'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_material_received',
          {'project': event.project, 'site_date': event.dateStr},
        ).then((r) => r, onError: (_) => null),
      ]);

      final mainResponseEither = responses[0];
      final taskProgressResponseEither = responses[1];
      final materialDeliveriesResponseEither = responses[2];
      final materialReceivedResponseEither = responses[3];

      dynamic mainResponse;
      mainResponseEither.fold((_) => null, (r) => mainResponse = r);

      if (mainResponse != null && mainResponse is Map<String, dynamic>) {
        final updatedData = Map<String, dynamic>.from(state.document!.data);
        updatedData['site_date'] = event.dateStr;
        updatedData['project'] = event.project;

        final childTables = [
          'task',
          'activity_progress',
          'material_received',
          'material_deliveries',
          'manpower_log',
          'equipment_log',
          'visitors',
        ];

        final data = mainResponse.containsKey('message')
            ? mainResponse['message']
            : mainResponse;

        for (final table in childTables) {
          if (data is Map && data.containsKey(table)) {
            updatedData[table] = data[table];
          }
        }

        dynamic extractData(dynamic eitherResult) {
          if (eitherResult == null) return null;
          dynamic val;
          eitherResult.fold((_) => null, (r) => val = r);
          if (val is Map<String, dynamic>) {
            return val.containsKey('message') ? val['message'] : val;
          }
          return val;
        }

        final rawProgressData = extractData(taskProgressResponseEither);
        final List<Map<String, dynamic>> taskProgressData = [];
        if (rawProgressData is List) {
          for (final item in rawProgressData) {
            if (item is Map) {
              final mapItem = Map<String, dynamic>.from(item);
              final docNameVal =
                  mapItem['doc_name']?.toString() ??
                  mapItem['docname']?.toString();
              if (docNameVal != null &&
                  (docNameVal.startsWith('TP') ||
                      docNameVal.contains('TP-') ||
                      docNameVal.contains('TP -'))) {
                mapItem['id'] = docNameVal.trim();
                mapItem['doc_name'] = 'Task Progress';
              }
              taskProgressData.add(mapItem);
            }
          }
        }

        if (taskProgressData.isNotEmpty) {
          updatedData['activity_progress'] = taskProgressData;
        }

        final Map<String, String> taskSubjects = {};

        final existingTasks = updatedData['task'];
        if (existingTasks is List) {
          for (final item in existingTasks) {
            if (item is Map) {
              final taskId = item['task']?.toString();
              final subject = item['task_subject']?.toString();
              if (taskId != null && taskId.isNotEmpty) {
                taskSubjects[taskId] = subject ?? '';
              }
            }
          }
        }

        for (final item in taskProgressData) {
          final taskId =
              item['task']?.toString() ?? item['task_id']?.toString();
          if (taskId != null && taskId.isNotEmpty) {
            if (!taskSubjects.containsKey(taskId)) {
              taskSubjects[taskId] = '';
            }
          }
        }

        final List<Map<String, dynamic>> finalTaskList = [];
        for (final entry in taskSubjects.entries) {
          final taskId = entry.key;
          var subject = entry.value;

          if (subject.isEmpty) {
            final responseEither = await callSiteDiaryApi(
              'frappe.client.get_value',
              {
                'doctype': 'Task',
                'fieldname': 'subject',
                'filters': taskId,
              },
            );
            responseEither.fold((_) => null, (response) {
              if (response != null && response is Map<String, dynamic>) {
                final message = response['message'];
                if (message is Map) {
                  subject = message['subject']?.toString() ?? '';
                } else if (message is String) {
                  subject = message;
                }
              }
            });
          }
          finalTaskList.add({'task': taskId, 'task_subject': subject});
        }

        updatedData['task'] = finalTaskList;

        final materialDeliveriesData =
            extractData(materialDeliveriesResponseEither);
        if (materialDeliveriesData != null) {
          updatedData['material_deliveries'] = materialDeliveriesData;
        }

        final materialReceivedData =
            extractData(materialReceivedResponseEither);
        if (materialReceivedData != null) {
          updatedData['material_received'] = materialReceivedData;
        }

        final updatedDoc = state.document!.copyWith(data: updatedData);
        emit(state.copyWith(
          status: SiteDiaryFormStatus.loadSuccess,
          document: updatedDoc,
          detailsFetched: true,
        ));
      } else {
        emit(state.copyWith(
          status: SiteDiaryFormStatus.loadSuccess,
          error: 'Invalid response from details API',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: SiteDiaryFormStatus.loadSuccess,
        error: e.toString(),
      ));
    }
  }

  void _onUpdateDocumentData(
    UpdateDocumentDataEvent event,
    Emitter<SiteDiaryFormState> emit,
  ) {
    if (state.document == null) return;
    final updatedDoc = state.document!.copyWith(data: event.data);
    emit(state.copyWith(document: updatedDoc));
  }

  Future<void> _onSaveForm(
    SaveFormEvent event,
    Emitter<SiteDiaryFormState> emit,
  ) async {
    if (state.document == null) return;
    emit(state.copyWith(status: SiteDiaryFormStatus.processing));

    final String? diaryName = state.document!.data['name']?.toString();
    var payload = Map<String, dynamic>.from(event.payload);

    if (event.pickedSitePhotoPath != null) {
      String docNameToUpload = diaryName ?? 'TempUploadName';
      final uploadResult = await uploadSiteDiaryFile(
        filePath: event.pickedSitePhotoPath!,
        docName: docNameToUpload,
        doctype: 'Site Diary',
        docfield: 'site_photos',
      );

      String? uploadedUrl;
      uploadResult.fold(
        (failure) {
          // Photo upload failure doesn't block save
        },
        (url) => uploadedUrl = url,
      );

      if (uploadedUrl != null) {
        payload['site_photos'] = uploadedUrl;
      }
    }

    final saveResult = await saveSiteDiaryDocument(
      name: diaryName,
      payload: payload,
      existingDocument: state.document,
    );

    saveResult.fold(
      (failure) => emit(state.copyWith(
        status: SiteDiaryFormStatus.saveFailure,
        error: failure.message,
      )),
      (result) {
        emit(state.copyWith(status: SiteDiaryFormStatus.saveSuccess));
      },
    );
  }

  Future<void> _onFetchEmployeeName(
    FetchEmployeeNameEvent event,
    Emitter<SiteDiaryFormState> emit,
  ) async {
    final result = await getEmployeeName(event.employeeId);
    result.fold(
      (_) => emit(state.copyWith(employeeName: event.employeeId)),
      (name) => emit(state.copyWith(
        status: SiteDiaryFormStatus.employeeNameLoaded,
        employeeName: name,
      )),
    );
  }
}
