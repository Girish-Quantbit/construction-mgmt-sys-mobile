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
  final double? openingReading;
  final double? closingReading;
  final double? dieselFilledInLtr;
  final bool? billed;
  final bool? paid;
  final double? workingHrs;

  const EquipmentUsageItem({
    required this.task,
    required this.subtask,
    required this.quantity,
    this.rate = 0.0,
    this.amount = 0.0,
    required this.equipmentItem,
    required this.contractor,
    required this.uom,
    this.openingReading,
    this.closingReading,
    this.dieselFilledInLtr,
    this.billed,
    this.paid,
    this.workingHrs,
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
    openingReading,
    closingReading,
    dieselFilledInLtr,
    billed,
    paid,
    workingHrs,
  ];
}
