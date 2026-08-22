import '../repositories/task_progress_repository.dart';

class GetTaskProgressBaseUrl {
  final TaskProgressRepository repository;

  GetTaskProgressBaseUrl(this.repository);

  String call() => repository.getBaseUrl();
}
