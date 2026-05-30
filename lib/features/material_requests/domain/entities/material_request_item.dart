import 'package:equatable/equatable.dart';

class MaterialRequestItem extends Equatable {
  final String itemName;
  final String itemCode;
  final double qty;
  final String? uom;
  final DateTime? requiredByDate;
  final DateTime? scheduleDate;
  final String? warehouse;

  const MaterialRequestItem({
    required this.itemName,
    required this.itemCode,
    required this.qty,
    this.uom,
    this.requiredByDate,
    this.scheduleDate,
    this.warehouse,
  });

  @override
  List<Object?> get props => [
        itemName,
        itemCode,
        qty,
        uom,
        requiredByDate,
        scheduleDate,
        warehouse,
      ];
}
