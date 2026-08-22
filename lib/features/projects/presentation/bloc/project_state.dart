import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';

abstract class ProjectState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<Project> projects;
  ProjectLoaded(this.projects);
  @override
  List<Object?> get props => [projects];
}

class ProjectError extends ProjectState {
  final String message;
  ProjectError(this.message);
  @override
  List<Object?> get props => [message];
}
