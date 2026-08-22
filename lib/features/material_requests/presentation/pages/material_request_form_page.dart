import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/widgets/link_search_bottom_sheet.dart';
import 'package:cms/core/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/services/project_selection_service.dart';
import 'package:cms/core/services/homepage_reload_notifier.dart';
import '../widgets/material_request_item_editor.dart';

class MaterialRequestFormPage extends StatefulWidget {
  final String? requestName;
  const MaterialRequestFormPage({super.key, this.requestName});

  @override
  State<MaterialRequestFormPage> createState() =>
      _MaterialRequestFormPageState();
}

class _MaterialRequestFormPageState extends State<MaterialRequestFormPage> {
  bool _isLoading = true;
  String? _error;
  Document? _document;

  // Form Fields
  String? _namingSeries;
  String? _materialRequestType;
  DateTime? _transactionDate;
  DateTime? _scheduleDate;
  String? _buyingPriceList;
  String? _setWarehouse;
  String? _setFromWarehouse;

  // Items Child Table
  List<Map<String, dynamic>> _items = [];

  // Controllers for general inputs
  final _namingSeriesController = TextEditingController();
  final _materialRequestTypeController = TextEditingController();
  final _transactionDateController = TextEditingController();
  final _scheduleDateController = TextEditingController();
  final _buyingPriceListController = TextEditingController();
  final _setWarehouseController = TextEditingController();
  final _setFromWarehouseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _namingSeriesController.dispose();
    _materialRequestTypeController.dispose();
    _transactionDateController.dispose();
    _scheduleDateController.dispose();
    _buyingPriceListController.dispose();
    _setWarehouseController.dispose();
    _setFromWarehouseController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final sdk = sl<FrappeSDK>();
      Document? doc;
      if (widget.requestName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName(
            'Material Request',
            widget.requestName!,
          );
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Material Request',
            serverId: widget.requestName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(
            widget.requestName!,
            'Material Request',
          );
        }
      }

      if (doc != null) {
        final data = doc.data;
        _namingSeries = data['naming_series']?.toString();
        _materialRequestType = data['material_request_type']?.toString();
        _setWarehouse = data['set_warehouse']?.toString();
        _setFromWarehouse = data['set_from_warehouse']?.toString();
        _buyingPriceList = data['buying_price_list']?.toString();

        if (data['transaction_date'] != null) {
          _transactionDate = DateTime.tryParse(
            data['transaction_date'].toString(),
          );
        }
        if (data['schedule_date'] != null) {
          _scheduleDate = DateTime.tryParse(data['schedule_date'].toString());
        }

        final rawItems = data['items'] as List? ?? [];
        _items = rawItems
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        // Update controllers
        _namingSeriesController.text = _namingSeries ?? '';
        _materialRequestTypeController.text = _materialRequestType ?? '';
        _setWarehouseController.text = _setWarehouse ?? '';
        _setFromWarehouseController.text = _setFromWarehouse ?? '';
        _buyingPriceListController.text = _buyingPriceList ?? '';

        if (_transactionDate != null) {
          _transactionDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(_transactionDate!);
        }
        if (_scheduleDate != null) {
          _scheduleDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(_scheduleDate!);
        }
      } else {
        // Defaults for new request
        _namingSeries = 'MAT-MR-.YYYY.-';
        _namingSeriesController.text = 'MAT-MR-.YYYY.-';
        _transactionDate = DateTime.now();
        _transactionDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_transactionDate!);
        _scheduleDate = DateTime.now();
        _scheduleDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_scheduleDate!);
      }

      setState(() {
        _document = doc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalQty {
    return _items.fold(0.0, (sum, item) {
      final qty = double.tryParse(item['qty']?.toString() ?? '0.0') ?? 0.0;
      return sum + qty;
    });
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) {
      final amount = double.tryParse(item['amount']?.toString() ?? '0.0') ?? 0.0;
      return sum + amount;
    });
  }

  Future<void> _selectTransactionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _transactionDate = picked;
        _transactionDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(picked);
      });
    }
  }

  Future<void> _selectScheduleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _scheduleDate = picked;
        _scheduleDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _showLinkSearch(
    String doctype,
    ValueChanged<String> onSelected,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return LinkSearchBottomSheet(
          doctype: doctype,
          onSelected: (val, _) {
            Navigator.pop(context);
            onSelected(val);
          },
        );
      },
    );
  }

  void _openItemEditor({int? index}) {
    final Map<String, dynamic> initialItem = index != null
        ? Map<String, dynamic>.from(_items[index])
        : {
            'item_code': '',
            'item_name': '',
            'qty': 0.0,
            'uom': 'PCS',
            'stock_uom': 'PCS',
            'conversion_factor': 1.0,
            'warehouse': _setWarehouse ?? 'Main Warehouse',
            'rate': 0.0,
            'project': sl<ProjectSelectionService>().selectedProject ?? '',
            'cost_center': '',
            'gst_hsn_code': '',
            'expense_account': '',
            'wip_composite_asset': '',
            'manufacturer': '',
            'bom_no': '',
            'description': '',
          };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return MaterialRequestItemEditor(
          initialItem: initialItem,
          showLinkSearch: _showLinkSearch,
          onSave: (savedItem) {
            setState(() {
              if (index != null) {
                _items[index] = savedItem;
              } else {
                _items.add(savedItem);
              }
            });
          },
        );
      },
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveDocument() async {
    if (_materialRequestType == null || _materialRequestType!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a Purpose')));
      return;
    }

    if (_transactionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Transaction Date')),
      );
      return;
    }

    if (_scheduleDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Required By date')),
      );
      return;
    }

    if (_setWarehouse == null || _setWarehouse!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Set Target Warehouse')),
      );
      return;
    }

    if (_materialRequestType == 'Material Transfer' &&
        (_setFromWarehouse == null || _setFromWarehouse!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Set Source Warehouse')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final sdk = sl<FrappeSDK>();
    final transactionDateStr = _transactionDate != null
        ? DateFormat('yyyy-MM-dd').format(_transactionDate!)
        : null;
    final scheduleDateStr = _scheduleDate != null
        ? DateFormat('yyyy-MM-dd').format(_scheduleDate!)
        : null;

    final payload = {
      'naming_series': _namingSeries,
      'material_request_type': _materialRequestType,
      'transaction_date': transactionDateStr,
      'schedule_date': scheduleDateStr,
      'buying_price_list': _buyingPriceList,
      'set_warehouse': _setWarehouse,
      'set_from_warehouse': _setFromWarehouse,
      'items': _items,
    };

    try {
      if (_document == null) {
        // Create new doc
        final result = await sdk.api.document.createDocument(
          'Material Request',
          payload,
        );
        final serverName =
            result['name']?.toString() ?? result['docname']?.toString();
        if (serverName != null) {
          final merged = Map<String, dynamic>.from(payload)
            ..['name'] = serverName;
          try {
            await sdk.api.document.submitDocument(
              'Material Request',
              serverName,
            );
            merged['docstatus'] = 1;
          } catch (e) {
            merged['docstatus'] = 0;
            await sdk.repository.saveServerDocument(
              doctype: 'Material Request',
              serverId: serverName,
              data: merged,
            );
            rethrow;
          }
          await sdk.repository.saveServerDocument(
            doctype: 'Material Request',
            serverId: serverName,
            data: merged,
          );
        }
      } else {
        // Update existing doc
        final existingData = Map<String, dynamic>.from(_document!.data)
          ..addAll(payload);
        await sdk.api.document.updateDocument(
          'Material Request',
          _document!.serverId!,
          existingData,
        );
        final docstatus = int.tryParse(existingData['docstatus']?.toString() ?? '0') ?? 0;
        if (docstatus == 0) {
          try {
            await sdk.api.document.submitDocument(
              'Material Request',
              _document!.serverId!,
            );
            existingData['docstatus'] = 1;
          } catch (e) {
            existingData['docstatus'] = 0;
            await sdk.repository.updateDocumentData(
              _document!.localId,
              existingData,
            );
            rethrow;
          }
        }
        await sdk.repository.updateDocumentData(
          _document!.localId,
          existingData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material Request saved successfully')),
        );
        sl<HomepageReloadNotifier>().notifySave();
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorDialog(context, 'Save Failed', e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.requestName != null
              ? 'Edit Material Request'
              : 'New Material Request',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(sizeContextOf(context, 16)),
        child: Column(
          children: [
            // 1. General Information Card
            _buildCard(
              title: 'General Information',
              icon: Icons.info_outline,
              children: [
                _buildDropdownField(
                  label: 'Purpose *',
                  value:
                      _materialRequestType != null &&
                          [
                            'Purchase',
                            'Material Transfer',
                            'Material Issue',
                            'Manufacture',
                            'Customer Provided',
                          ].contains(_materialRequestType)
                      ? _materialRequestType
                      : null,
                  items: const [
                    'Purchase',
                    'Material Transfer',
                    'Material Issue',
                    'Manufacture',
                    'Customer Provided',
                  ],
                  onChanged: (val) {
                    setState(() {
                      _materialRequestType = val;
                      if (val != null) {
                        _materialRequestTypeController.text = val;
                      }
                      if (val != 'Material Transfer') {
                        _setFromWarehouse = null;
                        _setFromWarehouseController.clear();
                      }
                    });
                  },
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Transaction Date *',
                        controller: _transactionDateController,
                        placeholder: 'YYYY-MM-DD',
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        onTap: _selectTransactionDate,
                      ),
                    ),
                    SizedBox(width: sizeContextOf(context, 12)),
                    Expanded(
                      child: _buildTextField(
                        label: 'Required By *',
                        controller: _scheduleDateController,
                        placeholder: 'YYYY-MM-DD',
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        onTap: _selectScheduleDate,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                _buildTextField(
                  label: 'Set Target Warehouse',
                  controller: _setWarehouseController,
                  placeholder: 'Select warehouse',
                  onTap: () => _showLinkSearch('Warehouse', (val) {
                    setState(() {
                      _setWarehouse = val;
                      _setWarehouseController.text = val;
                    });
                  }),
                ),
                if (_materialRequestType == 'Material Transfer') ...[
                  SizedBox(height: sizeContextOf(context, 16)),
                  _buildTextField(
                    label: 'Set Source Warehouse',
                    controller: _setFromWarehouseController,
                    placeholder: 'Select warehouse',
                    onTap: () => _showLinkSearch('Warehouse', (val) {
                      setState(() {
                        _setFromWarehouse = val;
                        _setFromWarehouseController.text = val;
                      });
                    }),
                  ),
                ],
                SizedBox(height: sizeContextOf(context, 16)),
                _buildTextField(
                  label: 'Buying Price List',
                  controller: _buyingPriceListController,
                  placeholder: 'Select price list',
                  onTap: () => _showLinkSearch('Price List', (val) {
                    setState(() {
                      _buyingPriceList = val;
                      _buyingPriceListController.text = val;
                    });
                  }),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 16)),

            // 2. Items Child Table Container
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFEA),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(sizeContextOf(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 18,
                              color: Colors.black54,
                            ),
                            SizedBox(width: sizeContextOf(context, 8)),
                            Expanded(
                              child: Text(
                                'Items Child Table',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: sizeContextOf(context, 8)),
                      TextButton.icon(
                        onPressed: () => _openItemEditor(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Item'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A8B5F),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),
                  if (_items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: sizeContextOf(context, 24),
                      ),
                      child: Center(
                        child: Text(
                          'No items added yet.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: sizeContextOf(context, 8)),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final name = item['item_name']?.toString() ?? '';
                        final code = item['item_code']?.toString() ?? '';
                        final qty =
                            double.tryParse(item['qty']?.toString() ?? '0') ??
                            0.0;
                        final uom = item['uom']?.toString() ?? '';
                        return InkWell(
                          onTap: () => _openItemEditor(index: index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCDE0D5),
                              ),
                            ),
                            padding: EdgeInsets.all(sizeContextOf(context, 12)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isNotEmpty ? name : 'Unnamed Item',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (code.isNotEmpty) ...[
                                        SizedBox(
                                          height: sizeContextOf(context, 4),
                                        ),
                                        Text(
                                          code,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                      SizedBox(
                                        height: sizeContextOf(context, 8),
                                      ),
                                      Text(
                                        'Qty: ${qty.toStringAsFixed(2)} $uom',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: Colors.blueGrey,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _openItemEditor(index: index),
                                    ),
                                    SizedBox(width: sizeContextOf(context, 12)),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Colors.redAccent,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: sizeContextOf(context, 16)),

            // 3. Totals
            _buildCard(
              title: 'Totals',
              icon: Icons.summarize_outlined,
              children: [
                _buildReadOnlyField(
                  label: 'Total Qty',
                  value: _totalQty.toStringAsFixed(2),
                ),
                SizedBox(height: sizeContextOf(context, 12)),
                _buildReadOnlyField(
                  label: 'Total Amount',
                  value: _totalAmount.toStringAsFixed(2),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 24)),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCDE0D5)),
                      padding: EdgeInsets.symmetric(
                        vertical: sizeContextOf(context, 16),
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 12)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveDocument,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Save Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: sizeContextOf(context, 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.black54),
                SizedBox(width: sizeContextOf(context, 8)),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 16)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
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
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: sizeContextOf(context, 12),
                  vertical: sizeContextOf(context, 12),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: suffixIcon != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          right: sizeContextOf(context, 8.0),
                        ),
                        child: suffixIcon,
                      )
                    : null,
                suffixIconConstraints: suffixIcon != null
                    ? const BoxConstraints(minWidth: 24, minHeight: 24)
                    : null,
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: sizeContextOf(context, 12),
              vertical: sizeContextOf(context, 12),
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCDE0D5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryContainer,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: sizeContextOf(context, 6)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: sizeContextOf(context, 12),
            vertical: sizeContextOf(context, 12),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCDE0D5)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
