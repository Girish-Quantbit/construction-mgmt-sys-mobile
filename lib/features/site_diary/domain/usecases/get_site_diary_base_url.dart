import '../repositories/site_diary_repository.dart';

class GetSiteDiaryBaseUrl {
  final SiteDiaryRepository repository;

  GetSiteDiaryBaseUrl(this.repository);

  String call() {
    return repository.getBaseUrl();
  }
}
