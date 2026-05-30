import 'package:equatable/equatable.dart';
import 'purchase_receipt_item.dart';

class PurchaseReceipt extends Equatable {
  final String name; // Receipt ID
  final String supplier;
  final DateTime? postingDate;
  final double grandTotal;
  final String status;
  final String? supplierAddress;
  final String? contactPerson;
  final List<PurchaseReceiptItem> items;
  final double taxesAndCharges;
  final double baseGrandTotal;
  final Map<String, dynamic> rawData;

  const PurchaseReceipt({
    required this.name,
    required this.supplier,
    this.postingDate,
    required this.grandTotal,
    required this.status,
    this.supplierAddress,
    this.contactPerson,
    this.items = const [],
    this.taxesAndCharges = 0.0,
    this.baseGrandTotal = 0.0,
    this.rawData = const {},
  });

  @override
  List<Object?> get props => [
    name,
    supplier,
    postingDate,
    grandTotal,
    status,
    supplierAddress,
    contactPerson,
    items,
    taxesAndCharges,
    baseGrandTotal,
    rawData,
  ];
}
