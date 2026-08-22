import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/widgets/link_search_bottom_sheet.dart';
import 'package:cms/core/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/services/project_selection_service.dart';
import 'package:cms/core/services/homepage_reload_notifier.dart';
import '../bloc/stock_entry_form_bloc.dart';
import '../bloc/stock_entry_form_event.dart';
import '../bloc/stock_entry_form_state.dart';
import '../widgets/item_editor_bottom_sheet.dart';

class StockEntryFormPage extends StatelessWidget {
  final String? stockEntryType;
  final String? entryName;

  const StockEntryFormPage({super.key, this.stockEntryType, this.entryName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StockEntryFormBloc>()
        ..add(
          InitializeStockEntryFormEvent(
            entryName: entryName,
            stockEntryType: stockEntryType,
          ),
        ),
      child: _StockEntryFormView(
        stockEntryType: stockEntryType,
        entryName: entryName,
      ),
    );
  }
}

class _StockEntryFormView extends StatefulWidget {
  final String? stockEntryType;
  final String? entryName;

  const _StockEntryFormView({this.stockEntryType, this.entryName});

  @override
  State<_StockEntryFormView> createState() => _StockEntryFormViewState();
}

class _StockEntryFormViewState extends State<_StockEntryFormView> {
  // Form Fields
  String? _namingSeries;
  DateTime? _postingDate;
  TimeOfDay? _postingTime;
  String? _fromWarehouse;
  String? _toWarehouse;
  String? _project;
  String? _costCenter;
  String? _remarks;
  String? _existingServerId;

  String? _customTask;

  // Items Child Table
  List<Map<String, dynamic>> _items = [];

  // Controllers
  final _namingSeriesController = TextEditingController();
  final _postingDateController = TextEditingController();
  final _postingTimeController = TextEditingController();
  final _fromWarehouseController = TextEditingController();
  final _toWarehouseController = TextEditingController();
  final _projectController = TextEditingController();
  final _costCenterController = TextEditingController();
  final _remarksController = TextEditingController();
  final _customTaskController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _namingSeriesController.dispose();
    _postingDateController.dispose();
    _postingTimeController.dispose();
    _fromWarehouseController.dispose();
    _toWarehouseController.dispose();
    _projectController.dispose();
    _costCenterController.dispose();
    _remarksController.dispose();
    _customTaskController.dispose();
    super.dispose();
  }

  void _populateFromDocumentData(Map<String, dynamic>? data) {
    if (data != null) {
      _existingServerId = data['name']?.toString();
      _namingSeries = data['naming_series']?.toString();
      if (_namingSeries == null &&
          (widget.stockEntryType == 'Material Issue' ||
              widget.stockEntryType == 'Material Transfer')) {
        _namingSeries = 'MAT-STE-';
      }
      _fromWarehouse = data['from_warehouse']?.toString();
      _toWarehouse = data['to_warehouse']?.toString();
      _project = data['project']?.toString();
      _costCenter = data['cost_center']?.toString();
      _remarks = data['remarks']?.toString();
      _customTask = data['custom_task']?.toString();

      if (data['posting_date'] != null) {
        _postingDate = DateTime.tryParse(data['posting_date'].toString());
      }
      if (data['posting_time'] != null) {
        final timeStr = data['posting_time'].toString();
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          _postingTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      final rawItems = data['items'] as List? ?? [];
      _items = rawItems.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      // Defaults for new entry
      _postingDate = DateTime.now();
      _postingTime = TimeOfDay.now();
      _project = sl<ProjectSelectionService>().selectedProject;
      if (widget.stockEntryType == 'Material Issue' ||
          widget.stockEntryType == 'Material Transfer') {
        _namingSeries = 'MAT-STE-';
      }
    }

    _namingSeriesController.text = _namingSeries ?? '';
    _fromWarehouseController.text = _fromWarehouse ?? '';
    _toWarehouseController.text = _toWarehouse ?? '';
    _projectController.text = _project ?? '';
    _costCenterController.text = _costCenter ?? '';
    _remarksController.text = _remarks ?? '';
    _customTaskController.text = _customTask ?? '';
    if (_postingDate != null) {
      _postingDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(_postingDate!);
    }
    if (_postingTime != null) {
      _postingTimeController.text =
          '${_postingTime!.hour.toString().padLeft(2, '0')}:${_postingTime!.minute.toString().padLeft(2, '0')}';
    }
  }

  double get _totalQty => _items.fold(
    0.0,
    (sum, item) =>
        sum + (double.tryParse(item['qty']?.toString() ?? '0.0') ?? 0.0),
  );

  double get _totalAmount => _items.fold(0.0, (sum, item) {
    final qty = double.tryParse(item['qty']?.toString() ?? '0.0') ?? 0.0;
    final rate =
        double.tryParse(item['basic_rate']?.toString() ?? '0.0') ?? 0.0;
    return sum + (qty * rate);
  });

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
        _postingDateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
        _postingTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _showLinkSearch(
    String doctype,
    ValueChanged<String> onSelected, {
    List<List<dynamic>>? extraFilters,
  }) async {
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
          extraFilters: extraFilters,
          onSelected: (val, _) {
            Navigator.pop(context);
            onSelected(val);
          },
        );
      },
    );
  }

  void _openItemEditor({int? index}) {
    final initialItem = index != null
        ? Map<String, dynamic>.from(_items[index])
        : {
            'item_code': '',
            'item_name': '',
            'qty': 0.0,
            'uom': 'PCS',
            'stock_uom': 'PCS',
            'conversion_factor': 1.0,
            's_warehouse': _fromWarehouse ?? '',
            't_warehouse': _toWarehouse ?? '',
            'basic_rate': 0.0,
            'amount': 0.0,
            'project': _project ?? '',
            'cost_center': _costCenter ?? '',
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
        return ItemEditorBottomSheet(
          initialItem: initialItem,
          showLinkSearch: _showLinkSearch,
          stockEntryType: widget.stockEntryType,
          project: _project,
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
    setState(() => _items.removeAt(index));
  }

  void _saveDocument(BuildContext context) {
    final isIssue = widget.stockEntryType == 'Material Issue';
    final isTransfer = widget.stockEntryType == 'Material Transfer';
    if (!isIssue &&
        !isTransfer &&
        (_customTask == null || _customTask!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Task'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dateStr = _postingDate != null
        ? DateFormat('yyyy-MM-dd').format(_postingDate!)
        : null;
    final timeStr = _postingTime != null
        ? '${_postingTime!.hour.toString().padLeft(2, '0')}:${_postingTime!.minute.toString().padLeft(2, '0')}:00'
        : null;

    final payload = {
      'naming_series': _namingSeries,
      'stock_entry_type': widget.stockEntryType ?? 'Material Transfer',
      'posting_date': dateStr,
      'posting_time': timeStr,
      'from_warehouse': _fromWarehouse,
      'to_warehouse': _toWarehouse,
      'project': _project,
      'cost_center': _costCenter,
      'remarks': _remarks,
      'custom_task': _customTask,
      'items': _items,
      'total_qty': _totalQty,
      'total_amount': _totalAmount,
    };

    context.read<StockEntryFormBloc>().add(
      SaveStockEntryFormEvent(
        existingServerId: _existingServerId,
        payload: payload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StockEntryFormBloc, StockEntryFormState>(
      listener: (context, state) {
        if (state.status == StockEntryFormStatus.loadSuccess && !_initialized) {
          setState(() {
            _initialized = true;
            _populateFromDocumentData(state.documentData);
          });
        } else if (state.status == StockEntryFormStatus.saveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.stockEntryType ?? 'Stock Entry'} saved successfully',
              ),
            ),
          );
          sl<HomepageReloadNotifier>().notifySave();
          Navigator.pop(context, true);
        } else if (state.status == StockEntryFormStatus.saveFailure ||
            state.status == StockEntryFormStatus.loadFailure) {
          showErrorDialog(
            context,
            state.status == StockEntryFormStatus.saveFailure
                ? 'Save Failed'
                : 'Load Failed',
            state.error ?? 'An error occurred',
          );
        }
      },
      builder: (context, state) {
        final isLoading =
            state.status == StockEntryFormStatus.loading ||
            state.status == StockEntryFormStatus.saving;

        if (state.status == StockEntryFormStatus.loading && !_initialized) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == StockEntryFormStatus.loadFailure && !_initialized) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Error: ${state.error}')),
          );
        }

        final isTransfer = widget.stockEntryType == 'Material Transfer';
        final isIssue = widget.stockEntryType == 'Material Issue';

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
              widget.entryName != null
                  ? 'Edit ${widget.stockEntryType ?? 'Stock Entry'}'
                  : 'New ${widget.stockEntryType ?? 'Stock Entry'}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: isLoading && _initialized
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(sizeContextOf(context, 16)),
                  child: Column(
                    children: [
                      _buildCard(
                        title: 'General Information',
                        icon: Icons.info_outline,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  label: 'Posting Date',
                                  controller: _postingDateController,
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
                                  label: 'Posting Time',
                                  controller: _postingTimeController,
                                  placeholder: 'HR:MM',
                                  suffixIcon: const Icon(
                                    Icons.access_time,
                                    size: 16,
                                  ),
                                  onTap: _selectTime,
                                ),
                              ),
                            ],
                          ),
                          if (isTransfer || isIssue) ...[
                            SizedBox(height: sizeContextOf(context, 16)),
                            _buildTextField(
                              label: 'Default Source Warehouse',
                              controller: _fromWarehouseController,
                              placeholder: 'From Warehouse',
                              onTap: () => _showLinkSearch('Warehouse', (val) {
                                setState(() {
                                  _fromWarehouse = val;
                                  _fromWarehouseController.text = val;
                                });
                              }),
                            ),
                          ],
                          if (isTransfer) ...[
                            SizedBox(height: sizeContextOf(context, 16)),
                            _buildTextField(
                              label: 'Target Warehouse',
                              controller: _toWarehouseController,
                              placeholder: 'To Warehouse',
                              onTap: () => _showLinkSearch('Warehouse', (val) {
                                setState(() {
                                  _toWarehouse = val;
                                  _toWarehouseController.text = val;
                                });
                              }),
                            ),
                          ],
                          if (!isIssue && !isTransfer) ...[
                            SizedBox(height: sizeContextOf(context, 16)),
                            _buildTextField(
                              label: 'Task*',
                              controller: _customTaskController,
                              placeholder: 'Select Task',
                              onTap: () {
                                final List<List<dynamic>> extra = [];
                                if (_project != null && _project!.isNotEmpty) {
                                  extra.add([
                                    'Task',
                                    'project',
                                    '=',
                                    _project!,
                                  ]);
                                }
                                _showLinkSearch('Task', (val) {
                                  setState(() {
                                    _customTask = val;
                                    _customTaskController.text = val;
                                  });
                                }, extraFilters: extra);
                              },
                            ),
                          ],
                          if (!isIssue) ...[
                            SizedBox(height: sizeContextOf(context, 16)),
                            _buildTextField(
                              label: 'Cost Center',
                              controller: _costCenterController,
                              placeholder: 'Select cost center',
                              onTap: () =>
                                  _showLinkSearch('Cost Center', (val) {
                                    setState(() {
                                      _costCenter = val;
                                      _costCenterController.text = val;
                                    });
                                  }),
                            ),
                            SizedBox(height: sizeContextOf(context, 16)),
                            _buildTextField(
                              label: 'Remarks',
                              controller: _remarksController,
                              placeholder: 'Enter remarks...',
                              onChanged: (val) => _remarks = val,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 16)),

                      // Items Child Table
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
                                      const Icon(
                                        Icons.list_alt,
                                        size: 18,
                                        color: Colors.black54,
                                      ),
                                      SizedBox(
                                        width: sizeContextOf(context, 8),
                                      ),
                                      const Expanded(
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
                                child: const Center(
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
                                separatorBuilder: (_, index) =>
                                    SizedBox(height: sizeContextOf(context, 8)),
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final name =
                                      item['item_name']?.toString() ?? '';
                                  final code =
                                      item['item_code']?.toString() ?? '';
                                  final qty =
                                      double.tryParse(
                                        item['qty']?.toString() ?? '0',
                                      ) ??
                                      0.0;
                                  final rate =
                                      double.tryParse(
                                        item['basic_rate']?.toString() ?? '0',
                                      ) ??
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
                                      padding: EdgeInsets.all(
                                        sizeContextOf(context, 12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name.isNotEmpty
                                                      ? name
                                                      : 'Unnamed Item',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (code.isNotEmpty) ...[
                                                  SizedBox(
                                                    height: sizeContextOf(
                                                      context,
                                                      4,
                                                    ),
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
                                                  height: sizeContextOf(
                                                    context,
                                                    8,
                                                  ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'INR ${amount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF4A8B5F),
                                                ),
                                              ),
                                              SizedBox(
                                                height: sizeContextOf(
                                                  context,
                                                  8,
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
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () =>
                                                        _openItemEditor(
                                                          index: index,
                                                        ),
                                                  ),
                                                  SizedBox(
                                                    width: sizeContextOf(
                                                      context,
                                                      12,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 20,
                                                      color: Colors.redAccent,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () =>
                                                        _removeItem(index),
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

                      // Totals
                      _buildCard(
                        title: 'Totals',
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

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFCDE0D5),
                                ),
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
                              onPressed: () => _saveDocument(context),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: Text(
                                'Save ${widget.stockEntryType ?? 'Stock Entry'}',
                              ),
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
      },
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
