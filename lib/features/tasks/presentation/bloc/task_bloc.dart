import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

// Events
abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetTasksRequested extends TaskEvent {
  final String? project;
  GetTasksRequested({this.project});
  @override
  List<Object?> get props => [project];
}

// States
abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<ProjectTask> tasks;
  TaskLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;

  TaskBloc({required this.taskRepository}) : super(TaskInitial()) {
    on<GetTasksRequested>((event, emit) async {
      emit(TaskLoading());
      final result = await taskRepository.getTasks(project: event.project);
      result.fold(
        (failure) => emit(TaskError(failure.message)),
        (tasks) => emit(TaskLoaded(tasks)),
      );
    });
  }
}
