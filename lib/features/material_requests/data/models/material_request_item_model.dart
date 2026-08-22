import '../../domain/entities/material_request_item.dart';

class MaterialRequestItemModel extends MaterialRequestItem {
  const MaterialRequestItemModel({
    required super.itemName,
    required super.itemCode,
    required super.qty,
    super.uom,
    super.requiredByDate,
    super.scheduleDate,
    super.warehouse,
  });

  factory MaterialRequestItemModel.fromJson(Map<String, dynamic> json) {
    return MaterialRequestItemModel(
      itemName: json['item_name'] ?? '',
      itemCode: json['item_code'] ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      uom: json['uom'],
      requiredByDate: json['required_by_date'] != null
          ? DateTime.tryParse(json['required_by_date'])
          : null,
      scheduleDate: json['schedule_date'] != null
          ? DateTime.tryParse(json['schedule_date'])
          : null,
      warehouse: json['warehouse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'item_code': itemCode,
      'qty': qty,
      'uom': uom,
      'required_by_date': requiredByDate?.toIso8601String(),
      'schedule_date': scheduleDate?.toIso8601String(),
      'warehouse': warehouse,
    };
  }
}
