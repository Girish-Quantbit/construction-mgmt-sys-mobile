import 'package:equatable/equatable.dart';

class StockEntryItem extends Equatable {
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
  final String? sWarehouse;
  final String? tWarehouse;
  final double basicRate;
  final double amount;

  const StockEntryItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
    this.sWarehouse,
    this.tWarehouse,
    required this.basicRate,
    required this.amount,
  });

  @override
  List<Object?> get props => [
    itemCode,
    itemName,
    qty,
    uom,
    sWarehouse,
    tWarehouse,
    basicRate,
    amount,
  ];
}
