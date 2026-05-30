import 'package:equatable/equatable.dart';

class PurchaseReceiptItem extends Equatable {
  final String itemName;
  final String itemCode; // SKU
  final double qty;
  final double rate; // Unit Price
  final double amount; // Subtotal

  const PurchaseReceiptItem({
    required this.itemName,
    required this.itemCode,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  @override
  List<Object?> get props => [itemName, itemCode, qty, rate, amount];
}
