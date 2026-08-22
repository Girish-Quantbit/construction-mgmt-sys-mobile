import 'package:equatable/equatable.dart';

abstract class TaskProgressFormEvent extends Equatable {
  const TaskProgressFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeTaskProgressFormEvent extends TaskProgressFormEvent {
  final String? progressName;

  const InitializeTaskProgressFormEvent({this.progressName});

  @override
  List<Object?> get props => [progressName];
}

class SaveTaskProgressFormEvent extends TaskProgressFormEvent {
  final String? existingServerId;
  final Map<String, dynamic> payload;
  final List<String> parentImagesPaths;
  final Map<int, List<String>> childImagesPaths; // Maps index of item -> file paths to upload

  const SaveTaskProgressFormEvent({
    required this.existingServerId,
    required this.payload,
    this.parentImagesPaths = const [],
    this.childImagesPaths = const {},
  });

  @override
  List<Object?> get props => [existingServerId, payload, parentImagesPaths, childImagesPaths];
}
