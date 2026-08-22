import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../repositories/task_progress_repository.dart';

class GetTaskProgressMeta {
  final TaskProgressRepository repository;

  GetTaskProgressMeta(this.repository);

  Future<Either<Failure, DocTypeMeta>> call() {
    return repository.getMeta();
  }
}
