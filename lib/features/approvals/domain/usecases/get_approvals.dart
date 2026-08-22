import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/approval_item.dart';
import '../repositories/approvals_repository.dart';

class GetApprovals {
  final ApprovalsRepository repository;

  GetApprovals(this.repository);

  Future<Either<Failure, List<ApprovalItem>>> call({
    String? project,
  }) {
    return repository.getApprovals(
      project: project,
    );
  }
}
