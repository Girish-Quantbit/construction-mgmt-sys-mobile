import 'package:equatable/equatable.dart';

abstract class SiteDiaryFormEvent extends Equatable {
  const SiteDiaryFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeFormEvent extends SiteDiaryFormEvent {
  final String? diaryName;
  final String? project;

  const InitializeFormEvent({this.diaryName, this.project});

  @override
  List<Object?> get props => [diaryName, project];
}

class GetDetailsEvent extends SiteDiaryFormEvent {
  final String project;
  final String dateStr;

  const GetDetailsEvent({required this.project, required this.dateStr});

  @override
  List<Object?> get props => [project, dateStr];
}

class UpdateDocumentDataEvent extends SiteDiaryFormEvent {
  final Map<String, dynamic> data;

  const UpdateDocumentDataEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class SaveFormEvent extends SiteDiaryFormEvent {
  final Map<String, dynamic> payload;
  final String? pickedSitePhotoPath;

  const SaveFormEvent({
    required this.payload,
    this.pickedSitePhotoPath,
  });

  @override
  List<Object?> get props => [payload, pickedSitePhotoPath];
}

class FetchEmployeeNameEvent extends SiteDiaryFormEvent {
  final String employeeId;

  const FetchEmployeeNameEvent(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}
