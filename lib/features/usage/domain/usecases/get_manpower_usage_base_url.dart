import '../repositories/manpower_usage_repository.dart';

class GetManpowerUsageBaseUrl {
  final ManpowerUsageRepository repository;

  GetManpowerUsageBaseUrl(this.repository);

  String call() => repository.getBaseUrl();
}
