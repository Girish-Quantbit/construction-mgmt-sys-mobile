import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/approval_item.dart';

abstract class ApprovalsRepository {
  Future<Either<Failure, List<ApprovalItem>>> getApprovals({
    String? project,
  });
}
