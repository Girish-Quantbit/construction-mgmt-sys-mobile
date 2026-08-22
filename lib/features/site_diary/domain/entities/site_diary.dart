import 'package:equatable/equatable.dart';
import 'site_diary_child_entities.dart';

class SiteDiary extends Equatable {
  final String name;
  final DateTime? siteDate;
  final String? project;
  final String? generalRemarks;
  final String? weatherAm;
  final String? weatherPm;
  final String status;

  // Child table entities
  final List<SiteDiaryTask> tasks;
  final List<SiteDiaryActivityProgress> activityProgress;
  final List<SiteDiaryManpowerLog> manpowerLogs;
  final List<SiteDiaryEquipmentLog> equipmentLogs;
  final List<SiteDiaryMaterialReceived> materialsReceived;
  final List<SiteDiaryMaterialDelivery> materialsDelivered;
  final List<SiteDiaryVisitor> visitors;

  final Map<String, dynamic> rawData;

  const SiteDiary({
    required this.name,
    this.siteDate,
    this.project,
    this.generalRemarks,
    this.weatherAm,
    this.weatherPm,
    required this.status,
    this.tasks = const [],
    this.activityProgress = const [],
    this.manpowerLogs = const [],
    this.equipmentLogs = const [],
    this.materialsReceived = const [],
    this.materialsDelivered = const [],
    this.visitors = const [],
    this.rawData = const {},
  });

  @override
  List<Object?> get props => [
    name,
    siteDate,
    project,
    generalRemarks,
    weatherAm,
    weatherPm,
    status,
    tasks,
    activityProgress,
    manpowerLogs,
    equipmentLogs,
    materialsReceived,
    materialsDelivered,
    visitors,
    rawData,
  ];
}
