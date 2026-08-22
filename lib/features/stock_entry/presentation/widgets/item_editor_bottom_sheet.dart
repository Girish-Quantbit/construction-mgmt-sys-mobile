import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:intl/intl.dart';
import 'package:cms/core/widgets/task_selection_widget.dart';

class ItemEditorBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialItem;
  final Function(Map<String, dynamic>) onSave;
  final Function(
    String doctype,
    ValueChanged<String> callback, {
    List<List<dynamic>>? extraFilters,
  })
  showLinkSearch;
  final String? stockEntryType;
  final String? project;

  const ItemEditorBottomSheet({
    super.key,
    required this.initialItem,
    required this.onSave,
    required this.showLinkSearch,
    this.stockEntryType,
    this.project,
  });

  @override
  State<ItemEditorBottomSheet> createState() => _ItemEditorBottomSheetState();
}

class _ItemEditorBottomSheetState extends State<ItemEditorBottomSheet> {
  late Map<String, dynamic> _item;

  late TextEditingController _itemCodeController;
  late TextEditingController _itemNameController;
  late TextEditingController _qtyController;
  late TextEditingController _uomController;
  late TextEditingController _stockUomController;
  late TextEditingController _convFactorController;
  late TextEditingController _sWarehouseController;
  late TextEditingController _tWarehouseController;
  late TextEditingController _rateController;
  late TextEditingController _costCenterController;
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
    _sWarehouseController = TextEditingController(
      text: _item['s_warehouse']?.toString(),
    );
    _tWarehouseController = TextEditingController(
      text: _item['t_warehouse']?.toString(),
    );
    _rateController = TextEditingController(
      text: _item['basic_rate']?.toString() ?? '0.0',
    );
    _costCenterController = TextEditingController(
      text: _item['cost_center']?.toString(),
    );
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
    _sWarehouseController.dispose();
    _tWarehouseController.dispose();
    _rateController.dispose();
    _costCenterController.dispose();
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
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: sizeContextOf(context, 12),
                  vertical: sizeContextOf(context, 12),
                ),
                filled: true,
                fillColor: Colors.white,
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
    final isTransfer = widget.stockEntryType == 'Material Transfer';
    final isIssue = widget.stockEntryType == 'Material Issue';

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
                  if (isIssue || isTransfer) ...[
                    TaskSelectionWidget(
                      project: widget.project,
                      initialParentTask: _item['parent_task']?.toString(),
                      initialTask: _item['task']?.toString(),
                      initialLevels: {
                        for (int i = 1; i <= 10; i++)
                          i:
                              _item[i == 2 ? 'task_level' : 'task_level$i']
                                  ?.toString() ??
                              '',
                      },
                      showLinkSearch: widget.showLinkSearch,
                      onTaskChanged: (result) {
                        setState(() {
                          _item['custom_task'] = result.activeTask;
                          _item['parent_task'] = result.parentTask;
                          _item['task'] = result.task;
                          for (int i = 1; i <= 10; i++) {
                            _item[i == 2 ? 'task_level' : 'task_level$i'] =
                                result.levels[i];
                          }
                        });
                      },
                    ),
                    SizedBox(height: sizeContextOf(context, 12)),
                  ],
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
                              final fetchedStockUom =
                                  (itemData['stock_uom'] ??
                                          itemData['default_uom'] ??
                                          itemData['uom'])
                                      ?.toString();
                              final fetchedWarehouse =
                                  (itemData['default_warehouse'] ??
                                          itemData['warehouse'])
                                      ?.toString();

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

                              double incomingRate = 0.0;
                              try {
                                final rateResponse = await sdk.api.call(
                                  'erpnext.stock.utils.get_incoming_rate',
                                  args: {
                                    'args': jsonEncode({
                                      'item_code': val,
                                      'posting_date': DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(DateTime.now()),
                                      'posting_time': DateFormat(
                                        'HH:mm:ss',
                                      ).format(DateTime.now()),
                                      'warehouse':
                                          fetchedWarehouse ??
                                          _item['s_warehouse'] ??
                                          _item['t_warehouse'] ??
                                          '',
                                      'company':
                                          companyName ?? 'Aarya Construction',
                                      'qty': 0,
                                      'voucher_type': 'Stock Entry',
                                      'allow_zero_valuation': 1,
                                    }),
                                  },
                                );
                                if (rateResponse is Map &&
                                    rateResponse.containsKey('message')) {
                                  incomingRate =
                                      double.tryParse(
                                        rateResponse['message']?.toString() ??
                                            '',
                                      ) ??
                                      0.0;
                                } else {
                                  incomingRate =
                                      double.tryParse(
                                        rateResponse?.toString() ?? '',
                                      ) ??
                                      0.0;
                                }
                              } catch (_) {}

                              setState(() {
                                _item['item_name'] = fetchedItemName;
                                _itemNameController.text = fetchedItemName;
                                _item['rate'] = incomingRate;
                                _item['basic_rate'] = incomingRate;
                                _rateController.text = incomingRate.toString();

                                final currentQty =
                                    double.tryParse(
                                      _item['qty']?.toString() ?? '0.0',
                                    ) ??
                                    0.0;
                                if (currentQty == 0.0) {
                                  _item['qty'] = 1.0;
                                  _qtyController.text = '1.0';
                                }

                                if (fetchedUom != null) {
                                  _item['uom'] = fetchedUom;
                                  _uomController.text = fetchedUom;
                                }
                                if (fetchedStockUom != null) {
                                  _item['stock_uom'] = fetchedStockUom;
                                  _stockUomController.text = fetchedStockUom;
                                }
                                if (fetchedWarehouse != null) {
                                  if (widget.stockEntryType ==
                                      'Material Issue') {
                                    _item['s_warehouse'] = fetchedWarehouse;
                                    _sWarehouseController.text =
                                        fetchedWarehouse;
                                  } else {
                                    _item['t_warehouse'] = fetchedWarehouse;
                                    _tWarehouseController.text =
                                        fetchedWarehouse;
                                  }
                                }
                              });
                            } catch (_) {
                              setState(() {
                                _item['item_name'] = val;
                                _itemNameController.text = val;
                                final currentQty =
                                    double.tryParse(
                                      _item['qty']?.toString() ?? '0.0',
                                    ) ??
                                    0.0;
                                if (currentQty == 0.0) {
                                  _item['qty'] = 1.0;
                                  _qtyController.text = '1.0';
                                }
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
                              onChanged: (val) =>
                                  _item['qty'] = double.tryParse(val) ?? 0.0,
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Basic Rate',
                              controller: _rateController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) {
                                final r = double.tryParse(val) ?? 0.0;
                                _item['basic_rate'] = r;
                                _item['rate'] = r;
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
                        onChanged: (val) => _item['conversion_factor'] =
                            double.tryParse(val) ?? 1.0,
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Warehouse Details',
                    children: [
                      if (isTransfer || isIssue) ...[
                        _buildTextField(
                          label: 'Source Warehouse',
                          controller: _sWarehouseController,
                          placeholder: 'From Warehouse',
                          onTap: () =>
                              widget.showLinkSearch('Warehouse', (val) {
                                setState(() {
                                  _item['s_warehouse'] = val;
                                  _sWarehouseController.text = val;
                                });
                              }),
                        ),
                      ],
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Target Warehouse',
                        controller: _tWarehouseController,
                        placeholder: 'To Warehouse',
                        onTap: () => widget.showLinkSearch('Warehouse', (val) {
                          setState(() {
                            _item['t_warehouse'] = val;
                            _tWarehouseController.text = val;
                          });
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),

                  _buildInnerCard(
                    title: 'Accounting & Dimensions',
                    children: [
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
                        label: 'Description',
                        controller: _descriptionController,
                        placeholder: 'Description...',
                        onChanged: (val) => _item['description'] = val,
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
              final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quantity must be greater than 0'),
                  ),
                );
                return;
              }
              if (_uomController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select UOM')),
                );
                return;
              }
              if (_stockUomController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select Stock UOM')),
                );
                return;
              }
              final conv =
                  double.tryParse(_convFactorController.text.trim()) ?? 0.0;
              if (conv <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversion Factor must be greater than 0'),
                  ),
                );
                return;
              }
              final isIssue = widget.stockEntryType == 'Material Issue';
              final isTransfer = widget.stockEntryType == 'Material Transfer';
              if (isIssue || isTransfer) {
                final sourceWh = _sWarehouseController.text.trim();
                if (sourceWh.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select Source Warehouse'),
                    ),
                  );
                  return;
                }
              }
              if (isTransfer) {
                final targetWh = _tWarehouseController.text.trim();
                if (targetWh.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select Target Warehouse'),
                    ),
                  );
                  return;
                }
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
