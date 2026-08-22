import 'package:dartz/dartz.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/error/failures.dart';
import '../entities/site_diary.dart';

abstract class SiteDiaryRepository {
  Future<Either<Failure, List<SiteDiary>>> getSiteDiaries({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? project,
  });

  Future<Either<Failure, SiteDiary>> getSiteDiaryDetails(String name);

  Future<Either<Failure, DocTypeMeta>> getMeta();

  Future<Either<Failure, Document>> loadDocument(String? name, String? project);

  Future<Either<Failure, dynamic>> callApiMethod(String method, Map<String, dynamic> args);

  Future<Either<Failure, String?>> uploadFile({
    required String filePath,
    required String docName,
    required String doctype,
    required String docfield,
  });

  Future<Either<Failure, dynamic>> saveDocument({
    required String? name,
    required Map<String, dynamic> payload,
    required Document? existingDocument,
  });

  Future<Either<Failure, String>> getEmployeeName(String employeeId);

  String getBaseUrl();
}
