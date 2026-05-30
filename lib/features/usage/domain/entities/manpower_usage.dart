import 'package:equatable/equatable.dart';
import 'manpower_usage_item.dart';

class ManpowerUsage extends Equatable {
  final String name;
  final String project;
  final DateTime? siteDate;
  final String status;
  final List<ManpowerUsageItem> manpowerUsage;
  final Map<String, dynamic> rawData;

  const ManpowerUsage({
    required this.name,
    required this.project,
    this.siteDate,
    required this.status,
    this.manpowerUsage = const [],
    this.rawData = const {},
  });

  @override
  List<Object?> get props => [
    name,
    project,
    siteDate,
    status,
    manpowerUsage,
    rawData,
  ];
}
