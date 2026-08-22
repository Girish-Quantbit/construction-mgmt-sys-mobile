import '../repositories/equipment_usage_repository.dart';

class GetEquipmentUsageBaseUrl {
  final EquipmentUsageRepository repository;

  GetEquipmentUsageBaseUrl(this.repository);

  String call() => repository.getBaseUrl();
}
