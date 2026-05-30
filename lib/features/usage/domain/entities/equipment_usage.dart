import 'package:equatable/equatable.dart';
import 'equipment_usage_item.dart';

class EquipmentUsage extends Equatable {
  final String name;
  final String project;
  final DateTime? siteDate;
  final String status;
  final List<EquipmentUsageItem> equipmentUsageDetails;
  final Map<String, dynamic> rawData;

  const EquipmentUsage({
    required this.name,
    required this.project,
    this.siteDate,
    required this.status,
    this.equipmentUsageDetails = const [],
    this.rawData = const {},
  });

  @override
  List<Object?> get props => [name, project, siteDate, status, equipmentUsageDetails, rawData];
}
