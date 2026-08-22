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

class EquipmentUsageFormPage extends StatefulWidget {
  final String? usageName;
  const EquipmentUsageFormPage({super.key, this.usageName});

  @override
  State<EquipmentUsageFormPage> createState() => _EquipmentUsageFormPageState();
}

class _EquipmentUsageFormPageState extends State<EquipmentUsageFormPage> {
  bool _isLoading = true;
  String? _error;
  Document? _document;
  dynamic _meta;

  // Form Fields
  String? _project;
  DateTime? _siteDate;
  String? _company;
  String? _shift;

  // Items Child Table
  List<Map<String, dynamic>> _items = [];

  // Controllers for general inputs
  final _projectController = TextEditingController();
  final _siteDateController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _projectController.dispose();
    _siteDateController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final sdk = sl<FrappeSDK>();
      final meta = await sdk.meta.getMeta('Equipment Usage', forceRefresh: true);
      Document? doc;
      if (widget.usageName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName(
            'Equipment Usage',
            widget.usageName!,
          );
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Equipment Usage',
            serverId: widget.usageName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(
            widget.usageName!,
            'Equipment Usage',
          );
        }
      }

      if (doc != null) {
        final data = doc.data;
        _project = data['project']?.toString();
        _company = data['company']?.toString();
        _shift = data['shift']?.toString() ?? 'Day';

        if (data['site_date'] != null) {
          _siteDate = DateTime.tryParse(data['site_date'].toString());
        }

        final rawItems = data['equipment_usage_details'] as List? ?? [];
        _items = rawItems
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        // Update controllers
        _projectController.text = _project ?? '';
        _companyController.text = _company ?? '';

        if (_siteDate != null) {
          _siteDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(_siteDate!);
        }
      } else {
        // Defaults for new equipment usage
        _siteDate = DateTime.now();
        _siteDateController.text = DateFormat('yyyy-MM-dd').format(_siteDate!);
        _shift = 'Day';

        final selectionService = sl<ProjectSelectionService>();
        _project = selectionService.selectedProject;
        _projectController.text = _project ?? '';
      }

      setState(() {
        _meta = meta;
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

  int get _totalEquipment {
    return _items.length;
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) {
      final amount =
          double.tryParse(item['amount']?.toString() ?? '0.0') ?? 0.0;
      return sum + amount;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _siteDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _siteDate = picked;
        _siteDateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
    final Map<String, dynamic> initialItem = index != null
        ? Map<String, dynamic>.from(_items[index])
        : {
            'task': '',
            'subtask': '',
            'equipment_item': '',
            'uom': 'Nos',
            'quantity': 1.0,
            'rate': 0.0,
            'amount': 0.0,
            'billed': false,
            'paid': false,
            'contractor': '',
            'opening_reading': 0.0,
            'closing_reading': 0.0,
            'diesel_filledin_ltr': 0.0,
            'working_hrs': 8.0,
          };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ItemEditorBottomSheet(
          initialItem: initialItem,
          project: _project,
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

  List<String> getSelectOptions(String fieldname) {
    if (_meta == null) {
      if (fieldname == 'shift') return ['Day', 'Night'];
      return [];
    }
    try {
      final field = _meta!.fields.firstWhere((f) => f.fieldname == fieldname);
      if (field.options != null && field.options!.trim().isNotEmpty) {
        return field.options!
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    if (fieldname == 'shift') return ['Day', 'Night'];
    return [];
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: sizeContextOf(context, 6)),
        Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCDE0D5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: Text(
                'Select $label',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveDocument() async {
    if (_siteDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Site Date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final sdk = sl<FrappeSDK>();
    final dateStr = _siteDate != null
        ? DateFormat('yyyy-MM-dd').format(_siteDate!)
        : null;

    final payload = {
      'project': _project,
      'site_date': dateStr,
      'company': _company,
      'shift': _shift,
      'equipment_usage_details': _items,
    };

    try {
      if (_document == null) {
        // Create new doc
        final result = await sdk.api.document.createDocument(
          'Equipment Usage',
          payload,
        );
        final serverName =
            result['name']?.toString() ?? result['docname']?.toString();
        if (serverName != null) {
          final merged = Map<String, dynamic>.from(payload)
            ..['name'] = serverName;
          try {
            await sdk.api.document.submitDocument(
              'Equipment Usage',
              serverName,
            );
            merged['docstatus'] = 1;
          } catch (e) {
            merged['docstatus'] = 0;
            await sdk.repository.saveServerDocument(
              doctype: 'Equipment Usage',
              serverId: serverName,
              data: merged,
            );
            rethrow;
          }
          await sdk.repository.saveServerDocument(
            doctype: 'Equipment Usage',
            serverId: serverName,
            data: merged,
          );
        }
      } else {
        // Update existing doc
        final existingData = Map<String, dynamic>.from(_document!.data)
          ..addAll(payload);
        await sdk.api.document.updateDocument(
          'Equipment Usage',
          _document!.serverId!,
          existingData,
        );
        final docstatus = int.tryParse(existingData['docstatus']?.toString() ?? '0') ?? 0;
        if (docstatus == 0) {
          try {
            await sdk.api.document.submitDocument(
              'Equipment Usage',
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
          const SnackBar(content: Text('Equipment Usage saved successfully')),
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
          widget.usageName != null
              ? 'Edit Equipment Usage'
              : 'New Equipment Usage',
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
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        label: 'Site Date *',
                        controller: _siteDateController,
                        placeholder: 'YYYY-MM-DD',
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        onTap: _selectDate,
                      ),
                    ),
                    SizedBox(width: sizeContextOf(context, 8)),
                    Expanded(
                      flex: 2,
                      child: _buildDropdownField(
                        label: 'Shift',
                        value: _shift,
                        items: getSelectOptions('shift'),
                        onChanged: (val) {
                          setState(() {
                            _shift = val;
                          });
                        },
                      ),
                    ),
                  ],
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
                            const Icon(
                              Icons.list_alt,
                              size: 18,
                              color: Colors.black54,
                            ),
                            SizedBox(width: sizeContextOf(context, 8)),
                            const Expanded(
                              child: Text(
                                'Equipment Item',
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
                        label: const Text('Add Equipment'),
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
                          'No equipment entries added yet.',
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
                        final contractor = item['contractor']?.toString() ?? '';
                        final eqItem = item['equipment_item']?.toString() ?? '';
                        final qty =
                            double.tryParse(item['quantity']?.toString() ?? '1') ??
                            1.0;
                        final workingHrs =
                            double.tryParse(item['working_hrs']?.toString() ?? '8') ??
                            8.0;
                        final amount =
                            double.tryParse(
                              item['amount']?.toString() ?? '0',
                            ) ??
                            0.0;
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
                                        eqItem.isNotEmpty ? eqItem : 'No Equipment',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (contractor.isNotEmpty) ...[
                                        SizedBox(
                                          height: sizeContextOf(context, 4),
                                        ),
                                        Text(
                                          'Contractor: $contractor',
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
                                        'Qty: ${qty.toStringAsFixed(1)} x ${workingHrs.toStringAsFixed(1)} hrs',
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
                                      'INR ${amount.toStringAsFixed(2)}',
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

            // 3. Totals Card
            _buildCard(
              title: 'Totals',
              icon: Icons.summarize_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        label: 'Total Equipment Logs',
                        value: _totalEquipment.toString(),
                      ),
                    ),
                    SizedBox(width: sizeContextOf(context, 12)),
                    Expanded(
                      child: _buildReadOnlyField(
                        label: 'Total Amount',
                        value: 'INR ${_totalAmount.toStringAsFixed(2)}',
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
                    label: const Text('Save Usage'),
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

class _ItemEditorBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialItem;
  final String? project;
  final Function(Map<String, dynamic>) onSave;
  final Function(
    String doctype,
    ValueChanged<String> onSelected, {
    List<List<dynamic>>? extraFilters,
  })
  showLinkSearch;

  const _ItemEditorBottomSheet({
    required this.initialItem,
    required this.project,
    required this.onSave,
    required this.showLinkSearch,
  });

  @override
  State<_ItemEditorBottomSheet> createState() => _ItemEditorBottomSheetState();
}

class _ItemEditorBottomSheetState extends State<_ItemEditorBottomSheet> {
  late Map<String, dynamic> _item;

  late TextEditingController _taskController;
  late TextEditingController _parentTaskController;
  late TextEditingController _taskSubjectController;
  late TextEditingController _parentTaskSubjectController;
  late TextEditingController _openingReadingController;
  late TextEditingController _closingReadingController;
  late TextEditingController _dieselFilledInLtrController;
  late TextEditingController _qtyController;
  late TextEditingController _uomController;
  late TextEditingController _rateController;
  late TextEditingController _amountController;
  late TextEditingController _equipmentItemController;
  late TextEditingController _contractorController;
  late TextEditingController _workingHrsController;

  final Map<int, TextEditingController> _levelTaskControllers = {};
  final Map<int, TextEditingController> _levelSubjectControllers = {};

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
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
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCDE0D5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: Text(
                'Select $label',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _getTaskKey(int level) {
    if (level == 2) return 'task_level';
    return 'task_level$level';
  }

  String _getSubjectKey(int level) {
    return 'level${level}_subject';
  }

  Future<void> _fetchTaskIsGroup(
    String taskName,
    void Function(String subject, bool isGroup) onFetched,
  ) async {
    if (taskName.isEmpty) return;
    try {
      final sdk = sl<FrappeSDK>();
      final taskData = await sdk.api.doctype.getByName('Task', taskName);
      final subject = taskData['subject']?.toString() ?? '';
      final isGroup =
          (taskData['is_group'] as num?)?.toInt() == 1 ||
          taskData['is_group'] == true ||
          taskData['is_group']?.toString() == 'Yes';
      onFetched(subject, isGroup);
    } catch (_) {}
  }

  Future<void> _fetchTaskSubject(
    String taskName,
    ValueChanged<String> onFetched,
  ) async {
    if (taskName.isEmpty) return;
    try {
      final sdk = sl<FrappeSDK>();
      final taskData = await sdk.api.doctype.getByName('Task', taskName);
      final subject = taskData['subject']?.toString() ?? '';
      onFetched(subject);
    } catch (_) {}
  }

  Future<void> _fetchItemName(String itemCode) async {
    try {
      final sdk = sl<FrappeSDK>();
      final itemData = await sdk.api.doctype.getByName('Item', itemCode);
      final fetchedItemName = itemData['item_name']?.toString() ?? itemCode;
      if (mounted) {
        setState(() {
          _item['item_name'] = fetchedItemName;
          _equipmentItemController.text = fetchedItemName;
        });
      }
    } catch (_) {}
  }

  bool _taskIsGroup = false;
  final Map<int, bool> _levelIsGroup = {};

  bool _shouldShowLevel(int i) {
    if (i == 1) {
      return _taskController.text.isNotEmpty && _taskIsGroup;
    }
    final prevController = _levelTaskControllers[i - 1];
    final prevIsGroup = _levelIsGroup[i - 1] ?? false;
    return prevController != null &&
        prevController.text.isNotEmpty &&
        prevIsGroup;
  }

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.initialItem);

    _taskController = TextEditingController(text: _item['task']?.toString());
    _parentTaskController = TextEditingController(
      text: _item['parent_task']?.toString(),
    );
    _taskSubjectController = TextEditingController(
      text: _item['task_subject']?.toString(),
    );
    _parentTaskSubjectController = TextEditingController(
      text: _item['parent_task_subject']?.toString(),
    );
    _openingReadingController = TextEditingController(
      text: _item['opening_reading']?.toString() ?? '0.0',
    );
    _closingReadingController = TextEditingController(
      text: _item['closing_reading']?.toString() ?? '0.0',
    );
    _dieselFilledInLtrController = TextEditingController(
      text: _item['diesel_filledin_ltr']?.toString() ?? '0.0',
    );
    _qtyController = TextEditingController(
      text: _item['quantity']?.toString() ?? '1.0',
    );
    _uomController = TextEditingController(
      text: _item['uom']?.toString() ?? 'Nos',
    );
    _rateController = TextEditingController(
      text: _item['rate']?.toString() ?? '0.0',
    );
    _amountController = TextEditingController(
      text: _item['amount']?.toString() ?? '0.0',
    );
    final initialEqItem = _item['equipment_item']?.toString() ?? '';
    _equipmentItemController = TextEditingController(
      text: _item['item_name']?.toString() ?? initialEqItem,
    );
    _contractorController = TextEditingController(
      text: _item['contractor']?.toString(),
    );
    _workingHrsController = TextEditingController(
      text: _item['working_hrs']?.toString() ?? '8.0',
    );

    for (int i = 1; i <= 10; i++) {
      final taskKey = _getTaskKey(i);
      final subjectKey = _getSubjectKey(i);
      final taskVal = _item[taskKey]?.toString() ?? '';
      final subjectVal = _item[subjectKey]?.toString() ?? '';
      _levelTaskControllers[i] = TextEditingController(text: taskVal);
      _levelSubjectControllers[i] = TextEditingController(text: subjectVal);

      if (taskVal.isNotEmpty) {
        final levelIndex = i;
        _fetchTaskIsGroup(taskVal, (subject, isGroup) {
          if (mounted) setState(() => _levelIsGroup[levelIndex] = isGroup);
        });
      }
    }

    if (_taskController.text.isNotEmpty) {
      _fetchTaskIsGroup(_taskController.text, (subject, isGroup) {
        if (mounted) setState(() => _taskIsGroup = isGroup);
      });
    }

    if (initialEqItem.isNotEmpty &&
        (_item['item_name'] == null ||
            _item['item_name'].toString().isEmpty)) {
      _fetchItemName(initialEqItem);
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    _parentTaskController.dispose();
    _taskSubjectController.dispose();
    _parentTaskSubjectController.dispose();
    _openingReadingController.dispose();
    _closingReadingController.dispose();
    _dieselFilledInLtrController.dispose();
    _qtyController.dispose();
    _uomController.dispose();
    _rateController.dispose();
    _amountController.dispose();
    _equipmentItemController.dispose();
    _contractorController.dispose();
    _workingHrsController.dispose();
    for (var c in _levelTaskControllers.values) {
      c.dispose();
    }
    for (var c in _levelSubjectControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculateAmount() {
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final hours = double.tryParse(_workingHrsController.text) ?? 8.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final total = qty * hours * rate;
    setState(() {
      _item['quantity'] = qty;
      _item['working_hrs'] = hours;
      _item['rate'] = rate;
      _item['amount'] = total;
      _amountController.text = total.toStringAsFixed(2);
    });
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
                fillColor: readOnly ? const Color(0xFFF5F7F6) : Colors.white,
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
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
                'Edit Equipment Row',
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
                  _buildInnerCard(
                    title: 'Task Selection',
                    children: [
                      _buildTextField(
                        label: 'Stage',
                        controller: _parentTaskSubjectController,
                        placeholder: 'Select stage',
                        onTap: () => widget.showLinkSearch(
                          'Task',
                          (val) {
                            setState(() {
                              _item['parent_task'] = val;
                              _parentTaskController.text = val;
                              // Clear child fields
                              _item['task'] = '';
                              _taskController.text = '';
                              _item['task_subject'] = '';
                              _taskSubjectController.text = '';
                              _taskIsGroup = false;
                              _levelIsGroup.clear();
                              for (int j = 1; j <= 10; j++) {
                                _item[_getTaskKey(j)] = '';
                                _levelTaskControllers[j]?.text = '';
                                _item[_getSubjectKey(j)] = '';
                                _levelSubjectControllers[j]?.text = '';
                              }
                            });
                            _fetchTaskSubject(val, (subject) {
                              setState(() {
                                _item['parent_task_subject'] = subject;
                                _parentTaskSubjectController.text = subject;
                              });
                            });
                          },
                          extraFilters: widget.project != null
                              ? [
                                  ['Task', 'project', '=', widget.project],
                                  ['Task', 'is_group', '=', 1],
                                ]
                              : null,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Task',
                        controller: _taskSubjectController,
                        placeholder: 'Select task',
                        onTap: () {
                          final List<List<dynamic>> extra = [];
                          if (widget.project != null) {
                            extra.add(['Task', 'project', '=', widget.project]);
                          }
                          if (_item['parent_task'] != null &&
                              _item['parent_task'].toString().isNotEmpty) {
                            extra.add([
                              'Task',
                              'parent_task',
                              '=',
                              _item['parent_task']
                            ]);
                          }
                          widget.showLinkSearch(
                            'Task',
                            (val) {
                              setState(() {
                                _item['task'] = val;
                                _taskController.text = val;
                                // Clear levels below
                                _levelIsGroup.clear();
                                for (int j = 1; j <= 10; j++) {
                                  _item[_getTaskKey(j)] = '';
                                  _levelTaskControllers[j]?.text = '';
                                  _item[_getSubjectKey(j)] = '';
                                  _levelSubjectControllers[j]?.text = '';
                                }
                              });
                              _fetchTaskIsGroup(val, (subject, isGroup) {
                                setState(() {
                                  _item['task_subject'] = subject;
                                  _taskSubjectController.text = subject;
                                  _taskIsGroup = isGroup;
                                });
                              });
                            },
                            extraFilters: extra,
                          );
                        },
                      ),
                      for (int i = 1; i <= 10; i++)
                        if (_shouldShowLevel(i)) ...[
                          SizedBox(height: sizeContextOf(context, 12)),
                          _buildTextField(
                            label: 'Level $i Task',
                            controller: _levelSubjectControllers[i]!,
                            placeholder: 'Select subtask',
                            onTap: () {
                              final List<List<dynamic>> extra = [];
                              if (widget.project != null) {
                                extra.add([
                                  'Task',
                                  'project',
                                  '=',
                                  widget.project
                                ]);
                              }
                              final parentVal = i == 1
                                  ? _taskController.text
                                  : _levelTaskControllers[i - 1]!.text;
                              if (parentVal.isNotEmpty) {
                                extra.add(['Task', 'parent_task', '=', parentVal]);
                              }
                              widget.showLinkSearch(
                                'Task',
                                (val) {
                                  setState(() {
                                    _item[_getTaskKey(i)] = val;
                                    _levelTaskControllers[i]!.text = val;
                                    // Clear levels below
                                    for (int j = i + 1; j <= 10; j++) {
                                      _item[_getTaskKey(j)] = '';
                                      _levelTaskControllers[j]?.text = '';
                                      _item[_getSubjectKey(j)] = '';
                                      _levelSubjectControllers[j]?.text = '';
                                      _levelIsGroup.remove(j);
                                    }
                                  });
                                  _fetchTaskIsGroup(val, (subject, isGroup) {
                                    setState(() {
                                      _item[_getSubjectKey(i)] = subject;
                                      _levelSubjectControllers[i]!.text = subject;
                                      _levelIsGroup[i] = isGroup;
                                    });
                                  });
                                },
                                extraFilters: extra,
                              );
                            },
                          ),
                        ],
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),
                  _buildInnerCard(
                    title: 'Equipment Information',
                    children: [
                       GestureDetector(
                        onTap: () {
                          final contractor =
                              _item['contractor']?.toString() ?? '';
                          if (contractor.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('plzz select a contractor first'),
                              ),
                            );
                            return;
                          }
                          widget.showLinkSearch(
                            'Item',
                            (val) async {
                              setState(() {
                                _item['equipment_item'] = val;
                                _equipmentItemController.text = val;
                              });
                              try {
                                final sdk = sl<FrappeSDK>();
                                final itemData = await sdk.api.doctype
                                    .getByName('Item', val);
                                final rateVal =
                                    double.tryParse(
                                      itemData['standard_rate']?.toString() ??
                                          '0.0',
                                    ) ??
                                    0.0;
                                final uomVal =
                                    itemData['stock_uom']?.toString() ?? 'Nos';
                                final fetchedItemName =
                                    itemData['item_name']?.toString() ?? val;
                                setState(() {
                                  _item['rate'] = rateVal;
                                  _rateController.text = rateVal
                                      .toStringAsFixed(2);
                                  _item['uom'] = uomVal;
                                  _uomController.text = uomVal;
                                  _item['item_name'] = fetchedItemName;
                                  _equipmentItemController.text = fetchedItemName;
                                  _calculateAmount();
                                });
                              } catch (_) {}
                            },
                          );
                        },
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Equipment Item *',
                            controller: _equipmentItemController,
                            placeholder: 'Select equipment',
                          ),
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      GestureDetector(
                        onTap: () => widget.showLinkSearch('Contractor', (val) {
                          setState(() {
                            _item['contractor'] = val;
                            _contractorController.text = val;
                            _item['equipment_item'] = '';
                            _item['item_name'] = '';
                            _equipmentItemController.text = '';
                          });
                        }),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Contractor',
                            controller: _contractorController,
                            placeholder: 'Select contractor',
                          ),
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Quantity *',
                              controller: _qtyController,
                              placeholder: '1.0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (val) => _calculateAmount(),
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Working Hrs *',
                              controller: _workingHrsController,
                              placeholder: '8.0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (val) => _calculateAmount(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Rate *',
                              controller: _rateController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (val) => _calculateAmount(),
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Amount',
                              controller: _amountController,
                              placeholder: '0.00',
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Opening Reading',
                              controller: _openingReadingController,
                              placeholder: '0.0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _item['opening_reading'] =
                                      double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Closing Reading',
                              controller: _closingReadingController,
                              placeholder: '0.0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _item['closing_reading'] =
                                      double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Diesel Filled (Ltrs)',
                        controller: _dieselFilledInLtrController,
                        placeholder: '0.0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _item['diesel_filledin_ltr'] =
                                double.tryParse(val) ?? 0.0;
                          });
                        },
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
              String activeTask = '';
              if (_taskController.text.isNotEmpty) activeTask = _taskController.text;
              for (int i = 1; i <= 10; i++) {
                if (_levelTaskControllers[i]!.text.isNotEmpty) {
                  activeTask = _levelTaskControllers[i]!.text;
                }
              }

              if (activeTask.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a Task')),
                );
                return;
              }

              if (_equipmentItemController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an Equipment')),
                );
                return;
              }

               _item['task'] = activeTask;
              _item['parent_task'] = _parentTaskController.text;
              _item['parent_task_subject'] = _parentTaskSubjectController.text;
              _item['task_subject'] = _taskSubjectController.text;
              _item['quantity'] = double.tryParse(_qtyController.text) ?? 1.0;
              _item['working_hrs'] = double.tryParse(_workingHrsController.text) ?? 8.0;
              _item['rate'] = double.tryParse(_rateController.text) ?? 0.0;
              _item['amount'] = double.tryParse(_amountController.text) ?? 0.0;
              _item['equipment_item'] = _item['equipment_item'] ?? '';
              _item['contractor'] = _contractorController.text;

              for (int i = 1; i <= 10; i++) {
                _item[_getTaskKey(i)] = _levelTaskControllers[i]!.text;
                _item[_getSubjectKey(i)] = _levelSubjectControllers[i]!.text;
              }

              widget.onSave(_item);
              Navigator.pop(context);
            },
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
            child: const Text('Save Row Details'),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
