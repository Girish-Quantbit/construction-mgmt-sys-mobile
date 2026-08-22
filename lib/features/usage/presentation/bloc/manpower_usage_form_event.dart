import 'package:equatable/equatable.dart';

abstract class ManpowerUsageFormEvent extends Equatable {
  const ManpowerUsageFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeManpowerUsageFormEvent extends ManpowerUsageFormEvent {
  final String? usageName;

  const InitializeManpowerUsageFormEvent({this.usageName});

  @override
  List<Object?> get props => [usageName];
}

class SaveManpowerUsageFormEvent extends ManpowerUsageFormEvent {
  final String? existingServerId;
  final Map<String, dynamic> payload;

  const SaveManpowerUsageFormEvent({
    required this.existingServerId,
    required this.payload,
  });

  @override
  List<Object?> get props => [existingServerId, payload];
}
