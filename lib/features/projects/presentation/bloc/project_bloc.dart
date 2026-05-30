import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

// Events
abstract class ProjectEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetProjectsRequested extends ProjectEvent {}

// States
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

// BLoC
class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository projectRepository;

  ProjectBloc({required this.projectRepository}) : super(ProjectInitial()) {
    on<GetProjectsRequested>((event, emit) async {
      emit(ProjectLoading());
      final result = await projectRepository.getProjects();
      result.fold(
        (failure) => emit(ProjectError(failure.message)),
        (projects) => emit(ProjectLoaded(projects)),
      );
    });
  }
}
