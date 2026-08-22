import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_progress.dart';

abstract class TaskProgressRepository {
  Future<Either<Failure, List<TaskProgress>>> getTaskProgresses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? project,
  });

  Future<Either<Failure, TaskProgress>> getTaskProgressDetails(String name);

  Future<Either<Failure, DocTypeMeta>> getMeta();

  Future<Either<Failure, Map<String, dynamic>?>> loadDocument(String? progressName);

  Future<Either<Failure, String>> saveDocument({
    required String? existingServerId,
    required Map<String, dynamic> payload,
  });

  Future<Either<Failure, void>> uploadFile({
    required String serverName,
    required String filePath,
  });

  String getBaseUrl();

  Future<Either<Failure, Uint8List>> downloadPdf(String entryName);
}
