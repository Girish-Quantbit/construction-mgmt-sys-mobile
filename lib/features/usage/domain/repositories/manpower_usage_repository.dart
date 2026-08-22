import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../entities/manpower_usage.dart';

abstract class ManpowerUsageRepository {
  Future<Either<Failure, List<ManpowerUsage>>> getManpowerUsages({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  });

  Future<Either<Failure, ManpowerUsage>> getManpowerUsageDetails(String name);

  Future<Either<Failure, DocTypeMeta>> getMeta();

  Future<Either<Failure, Map<String, dynamic>?>> loadDocument(String? usageName);

  Future<Either<Failure, String>> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  });

  String getBaseUrl();

  Future<Either<Failure, Uint8List>> downloadPdf(String entryName);
}
