import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_tasks.dart';
import 'task_event.dart';
import 'task_state.dart';

export 'task_event.dart';
export 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasks getTasks;

  TaskBloc({required this.getTasks}) : super(TaskInitial()) {
    on<GetTasksRequested>((event, emit) async {
      emit(TaskLoading());
      final result = await getTasks(project: event.project);
      result.fold(
        (failure) => emit(TaskError(failure.message)),
        (tasks) => emit(TaskLoaded(tasks)),
      );
    });
  }
}
