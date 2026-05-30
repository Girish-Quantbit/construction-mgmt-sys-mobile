import 'package:equatable/equatable.dart';
import 'material_request_item.dart';

class MaterialRequest extends Equatable {
  final String name;
  final String? title;
  final DateTime? transactionDate;
  final String materialRequestType;
  final String status;
  final List<MaterialRequestItem> items;
  final DateTime? scheduleDate;
  final String? buyingPriceList;
  final String? setWarehouse;
  final double? perOrdered;
  final double? perReceived;
  final Map<String, dynamic> rawData;

  const MaterialRequest({
    required this.name,
    this.title,
    this.transactionDate,
    required this.materialRequestType,
    required this.status,
    this.items = const [],
    this.scheduleDate,
    this.buyingPriceList,
    this.setWarehouse,
    this.perOrdered,
    this.perReceived,
    this.rawData = const {},
  });

  @override
  List<Object?> get props => [
        name,
        title,
        transactionDate,
        materialRequestType,
        status,
        items,
        scheduleDate,
        buyingPriceList,
        setWarehouse,
        perOrdered,
        perReceived,
        rawData,
      ];
}
