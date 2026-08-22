import '../../domain/entities/material_request.dart';
import 'material_request_item_model.dart';

class MaterialRequestModel extends MaterialRequest {
  const MaterialRequestModel({
    required super.name,
    super.title,
    super.transactionDate,
    required super.materialRequestType,
    required super.status,
    super.items = const [],
    super.scheduleDate,
    super.buyingPriceList,
    super.setWarehouse,
    super.perOrdered,
    super.perReceived,
    super.rawData = const {},
  });

  factory MaterialRequestModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsData = json['items'] ?? [];
    final items = itemsData
        .map((item) => MaterialRequestItemModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return MaterialRequestModel(
      name: json['name'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'])
          : null,
      materialRequestType: json['material_request_type'] ?? '',
      status: json['status'] ?? '',
      items: items,
      scheduleDate: json['schedule_date'] != null
          ? DateTime.tryParse(json['schedule_date'])
          : null,
      buyingPriceList: json['buying_price_list'],
      setWarehouse: json['set_warehouse'],
      perOrdered: (json['per_ordered'] as num?)?.toDouble(),
      perReceived: (json['per_received'] as num?)?.toDouble(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'transaction_date': transactionDate?.toIso8601String(),
      'material_request_type': materialRequestType,
      'status': status,
      'items': items.map((item) {
        if (item is MaterialRequestItemModel) {
          return item.toJson();
        }
        return {
          'item_name': item.itemName,
          'item_code': item.itemCode,
          'qty': item.qty,
          'uom': item.uom,
          'required_by_date': item.requiredByDate?.toIso8601String(),
          'schedule_date': item.scheduleDate?.toIso8601String(),
          'warehouse': item.warehouse,
        };
      }).toList(),
      'schedule_date': scheduleDate?.toIso8601String(),
      'buying_price_list': buyingPriceList,
      'set_warehouse': setWarehouse,
      'per_ordered': perOrdered,
      'per_received': perReceived,
    };
  }
}
