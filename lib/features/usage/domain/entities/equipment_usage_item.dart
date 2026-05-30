import 'package:equatable/equatable.dart';

class EquipmentUsageItem extends Equatable {
  final String task;
  final String subtask;
  final double quantity;
  final double rate;
  final double amount;
  final String equipmentItem;
  final String contractor;
  final String uom;

  const EquipmentUsageItem({
    required this.task,
    required this.subtask,
    required this.quantity,
    this.rate = 0.0,
    this.amount = 0.0,
    required this.equipmentItem,
    required this.contractor,
    required this.uom,
  });

  @override
  List<Object?> get props => [
    task,
    subtask,
    quantity,
    rate,
    amount,
    equipmentItem,
    contractor,
    uom,
  ];
}
