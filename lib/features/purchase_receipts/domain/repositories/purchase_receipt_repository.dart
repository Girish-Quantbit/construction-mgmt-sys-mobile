import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_receipt.dart';

abstract class PurchaseReceiptRepository {
  Future<Either<Failure, List<PurchaseReceipt>>> getPurchaseReceipts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
    String? sortBy,
    String? sortOrder,
    DateTime? fromDate,
    DateTime? toDate,
    String? supplier,
  });

  Future<Either<Failure, PurchaseReceipt>> getPurchaseReceiptDetails(
    String name,
  );

  Future<Either<Failure, String>> downloadPDF(String name);
}

