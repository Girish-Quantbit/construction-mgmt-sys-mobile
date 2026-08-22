import 'package:equatable/equatable.dart';

abstract class EquipmentUsageFormEvent extends Equatable {
  const EquipmentUsageFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeEquipmentUsageFormEvent extends EquipmentUsageFormEvent {
  final String? usageName;

  const InitializeEquipmentUsageFormEvent({this.usageName});

  @override
  List<Object?> get props => [usageName];
}

class SaveEquipmentUsageFormEvent extends EquipmentUsageFormEvent {
  final String? existingServerId;
  final Map<String, dynamic> payload;

  const SaveEquipmentUsageFormEvent({
    required this.existingServerId,
    required this.payload,
  });

  @override
  List<Object?> get props => [existingServerId, payload];
}
