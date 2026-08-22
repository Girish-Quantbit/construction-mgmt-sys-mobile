import 'package:cms/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';

class PurchaseReceiptItemEditor extends StatefulWidget {
  final Map<String, dynamic> initialItem;
  final Function(Map<String, dynamic>) onSave;
  final Function(String, ValueChanged<String>) showLinkSearch;
  final String? defaultWarehouse;

  const PurchaseReceiptItemEditor({
    super.key,
    required this.initialItem,
    required this.onSave,
    required this.showLinkSearch,
    this.defaultWarehouse,
  });

  @override
  State<PurchaseReceiptItemEditor> createState() =>
      _PurchaseReceiptItemEditorState();
}

class _PurchaseReceiptItemEditorState extends State<PurchaseReceiptItemEditor> {
  late Map<String, dynamic> _item;

  late TextEditingController _itemCodeController;
  late TextEditingController _itemNameController;
  late TextEditingController _acceptedQtyController;
  late TextEditingController _rejectedQtyController;
  late TextEditingController _receivedQtyController;
  late TextEditingController _uomController;
  late TextEditingController _stockUomController;
  late TextEditingController _convFactorController;
  late TextEditingController _baseRateController;
  late TextEditingController _warehouseController;
  late TextEditingController _rejectedWarehouseController;
  late TextEditingController _projectController;
  late TextEditingController _siteController;
  late TextEditingController _costCenterController;
  late TextEditingController _priceListRateController;
  late TextEditingController _expenseAccountController;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.initialItem);

    _itemCodeController = TextEditingController(
      text: _item['item_code']?.toString(),
    );
    _itemNameController = TextEditingController(
      text: _item['item_name']?.toString(),
    );

    final double accQty =
        double.tryParse(_item['qty']?.toString() ?? '0.0') ?? 0.0;
    final double rejQty =
        double.tryParse(_item['rejected_qty']?.toString() ?? '0.0') ?? 0.0;
    final double recQty = accQty + rejQty;

    _item['qty'] = accQty;
    _item['rejected_qty'] = rejQty;
    _item['received_qty'] = recQty;
    _item['total_qty'] = recQty;

    _acceptedQtyController = TextEditingController(text: accQty.toString());
    _rejectedQtyController = TextEditingController(text: rejQty.toString());
    _receivedQtyController = TextEditingController(text: recQty.toString());

    _uomController = TextEditingController(text: _item['uom']?.toString());
    _stockUomController = TextEditingController(
      text: _item['stock_uom']?.toString(),
    );
    _convFactorController = TextEditingController(
      text: _item['conversion_factor']?.toString() ?? '1.0',
    );
    _baseRateController = TextEditingController(
      text: _item['rate']?.toString() ?? '0.0',
    );
    _warehouseController = TextEditingController(
      text: _item['warehouse']?.toString(),
    );
    _rejectedWarehouseController = TextEditingController(
      text: _item['rejected_warehouse']?.toString(),
    );
    _projectController = TextEditingController(
      text: _item['project']?.toString(),
    );
    _siteController = TextEditingController(text: _item['site']?.toString());
    _costCenterController = TextEditingController(
      text: _item['cost_center']?.toString(),
    );
    _priceListRateController = TextEditingController(
      text: _item['price_list_rate']?.toString() ?? '0.0',
    );
    _expenseAccountController = TextEditingController(
      text: _item['expense_account']?.toString(),
    );
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _acceptedQtyController.dispose();
    _rejectedQtyController.dispose();
    _receivedQtyController.dispose();
    _uomController.dispose();
    _stockUomController.dispose();
    _convFactorController.dispose();
    _baseRateController.dispose();
    _warehouseController.dispose();
    _rejectedWarehouseController.dispose();
    _projectController.dispose();
    _siteController.dispose();
    _costCenterController.dispose();
    _priceListRateController.dispose();
    _expenseAccountController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label.endsWith('*')
            ? Text.rich(
                TextSpan(
                  text: label.substring(0, label.length - 1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
        SizedBox(height: sizeContextOf(context, 6)),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              readOnly: readOnly,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: sizeContextOf(context, 12),
                  vertical: sizeContextOf(context, 12),
                ),
                filled: true,
                fillColor: readOnly ? const Color(0xFFEEEEEE) : Colors.white,
                suffixIcon: suffixIcon,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: readOnly
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFFCDE0D5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: readOnly
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFF4A8B5F),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInnerCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF0F5F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: sizeContextOf(context, 12)),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: sizeContextOf(context, 16),
        left: sizeContextOf(context, 16),
        right: sizeContextOf(context, 16),
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Item Row',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: sizeContextOf(context, 12)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Item Code *',
                          controller: _itemCodeController,
                          placeholder: 'SKU-001',
                          onTap: () => widget.showLinkSearch('Item', (
                            val,
                          ) async {
                            setState(() {
                              _item['item_code'] = val;
                              _itemCodeController.text = val;
                            });
                            try {
                              final sdk = sl<FrappeSDK>();
                              final itemData = await sdk.api.doctype.getByName(
                                'Item',
                                val,
                              );

                              final fetchedItemName =
                                  itemData['item_name']?.toString() ?? val;
                              final fetchedUom =
                                  (itemData['stock_uom'] ??
                                          itemData['uom'] ??
                                          itemData['default_uom'])
                                      ?.toString();
                              final standardRate =
                                  double.tryParse(
                                    itemData['standard_rate']?.toString() ?? '',
                                  ) ??
                                  0.0;
                              final valuationRate =
                                  double.tryParse(
                                    itemData['valuation_rate']?.toString() ??
                                        '',
                                  ) ??
                                  0.0;
                              final lastPurchaseRate =
                                  double.tryParse(
                                    itemData['last_purchase_rate']
                                            ?.toString() ??
                                        '',
                                  ) ??
                                  0.0;
                              final priceListRate =
                                  double.tryParse(
                                    itemData['price_list_rate']?.toString() ??
                                        '',
                                  ) ??
                                  0.0;

                              double rateVal = 0.0;
                              if (valuationRate > 0) {
                                rateVal = valuationRate;
                              } else if (standardRate > 0) {
                                rateVal = standardRate;
                              } else if (lastPurchaseRate > 0) {
                                rateVal = lastPurchaseRate;
                              } else if (priceListRate > 0) {
                                rateVal = priceListRate;
                              }

                              final fetchedWarehouse =
                                  (itemData['default_warehouse'] ??
                                          itemData['warehouse'] ??
                                          widget.defaultWarehouse)
                                      ?.toString();
                              final fetchedExpenseAccount =
                                  (itemData['expense_account'] ??
                                          itemData['default_expense_account'])
                                      ?.toString();

                              setState(() {
                                _item['item_name'] = fetchedItemName;
                                _itemNameController.text = fetchedItemName;

                                // Default qty to 1.0 if not set or zero
                                final currentQty =
                                    double.tryParse(
                                      _item['qty']?.toString() ?? '0.0',
                                    ) ??
                                    0.0;
                                if (currentQty == 0.0) {
                                  _item['qty'] = 1.0;
                                  _acceptedQtyController.text = '1.0';

                                  final rej =
                                      double.tryParse(
                                        _item['rejected_qty']?.toString() ??
                                            '0.0',
                                      ) ??
                                      0.0;
                                  final rec = 1.0 + rej;
                                  _item['received_qty'] = rec;
                                  _item['total_qty'] = rec;
                                  _receivedQtyController.text = rec.toString();
                                }

                                if (fetchedUom != null) {
                                  _item['uom'] = fetchedUom;
                                  _uomController.text = fetchedUom;
                                  _item['stock_uom'] = fetchedUom;
                                  _stockUomController.text = fetchedUom;
                                }

                                _item['price_list_rate'] = rateVal;
                                _priceListRateController.text = rateVal
                                    .toStringAsFixed(2);
                                _item['rate'] = rateVal;
                                _baseRateController.text = rateVal
                                    .toStringAsFixed(2);

                                if (fetchedWarehouse != null) {
                                  _item['warehouse'] = fetchedWarehouse;
                                  _warehouseController.text = fetchedWarehouse;
                                }

                                if (fetchedExpenseAccount != null) {
                                  _item['expense_account'] =
                                      fetchedExpenseAccount;
                                  _expenseAccountController.text =
                                      fetchedExpenseAccount;
                                }
                              });
                            } catch (e) {
                              setState(() {
                                _item['item_name'] = val;
                                _itemNameController.text = val;
                              });
                            }
                          }),
                        ),
                      ),
                      SizedBox(width: sizeContextOf(context, 8)),
                      Expanded(
                        child: _buildTextField(
                          label: 'Item Name *',
                          controller: _itemNameController,
                          placeholder: 'Enter item name',
                          onChanged: (val) => _item['item_name'] = val,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Received and Accepted',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Accepted Qty *',
                              controller: _acceptedQtyController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) {
                                final acc = double.tryParse(val) ?? 0.0;
                                _item['qty'] = acc;
                                final rej =
                                    double.tryParse(
                                      _rejectedQtyController.text,
                                    ) ??
                                    0.0;
                                final rec = acc + rej;
                                setState(() {
                                  _item['received_qty'] = rec;
                                  _item['total_qty'] = rec;
                                  _receivedQtyController.text = rec.toString();
                                });
                              },
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Rejected Qty',
                              controller: _rejectedQtyController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) {
                                final rej = double.tryParse(val) ?? 0.0;
                                _item['rejected_qty'] = rej;
                                final acc =
                                    double.tryParse(
                                      _acceptedQtyController.text,
                                    ) ??
                                    0.0;
                                final rec = acc + rej;
                                setState(() {
                                  _item['received_qty'] = rec;
                                  _item['total_qty'] = rec;
                                  _receivedQtyController.text = rec.toString();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Received Qty',
                              controller: _receivedQtyController,
                              placeholder: '0.00',
                              readOnly: true,
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'UOM *',
                              controller: _uomController,
                              placeholder: 'PCS/KGS',
                              onTap: () => widget.showLinkSearch('UOM', (val) {
                                setState(() {
                                  _item['uom'] = val;
                                  _uomController.text = val;
                                });
                              }),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Stock UOM',
                              controller: _stockUomController,
                              placeholder: 'PCS',
                              readOnly: true,
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Conversion Factor',
                              controller: _convFactorController,
                              placeholder: '1.0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) {
                                _item['conversion_factor'] =
                                    double.tryParse(val) ?? 1.0;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Base Rate *',
                              controller: _baseRateController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              suffixIcon: const Icon(
                                Icons.calculate_outlined,
                                size: 16,
                              ),
                              onChanged: (val) {
                                _item['rate'] = double.tryParse(val) ?? 0.0;
                              },
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Price List Rate',
                              controller: _priceListRateController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              suffixIcon: const Icon(
                                Icons.calculate_outlined,
                                size: 16,
                              ),
                              onChanged: (val) {
                                _item['price_list_rate'] =
                                    double.tryParse(val) ?? 0.0;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Warehouse & Reference',
                    children: [
                      _buildTextField(
                        label: 'Accepted Warehouse',
                        controller: _warehouseController,
                        placeholder: 'Main Warehouse',
                        onTap: () => widget.showLinkSearch('Warehouse', (val) {
                          setState(() {
                            _item['warehouse'] = val;
                            _warehouseController.text = val;
                          });
                        }),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Rejected Warehouse',
                        controller: _rejectedWarehouseController,
                        placeholder: 'Select rejected warehouse',
                        onTap: () => widget.showLinkSearch('Warehouse', (val) {
                          setState(() {
                            _item['rejected_warehouse'] = val;
                            _rejectedWarehouseController.text = val;
                          });
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Accounting Dimensions',
                    children: [
                      _buildTextField(
                        label: 'Project',
                        controller: _projectController,
                        placeholder: 'Project Alpha',
                        onTap: () => widget.showLinkSearch('Project', (val) {
                          setState(() {
                            _item['project'] = val;
                            _projectController.text = val;
                          });
                        }),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Site',
                        controller: _siteController,
                        placeholder: 'Site A-1',
                        onTap: () => widget.showLinkSearch('Site', (val) {
                          setState(() {
                            _item['site'] = val;
                            _siteController.text = val;
                          });
                        }),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Cost Center',
                        controller: _costCenterController,
                        placeholder: 'Ops-01',
                        onTap: () =>
                            widget.showLinkSearch('Cost Center', (val) {
                              setState(() {
                                _item['cost_center'] = val;
                                _costCenterController.text = val;
                              });
                            }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sizeContextOf(context, 16)),
          ElevatedButton(
            onPressed: () {
              final itemCode = _itemCodeController.text.trim();
              if (itemCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an Item Code')),
                );
                return;
              }
              final itemName = _itemNameController.text.trim();
              if (itemName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an Item Name')),
                );
                return;
              }
              final uom = _uomController.text.trim();
              if (uom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select UOM')),
                );
                return;
              }
              final baseRateText = _baseRateController.text.trim();
              final baseRate = double.tryParse(baseRateText);
              if (baseRateText.isEmpty || baseRate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Base Rate')),
                );
                return;
              }
              widget.onSave(_item);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A8B5F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: sizeContextOf(context, 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Item',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
