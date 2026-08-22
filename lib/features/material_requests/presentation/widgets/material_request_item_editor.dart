import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';

class MaterialRequestItemEditor extends StatefulWidget {
  final Map<String, dynamic> initialItem;
  final Function(Map<String, dynamic>) onSave;
  final Function(String, ValueChanged<String>) showLinkSearch;

  const MaterialRequestItemEditor({
    super.key,
    required this.initialItem,
    required this.onSave,
    required this.showLinkSearch,
  });

  @override
  State<MaterialRequestItemEditor> createState() =>
      _MaterialRequestItemEditorState();
}

class _MaterialRequestItemEditorState extends State<MaterialRequestItemEditor> {
  late Map<String, dynamic> _item;

  late TextEditingController _itemCodeController;
  late TextEditingController _itemNameController;
  late TextEditingController _qtyController;
  late TextEditingController _uomController;
  late TextEditingController _stockUomController;
  late TextEditingController _convFactorController;
  late TextEditingController _warehouseController;
  late TextEditingController _rateController;
  late TextEditingController _amountController;
  late TextEditingController _projectController;
  late TextEditingController _costCenterController;
  late TextEditingController _expenseAccountController;
  late TextEditingController _wipAssetController;
  late TextEditingController _manufacturerController;
  late TextEditingController _bomNoController;
  late TextEditingController _descriptionController;

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
    _qtyController = TextEditingController(
      text: _item['qty']?.toString() ?? '0.0',
    );
    _uomController = TextEditingController(text: _item['uom']?.toString());
    _stockUomController = TextEditingController(
      text: _item['stock_uom']?.toString(),
    );
    _convFactorController = TextEditingController(
      text: _item['conversion_factor']?.toString() ?? '1.0',
    );
    _warehouseController = TextEditingController(
      text: _item['warehouse']?.toString(),
    );
    _rateController = TextEditingController(
      text: _item['rate']?.toString() ?? '0.0',
    );
    _amountController = TextEditingController(
      text: _item['amount']?.toString() ?? '0.0',
    );
    _projectController = TextEditingController(
      text: _item['project']?.toString(),
    );
    _costCenterController = TextEditingController(
      text: _item['cost_center']?.toString(),
    );
    _expenseAccountController = TextEditingController(
      text: _item['expense_account']?.toString(),
    );
    _wipAssetController = TextEditingController(
      text: _item['wip_composite_asset']?.toString(),
    );
    _manufacturerController = TextEditingController(
      text: _item['manufacturer']?.toString(),
    );
    _bomNoController = TextEditingController(text: _item['bom_no']?.toString());
    _descriptionController = TextEditingController(
      text: _item['description']?.toString(),
    );
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _qtyController.dispose();
    _uomController.dispose();
    _stockUomController.dispose();
    _convFactorController.dispose();
    _warehouseController.dispose();
    _rateController.dispose();
    _amountController.dispose();
    _projectController.dispose();
    _costCenterController.dispose();
    _expenseAccountController.dispose();
    _wipAssetController.dispose();
    _manufacturerController.dispose();
    _bomNoController.dispose();
    _descriptionController.dispose();
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
                        fontSize: 13,
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
            absorbing: onTap != null || readOnly,
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
                fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
                suffixIcon: suffixIcon,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCDE0D5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4A8B5F)),
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
                              String? companyName;
                              try {
                                final companies = await sdk.api.doctype.list(
                                  'Company',
                                  fields: ['name'],
                                  limitPageLength: 1,
                                );
                                if (companies.isNotEmpty) {
                                  companyName = companies[0]['name']
                                      ?.toString();
                                }
                              } catch (_) {}

                              final response = await sdk.api.call(
                                'erpnext.stock.get_item_details.get_item_details',
                                args: {
                                  'ctx': jsonEncode({
                                    'item_code': val,
                                    'doctype': 'Material Request',
                                    'qty': 1.0,
                                    'buying_price_list': 'Standard Buying',
                                    'currency': 'INR',
                                    'conversion_rate': 1.0,
                                    'plc_conversion_rate': 1.0,
                                    'company': ?companyName,
                                  }),
                                  'overwrite_warehouse': true,
                                },
                              );

                              final Map<String, dynamic> itemData =
                                  (response is Map &&
                                      response.containsKey('message'))
                                  ? Map<String, dynamic>.from(
                                      response['message'] as Map,
                                    )
                                  : Map<String, dynamic>.from(response as Map);

                              final fetchedItemName =
                                  itemData['item_name']?.toString() ?? val;
                              final fetchedUom =
                                  (itemData['uom'] ??
                                          itemData['default_uom'] ??
                                          itemData['stock_uom'])
                                      ?.toString();
                              final fetchedStockUom =
                                  (itemData['stock_uom'] ??
                                  itemData['default_uom'] ??
                                  itemData['uom']);
                              final fetchedWarehouse =
                                  (itemData['warehouse'] ??
                                          itemData['default_warehouse'])
                                      ?.toString();
                              final rateVal =
                                  double.tryParse(
                                    itemData['rate']?.toString() ?? '',
                                  ) ??
                                  0.0;
                              final qtyVal =
                                  double.tryParse(
                                    itemData['qty']?.toString() ?? '',
                                  ) ??
                                  0.0;
                              final amountVal =
                                  double.tryParse(
                                    itemData['amount']?.toString() ?? '',
                                  ) ??
                                  (qtyVal * rateVal);

                              setState(() {
                                _item['item_name'] = fetchedItemName;
                                _itemNameController.text = fetchedItemName;
                                _item['rate'] = rateVal;
                                _rateController.text = rateVal.toString();
                                _item['qty'] = qtyVal;
                                _qtyController.text = qtyVal.toString();
                                _item['amount'] = amountVal;
                                _amountController.text = amountVal.toString();
                                if (fetchedUom != null) {
                                  _item['uom'] = fetchedUom;
                                  _uomController.text = fetchedUom;
                                }
                                if (fetchedStockUom != null) {
                                  _item['stock_uom'] = fetchedStockUom;
                                  _stockUomController.text = fetchedStockUom;
                                }
                                if (fetchedWarehouse != null) {
                                  _item['warehouse'] = fetchedWarehouse;
                                  _warehouseController.text = fetchedWarehouse;
                                }
                              });
                            } catch (_) {
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
                          label: 'Item Name',
                          controller: _itemNameController,
                          placeholder: 'Enter item name',
                          onChanged: (val) => _item['item_name'] = val,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Quantity & Pricing',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Quantity *',
                              controller: _qtyController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) {
                                setState(() {
                                  _item['qty'] = double.tryParse(val) ?? 0.0;
                                  final r =
                                      double.tryParse(_rateController.text) ??
                                      0.0;
                                  final amt = _item['qty'] * r;
                                  _item['amount'] = amt;
                                  _amountController.text = amt.toStringAsFixed(
                                    2,
                                  );
                                });
                              },
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Rate',
                              controller: _rateController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) {
                                setState(() {
                                  _item['rate'] = double.tryParse(val) ?? 0.0;
                                  final q =
                                      double.tryParse(_qtyController.text) ??
                                      0.0;
                                  final amt = q * _item['rate'];
                                  _item['amount'] = amt;
                                  _amountController.text = amt.toStringAsFixed(
                                    2,
                                  );
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
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Stock UOM *',
                              controller: _stockUomController,
                              placeholder: 'PCS',
                              onTap: () => widget.showLinkSearch('UOM', (val) {
                                setState(() {
                                  _item['stock_uom'] = val;
                                  _stockUomController.text = val;
                                });
                              }),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Conversion Factor *',
                        controller: _convFactorController,
                        placeholder: '1.0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) {
                          _item['conversion_factor'] =
                              double.tryParse(val) ?? 1.0;
                        },
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Amount',
                        controller: _amountController,
                        placeholder: '0.00',
                        readOnly: true,
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Warehouse & GST',
                    children: [
                      _buildTextField(
                        label: 'Warehouse',
                        controller: _warehouseController,
                        placeholder: 'Select warehouse',
                        onTap: () => widget.showLinkSearch('Warehouse', (val) {
                          setState(() {
                            _item['warehouse'] = val;
                            _warehouseController.text = val;
                          });
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Accounting & Projects',
                    children: [
                      _buildTextField(
                        label: 'Project',
                        controller: _projectController,
                        placeholder: 'Select project',
                        onTap: () => widget.showLinkSearch('Project', (val) {
                          setState(() {
                            _item['project'] = val;
                            _projectController.text = val;
                          });
                        }),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Cost Center',
                        controller: _costCenterController,
                        placeholder: 'Select cost center',
                        onTap: () =>
                            widget.showLinkSearch('Cost Center', (val) {
                              setState(() {
                                _item['cost_center'] = val;
                                _costCenterController.text = val;
                              });
                            }),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Expense Account',
                        controller: _expenseAccountController,
                        placeholder: 'Select expense account',
                        onTap: () => widget.showLinkSearch('Account', (val) {
                          setState(() {
                            _item['expense_account'] = val;
                            _expenseAccountController.text = val;
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
              final qtyText = _qtyController.text.trim();
              final qty = double.tryParse(qtyText) ?? 0.0;
              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quantity must be greater than 0'),
                  ),
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
              final stockUom = _stockUomController.text.trim();
              if (stockUom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select Stock UOM')),
                );
                return;
              }
              final convText = _convFactorController.text.trim();
              final conv = double.tryParse(convText) ?? 0.0;
              if (conv <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversion Factor must be greater than 0'),
                  ),
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
