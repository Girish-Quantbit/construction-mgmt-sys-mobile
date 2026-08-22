import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/site_diary_repository.dart';

class CallSiteDiaryApi {
  final SiteDiaryRepository repository;

  CallSiteDiaryApi(this.repository);

  Future<Either<Failure, dynamic>> call(
    String method,
    Map<String, dynamic> args,
  ) {
    return repository.callApiMethod(method, args);
  }
}
