import 'package:equatable/equatable.dart';

class ManpowerUsageItem extends Equatable {
  final String task;
  final String subtask;
  final double quantity;
  final double rate;
  final double amount;
  final String equipmentItem;
  final String contractor;
  final String uom;
  final String skillType;
  final String? timeIn;
  final String? timeOut;
  final double? presenty;
  final double? hours;
  final double? totalPresenty;
  final bool? billed;
  final bool? paid;
  final String? itemName;


  const ManpowerUsageItem({
    required this.task,
    required this.subtask,
    required this.quantity,
    this.rate = 0.0,
    this.amount = 0.0,
    required this.equipmentItem,
    required this.contractor,
    required this.uom,
    required this.skillType,
    this.timeIn,
    this.timeOut,
    this.presenty,
    this.hours,
    this.totalPresenty,
    this.billed,
    this.paid,
    this.itemName,
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
    skillType,
    timeIn,
    timeOut,
    presenty,
    hours,
    totalPresenty,
    billed,
    paid,
    itemName,
  ];
}
