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
import '../widgets/purchase_receipt_item_editor.dart';

class PurchaseReceiptFormPage extends StatefulWidget {
  final String? receiptName;
  const PurchaseReceiptFormPage({super.key, this.receiptName});

  @override
  State<PurchaseReceiptFormPage> createState() =>
      _PurchaseReceiptFormPageState();
}

class _PurchaseReceiptFormPageState extends State<PurchaseReceiptFormPage> {
  bool _isLoading = true;
  String? _error;
  Document? _document;

  // Form Fields
  String? _namingSeries;
  String? _supplier;
  DateTime? _postingDate;
  TimeOfDay? _postingTime;

  String? _costCenter;
  String? _site;
  String? _project;
  String? _currency = 'INR';
  String? _setWarehouse;
  String? _rejectedWarehouse;
  String? _customSiteEngineer;

  // Items Child Table
  List<Map<String, dynamic>> _items = [];

  // Totals & Status
  String _status = 'Draft';

  // Controllers for general inputs
  final _namingSeriesController = TextEditingController();
  final _supplierController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  final _costCenterController = TextEditingController();
  final _siteController = TextEditingController();
  final _projectController = TextEditingController();
  final _currencyController = TextEditingController(text: 'INR');
  final _setWarehouseController = TextEditingController();
  final _rejectedWarehouseController = TextEditingController();
  final _customSiteEngineerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _namingSeriesController.dispose();
    _supplierController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _costCenterController.dispose();
    _siteController.dispose();
    _projectController.dispose();
    _currencyController.dispose();
    _setWarehouseController.dispose();
    _rejectedWarehouseController.dispose();
    _customSiteEngineerController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final sdk = sl<FrappeSDK>();
      Document? doc;
      if (widget.receiptName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName(
            'Purchase Receipt',
            widget.receiptName!,
          );
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Purchase Receipt',
            serverId: widget.receiptName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(
            widget.receiptName!,
            'Purchase Receipt',
          );
        }
      }

      if (doc != null) {
        final data = doc.data;
        _namingSeries = data['naming_series']?.toString();
        _supplier = data['supplier']?.toString();

        if (data['posting_date'] != null) {
          _postingDate = DateTime.tryParse(data['posting_date'].toString());
        }

        if (data['posting_time'] != null) {
          final timeStr = data['posting_time'].toString();
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            _postingTime = TimeOfDay(hour: hour, minute: minute);
          }
        }

        _costCenter = data['cost_center']?.toString();
        _site = data['site']?.toString();
        _project = data['project']?.toString();
        _currency = data['currency']?.toString() ?? 'INR';
        _status = data['status']?.toString() ?? 'Draft';
        _setWarehouse = data['set_warehouse']?.toString();
        _rejectedWarehouse = data['rejected_warehouse']?.toString();
        _customSiteEngineer = data['custom_site_engineer']?.toString();

        final rawItems = data['items'] as List? ?? [];
        _items = rawItems
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        // Update controllers
        _namingSeriesController.text = _namingSeries ?? '';
        _supplierController.text =
            data['supplier_name']?.toString() ?? _supplier ?? '';
        if (_postingDate != null) {
          _dateController.text = DateFormat('yyyy-MM-dd').format(_postingDate!);
        }
        if (_postingTime != null) {
          _timeController.text =
              '${_postingTime!.hour.toString().padLeft(2, '0')}:${_postingTime!.minute.toString().padLeft(2, '0')}';
        }
        _costCenterController.text = _costCenter ?? '';
        _siteController.text = _site ?? '';
        _projectController.text = _project ?? '';
        _currencyController.text = _currency ?? '';
        _setWarehouseController.text = _setWarehouse ?? '';
        _rejectedWarehouseController.text = _rejectedWarehouse ?? '';
        _customSiteEngineerController.text = _customSiteEngineer ?? '';
      } else {
        // Defaults for new receipt
        _namingSeries = 'PR-.YY.-';
        _namingSeriesController.text = 'PR-.YY.-';
        _postingDate = DateTime.now();
        _postingTime = TimeOfDay.now();
        _dateController.text = DateFormat('yyyy-MM-dd').format(_postingDate!);
        _timeController.text =
            '${_postingTime!.hour.toString().padLeft(2, '0')}:${_postingTime!.minute.toString().padLeft(2, '0')}';

        final selectionService = sl<ProjectSelectionService>();
        _project = selectionService.selectedProject;
        _projectController.text = _project ?? '';
        _site = selectionService.selectedSite;
        _siteController.text = _site ?? '';
      }

      if (_customSiteEngineer != null && _customSiteEngineer!.isNotEmpty) {
        try {
          final empData = await sdk.api.doctype.getByName('Employee', _customSiteEngineer!);
          final empName = empData['employee_name']?.toString();
          if (empName != null) {
            _customSiteEngineerController.text = empName;
          }
        } catch (_) {}
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
      final qty = double.tryParse(item['qty']?.toString() ?? '0.0') ?? 0.0;
      final rate = double.tryParse(item['rate']?.toString() ?? '0.0') ?? 0.0;
      return sum + (qty * rate);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _postingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _postingDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _postingTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _postingTime = picked;
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
          onSelected: (name, label) {
            Navigator.pop(context);
            onSelected(name);
          },
        );
      },
    );
  }

  Future<void> _showSupplierSearch(
    void Function(String name, String? label) onSelected,
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
          doctype: 'Supplier',
          onSelected: (name, label) {
            Navigator.pop(context);
            onSelected(name, label);
          },
        );
      },
    );
  }

  Future<void> _showEmployeeSearch(
    void Function(String name, String? label) onSelected,
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
          doctype: 'Employee',
          onSelected: (name, label) {
            Navigator.pop(context);
            onSelected(name, label);
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
            'rejected_qty': 0.0,
            'total_qty': 0.0,
            'uom': 'PCS',
            'stock_uom': 'PCS',
            'conversion_factor': 1.0,
            'rate': 0.0,
            'warehouse': _setWarehouse ?? 'Main Warehouse',
            'rejected_warehouse': _rejectedWarehouse ?? '',
            'project': _project ?? '',
            'site': _site ?? '',
            'cost_center': _costCenter ?? '',
          };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PurchaseReceiptItemEditor(
          initialItem: initialItem,
          showLinkSearch: _showLinkSearch,
          defaultWarehouse: _setWarehouse,
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
    if (_supplier == null || _supplier!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a Supplier')));
      return;
    }

    if (_postingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Posting Date')),
      );
      return;
    }

    if (_postingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Posting Time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final sdk = sl<FrappeSDK>();
    final dateStr = _postingDate != null
        ? DateFormat('yyyy-MM-dd').format(_postingDate!)
        : null;
    final timeStr = _postingTime != null
        ? '${_postingTime!.hour.toString().padLeft(2, '0')}:${_postingTime!.minute.toString().padLeft(2, '0')}:00'
        : null;

    final payload = {
      'naming_series': _namingSeries,
      'supplier': _supplier,
      'posting_date': dateStr,
      'posting_time': timeStr,
      'cost_center': _costCenter,
      'site': _site,
      'project': _project,
      'currency': _currency,
      'status': _status,
      'set_warehouse': _setWarehouse,
      'rejected_warehouse': _rejectedWarehouse,
      'custom_site_engineer': _customSiteEngineer,
      'items': _items,
      'total_qty': _totalQty,
      'grand_total': _totalAmount,
      'total': _totalAmount,
    };

    try {
      if (_document == null) {
        // Create new doc
        final result = await sdk.api.document.createDocument(
          'Purchase Receipt',
          payload,
        );
        final serverName =
            result['name']?.toString() ?? result['docname']?.toString();
        if (serverName != null) {
          final merged = Map<String, dynamic>.from(payload)
            ..['name'] = serverName;
          try {
            await sdk.api.document.submitDocument(
              'Purchase Receipt',
              serverName,
            );
            merged['docstatus'] = 1;
          } catch (e) {
            merged['docstatus'] = 0;
            await sdk.repository.saveServerDocument(
              doctype: 'Purchase Receipt',
              serverId: serverName,
              data: merged,
            );
            rethrow;
          }
          await sdk.repository.saveServerDocument(
            doctype: 'Purchase Receipt',
            serverId: serverName,
            data: merged,
          );
        }
      } else {
        // Update existing doc
        final existingData = Map<String, dynamic>.from(_document!.data)
          ..addAll(payload);
        await sdk.api.document.updateDocument(
          'Purchase Receipt',
          _document!.serverId!,
          existingData,
        );
        final docstatus = int.tryParse(existingData['docstatus']?.toString() ?? '0') ?? 0;
        if (docstatus == 0) {
          try {
            await sdk.api.document.submitDocument(
              'Purchase Receipt',
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
          const SnackBar(content: Text('Purchase Receipt saved successfully')),
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
        title: const Text(
          'New Purchase Receipt',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
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
                _buildTextField(
                  label: 'Supplier *',
                  controller: _supplierController,
                  placeholder: 'Enter supplier name',
                  onTap: () => _showSupplierSearch((val, label) {
                    setState(() {
                      _supplier = val;
                      _supplierController.text = label ?? val;
                    });
                  }),
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        label: 'Posting Date *',
                        controller: _dateController,
                        placeholder: 'YYYY-MM-DD',
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        onTap: _selectDate,
                      ),
                    ),
                    SizedBox(width: sizeContextOf(context, 12)),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        label: 'Posting Time *',
                        controller: _timeController,
                        placeholder: 'HR:MM',
                        suffixIcon: const Icon(Icons.access_time, size: 16),
                        onTap: _selectTime,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                _buildTextField(
                  label: 'Accepted Warehouse',
                  controller: _setWarehouseController,
                  placeholder: 'Select accepted warehouse',
                  onTap: () => _showLinkSearch('Warehouse', (val) {
                    setState(() {
                      _setWarehouse = val;
                      _setWarehouseController.text = val;
                    });
                  }),
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                _buildTextField(
                  label: 'Rejected Warehouse',
                  controller: _rejectedWarehouseController,
                  placeholder: 'Select rejected warehouse',
                  onTap: () => _showLinkSearch('Warehouse', (val) {
                    setState(() {
                      _rejectedWarehouse = val;
                      _rejectedWarehouseController.text = val;
                    });
                  }),
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                _buildTextField(
                  label: 'Site Engineer',
                  controller: _customSiteEngineerController,
                  placeholder: 'Select site engineer',
                  onTap: () => _showEmployeeSearch((name, label) {
                    setState(() {
                      _customSiteEngineer = name;
                      _customSiteEngineerController.text = label ?? name;
                    });
                  }),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 16)),

            // 2. Accounting Dimension Card
            _buildCard(
              title: 'Accounting Dimension',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildTextField(
                  label: 'Cost Center',
                  controller: _costCenterController,
                  placeholder: 'Enter cost center',
                  onTap: () => _showLinkSearch('Cost Center', (val) {
                    setState(() {
                      _costCenter = val;
                      _costCenterController.text = val;
                    });
                  }),
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                _buildTextField(
                  label: 'Site',
                  controller: _siteController,
                  placeholder: 'Enter site location',
                  onTap: () => _showLinkSearch('Site', (val) {
                    setState(() {
                      _site = val;
                      _siteController.text = val;
                    });
                  }),
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                _buildTextField(
                  label: 'Project',
                  controller: _projectController,
                  placeholder: 'Select project',
                  onTap: () => _showLinkSearch('Project', (val) {
                    setState(() {
                      _project = val;
                      _projectController.text = val;
                    });
                  }),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 16)),

            // 3. Items Child Table Container
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
                      Row(
                        children: [
                          Icon(Icons.list_alt, size: 18, color: Colors.black54),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Text(
                            'Items Child Table',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
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
                        final rate =
                            double.tryParse(item['rate']?.toString() ?? '0') ??
                            0.0;
                        final uom = item['uom']?.toString() ?? '';
                        final amount = qty * rate;
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
                                        '${qty.toStringAsFixed(2)} $uom x ${rate.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_currency ?? 'INR'} ${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF4A8B5F),
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 8)),
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
                                        SizedBox(
                                          width: sizeContextOf(context, 12),
                                        ),
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

            // 4. Totals & Status Card
            _buildCard(
              title: 'Totals & Status',
              icon: Icons.summarize_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        label: 'Total Qty',
                        value: _totalQty.toStringAsFixed(2),
                      ),
                    ),
                    SizedBox(width: sizeContextOf(context, 12)),
                    Expanded(
                      child: _buildReadOnlyField(
                        label: 'Total Amount',
                        value: _totalAmount.toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 24)),

            // Bottom Buttons
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: sizeContextOf(context, 12)),
                ),
                // Expanded(
                // child: OutlinedButton(
                //   onPressed: () => Navigator.pop(context),
                //   style: OutlinedButton.styleFrom(
                //     side: const BorderSide(color: Color(0xFFCDE0D5)),
                //     padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 16)),
                //     backgroundColor: Colors.white,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   child: const Text(
                //     'Cancel',
                //     style: TextStyle(
                //       color: Colors.black87,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                // ),
                // SizedBox(width: sizeContextOf(context, 12)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveDocument,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Save Receipt'),
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
                Padding(
                  padding: EdgeInsets.only(right: sizeContextOf(context, 12)),
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
