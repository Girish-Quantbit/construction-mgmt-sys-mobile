import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/site_diary_repository.dart';

class GetEmployeeName {
  final SiteDiaryRepository repository;

  GetEmployeeName(this.repository);

  Future<Either<Failure, String>> call(String employeeId) {
    return repository.getEmployeeName(employeeId);
  }
}
