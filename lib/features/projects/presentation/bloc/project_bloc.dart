import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_projects.dart';
import 'project_event.dart';
import 'project_state.dart';

export 'project_event.dart';
export 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetProjects getProjects;

  ProjectBloc({required this.getProjects}) : super(ProjectInitial()) {
    on<GetProjectsRequested>((event, emit) async {
      emit(ProjectLoading());
      final result = await getProjects();
      result.fold(
        (failure) => emit(ProjectError(failure.message)),
        (projects) => emit(ProjectLoaded(projects)),
      );
    });
  }
}
