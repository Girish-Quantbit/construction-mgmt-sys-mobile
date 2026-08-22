import 'package:cms/core/theme/app_sizes.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:intl/intl.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;

class DailyProgressReportPage extends StatefulWidget {
  final String? initialProject;
  final DateTime? initialSiteDate;

  const DailyProgressReportPage({
    super.key,
    this.initialProject,
    this.initialSiteDate,
  });

  @override
  State<DailyProgressReportPage> createState() =>
      _DailyProgressReportPageState();
}

class _DailyProgressReportPageState extends State<DailyProgressReportPage> {
  String? _selectedProject;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  List<dynamic>? _columns;
  List<dynamic>? _result;
  double _grandTotal = 0.0;
  final Set<int> _collapsedRowIndices = {};
  final List<dynamic> _activeColumns = [];
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _selectedProject = widget.initialProject;
    if (widget.initialSiteDate != null) {
      _selectedDate = widget.initialSiteDate!;
    }
    if (_selectedProject != null && _selectedProject!.isNotEmpty) {
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    if (_selectedProject == null || _selectedProject!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final sdk = sl<FrappeSDK>();
      final filters = {
        'site_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'project': _selectedProject,
      };

      final response = await sdk.api.call(
        'frappe.desk.query_report.run',
        args: {
          'report_name': 'Daily Progress Report',
          'filters': jsonEncode(filters),
          'ignore_prepared_report': false,
          'are_default_filters': false,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        final data = response.containsKey('message')
            ? response['message']
            : response;

        if (data != null && data is Map<String, dynamic>) {
          setState(() {
            _columns = data['columns'];
            _result = data['result'];
            _processReportData();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'No data returned from report';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Invalid response format';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _processReportData() {
    _grandTotal = 0.0;
    _collapsedRowIndices.clear();
    _activeColumns.clear();

    if (_result == null || _columns == null) return;

    // Find grand total
    for (var entryRaw in _result!) {
      if (entryRaw is! Map) continue;
      final entry = Map<String, dynamic>.from(entryRaw);
      final sectionName = entry['section'];
      if (sectionName == 'GRAND TOTAL') {
        _grandTotal = double.tryParse(entry['amount']?.toString() ?? '') ?? 0.0;
        break;
      }
    }

    // Identify active columns (columns that have at least one non-null, non-empty value)
    final activeFields = <String>{};
    for (var entryRaw in _result!) {
      if (entryRaw is! Map) continue;
      final entry = Map<String, dynamic>.from(entryRaw);

      if (entry['section'] == 'GRAND TOTAL') continue;

      for (var colRaw in _columns!) {
        if (colRaw is! Map) continue;
        final col = Map<String, dynamic>.from(colRaw);
        final fieldname = col['fieldname'];
        if (fieldname == null || fieldname == 'section') continue;
        final val = entry[fieldname];
        if (val != null && val.toString().trim().isNotEmpty) {
          activeFields.add(fieldname);
        }
      }
    }

    // Filter columns: keep 'section' first, then only the active fields
    for (var colRaw in _columns!) {
      if (colRaw is! Map) continue;
      final col = Map<String, dynamic>.from(colRaw);
      final fieldname = col['fieldname'];
      if (fieldname == 'section' || activeFields.contains(fieldname)) {
        _activeColumns.add(col);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchReport();
    }
  }

  bool _isRowVisible(int index) {
    if (_result == null || index >= _result!.length) return false;

    final row = _result![index];
    if (row is! Map) return false;
    if (row['section'] == 'GRAND TOTAL') return true;

    final currentIndent = row['indent'] ?? 0;

    int tempIndent = currentIndent;
    for (int i = index - 1; i >= 0; i--) {
      final prevRow = _result![i];
      if (prevRow is! Map) continue;
      if (prevRow['section'] == 'GRAND TOTAL') break;

      final prevIndent = prevRow['indent'] ?? 0;

      if (prevIndent < tempIndent) {
        if (_collapsedRowIndices.contains(i)) {
          return false;
        }
        tempIndent = prevIndent;
        if (tempIndent == 0) {
          break;
        }
      }
    }
    return true;
  }

  double _getColumnWidth(Map<String, dynamic> col) {
    final fieldname = col['fieldname'];
    if (fieldname == 'section') {
      return 280.0;
    }
    final widthVal = col['width'];
    if (widthVal != null) {
      return double.tryParse(widthVal.toString()) ?? 100.0;
    }

    final type = col['fieldtype'];
    if (type == 'Float' ||
        type == 'Currency' ||
        type == 'Percent' ||
        type == 'Int') {
      return 100.0;
    }
    return 130.0;
  }

  Alignment _getColumnAlignment(Map<String, dynamic> col) {
    final type = col['fieldtype'];
    if (type == 'Float' ||
        type == 'Currency' ||
        type == 'Percent' ||
        type == 'Int') {
      return Alignment.centerRight;
    }
    return Alignment.centerLeft;
  }

  CellValue? _toCellValue(dynamic val, String type) {
    if (val == null) return null;
    if (type == 'Currency' ||
        type == 'Percent' ||
        type == 'Float' ||
        type == 'Int') {
      final doubleVal = double.tryParse(val.toString());
      if (doubleVal != null) {
        if (type == 'Percent') {
          return DoubleCellValue(doubleVal / 100.0);
        }
        return DoubleCellValue(doubleVal);
      }
    }
    return TextCellValue(val.toString());
  }

  Future<void> _exportToExcel() async {
    if (_result == null || _result!.isEmpty || _columns == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final excel = Excel.createExcel();
      const sheetName = 'Daily Progress Report';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      final CellStyle headerStyle = CellStyle(bold: true);

      final List<CellValue?> headerLabels = [];
      headerLabels.add(TextCellValue('Sr. No'));
      for (var colRaw in _activeColumns) {
        final col = Map<String, dynamic>.from(colRaw);
        headerLabels.add(TextCellValue(col['label'] ?? ''));
      }
      sheet.appendRow(headerLabels);

      for (int i = 0; i < headerLabels.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = headerStyle;
      }

      int excelRowIdx = 1;
      int srNo = 1;
      Map<String, dynamic>? grandTotalEntry;

      for (var entryRaw in _result!) {
        if (entryRaw is! Map) continue;
        final entry = Map<String, dynamic>.from(entryRaw);

        if (entry['section'] == 'GRAND TOTAL') {
          grandTotalEntry = entry;
          continue;
        }

        final List<CellValue?> rowData = [];
        rowData.add(IntCellValue(srNo));

        final isGroup = entry['is_group'] == 1;
        final indent = entry['indent'] ?? 0;
        final sectionName = entry['section'] ?? '';

        for (var colRaw in _activeColumns) {
          final col = Map<String, dynamic>.from(colRaw);
          final fieldname = col['fieldname'];
          final type = col['fieldtype'];
          final val = entry[fieldname];

          if (fieldname == 'section') {
            final indentPrefix = '    ' * indent;
            final chevron = isGroup ? 'v ' : '';
            rowData.add(TextCellValue('$indentPrefix$chevron$sectionName'));
          } else {
            if (val == null) {
              rowData.add(null);
            } else {
              rowData.add(_toCellValue(val, type ?? ''));
            }
          }
        }

        sheet.appendRow(rowData);

        for (int colIdx = 0; colIdx < headerLabels.length; colIdx++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIdx,
              rowIndex: excelRowIdx,
            ),
          );

          bool rightAlign = false;
          NumFormat? numFormat;
          if (colIdx > 0 && colIdx - 1 < _activeColumns.length) {
            final col = Map<String, dynamic>.from(_activeColumns[colIdx - 1]);
            final type = col['fieldtype'];
            rightAlign =
                type == 'Currency' ||
                type == 'Percent' ||
                type == 'Float' ||
                type == 'Int';
            if (type == 'Currency') {
              numFormat = NumFormat.custom(formatCode: '₹ #,##0.00');
            } else if (type == 'Percent') {
              numFormat = NumFormat.custom(formatCode: '0.00%');
            }
          }

          cell.cellStyle = CellStyle(
            bold: isGroup,
            horizontalAlign: rightAlign
                ? HorizontalAlign.Right
                : HorizontalAlign.Left,
            numberFormat: numFormat ?? NumFormat.standard_0,
          );
        }

        excelRowIdx++;
        srNo++;
      }

      if (grandTotalEntry != null) {
        final List<CellValue?> rowData = [null];
        for (var colRaw in _activeColumns) {
          final col = Map<String, dynamic>.from(colRaw);
          final fieldname = col['fieldname'];
          final type = col['fieldtype'];
          final val = grandTotalEntry[fieldname];

          if (fieldname == 'section') {
            rowData.add(TextCellValue('GRAND TOTAL'));
          } else {
            if (val == null) {
              rowData.add(null);
            } else {
              rowData.add(_toCellValue(val, type ?? ''));
            }
          }
        }
        sheet.appendRow(rowData);

        for (int colIdx = 0; colIdx < headerLabels.length; colIdx++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIdx,
              rowIndex: excelRowIdx,
            ),
          );

          bool rightAlign = false;
          NumFormat? numFormat;
          if (colIdx > 0 && colIdx - 1 < _activeColumns.length) {
            final col = Map<String, dynamic>.from(_activeColumns[colIdx - 1]);
            final type = col['fieldtype'];
            rightAlign =
                type == 'Currency' ||
                type == 'Percent' ||
                type == 'Float' ||
                type == 'Int';
            if (type == 'Currency') {
              numFormat = NumFormat.custom(formatCode: '₹ #,##0.00');
            } else if (type == 'Percent') {
              numFormat = NumFormat.custom(formatCode: '0.00%');
            }
          }

          cell.cellStyle = CellStyle(
            bold: true,
            horizontalAlign: rightAlign
                ? HorizontalAlign.Right
                : HorizontalAlign.Left,
            numberFormat: numFormat ?? NumFormat.standard_0,
          );
        }
        excelRowIdx++;
      }

      sheet.setColumnWidth(0, 8.0);
      sheet.setColumnWidth(1, 40.0);
      for (int i = 2; i < headerLabels.length; i++) {
        sheet.setColumnWidth(i, 15.0);
      }

      final bytes = excel.save();
      if (bytes != null) {
        final directory = await getTemporaryDirectory();
        final projectNameSafe = (_selectedProject ?? 'Report').replaceAll(
          RegExp(r'[^\w\s\-]'),
          '_',
        );
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final filePath =
            '${directory.path}/Daily_Progress_Report_${projectNameSafe}_$dateStr.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([
          XFile(filePath),
        ], subject: 'Daily Progress Report - $_selectedProject ($dateStr)');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export Excel: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: sizeContextOf(context, 20),
        left: sizeContextOf(context, 16),
        right: sizeContextOf(context, 16),
      ),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Daily Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_result != null && _result!.isNotEmpty) ...[
                IconButton(
                  icon: Icon(
                    _isTableView ? Icons.view_agenda : Icons.table_chart,
                    color: Colors.white,
                  ),
                  tooltip: _isTableView
                      ? 'Switch to Card View'
                      : 'Switch to Table View',
                  onPressed: () {
                    setState(() {
                      _isTableView = !_isTableView;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  tooltip: 'Export to Excel',
                  onPressed: _exportToExcel,
                ),
              ],
            ],
          ),
          SizedBox(height: sizeContextOf(context, 12)),
          Container(
            padding: EdgeInsets.all(sizeContextOf(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROJECT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        _selectedProject ?? 'Select Project',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white24,
                  margin: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 12)),
                ),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    if (_result == null || _result!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: sizeContextOf(context, 16)),
            const Text(
              'No records found for the selected criteria.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: sizeContextOf(context, 24)),
            ElevatedButton(
              onPressed: _fetchReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      symbol: '₹ ',
      decimalDigits: 2,
    );

    final totalWidth = _activeColumns
        .map((c) => _getColumnWidth(Map<String, dynamic>.from(c)))
        .fold(0.0, (sum, w) => sum + w);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: sizeContextOf(context, 16), right: sizeContextOf(context, 16), top: sizeContextOf(context, 16)),
          child: _buildGrandTotalCard(currencyFormat),
        ),
        SizedBox(height: sizeContextOf(context, 16)),
        Expanded(
          child: _isTableView
              ? _buildTableContent(totalWidth, currencyFormat)
              : _buildCardContent(currencyFormat),
        ),
      ],
    );
  }

  Widget _buildTableContent(double totalWidth, NumberFormat currencyFormat) {
    return Container(
      margin: EdgeInsets.only(left: sizeContextOf(context, 16), right: sizeContextOf(context, 16), bottom: sizeContextOf(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(),
                const Divider(height: 1, color: Color(0xFFCBD5E1)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(children: _buildTableRows(currencyFormat)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(NumberFormat currencyFormat) {
    if (_result == null) return const SizedBox();

    return ListView.builder(
      padding: EdgeInsets.only(left: sizeContextOf(context, 16), right: sizeContextOf(context, 16), bottom: sizeContextOf(context, 16)),
      itemCount: _result!.length,
      itemBuilder: (context, index) {
        final entryRaw = _result![index];
        if (entryRaw is! Map) return const SizedBox();
        final entry = Map<String, dynamic>.from(entryRaw);

        if (entry['section'] == 'GRAND TOTAL') return const SizedBox();
        if (!_isRowVisible(index)) return const SizedBox();

        final isGroup = entry['is_group'] == 1;
        final indent = entry['indent'] ?? 0;
        final isCollapsed = _collapsedRowIndices.contains(index);
        final sectionName = entry['section']?.toString() ?? '';

        if (isGroup) {
          return InkWell(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedRowIndices.remove(index);
                } else {
                  _collapsedRowIndices.add(index);
                }
              });
            },
            child: Container(
              margin: EdgeInsets.only(top: sizeContextOf(context, 8), bottom: sizeContextOf(context, 8), left: indent * 16.0),
              padding: EdgeInsets.all(sizeContextOf(context, 12)),
              decoration: BoxDecoration(
                color: indent == 0
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: const Color(0xFF475569),
                  ),
                  SizedBox(width: sizeContextOf(context, 8)),
                  Expanded(
                    child: Text(
                      sectionName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final List<Widget> dataFields = [];
        for (var colRaw in _activeColumns) {
          final col = Map<String, dynamic>.from(colRaw);
          final fieldname = col['fieldname'];
          if (fieldname == 'section') continue;

          final label = col['label'] ?? '';
          final val = entry[fieldname];
          if (val == null || val.toString().isEmpty) continue;

          String textVal = '';
          final type = col['fieldtype'];
          if (type == 'Currency') {
            final doubleVal = double.tryParse(val.toString()) ?? 0.0;
            textVal = currencyFormat.format(doubleVal);
          } else if (type == 'Percent') {
            final doubleVal = double.tryParse(val.toString()) ?? 0.0;
            textVal = '${doubleVal.toStringAsFixed(1)}%';
          } else if (type == 'Float') {
            final doubleVal = double.tryParse(val.toString()) ?? 0.0;
            textVal = NumberFormat('#,##0.##').format(doubleVal);
          } else {
            textVal = val.toString();
          }

          dataFields.add(
            Padding(
              padding: EdgeInsets.only(bottom: sizeContextOf(context, 8.0)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      textVal,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          margin: EdgeInsets.only(top: sizeContextOf(context, 4), bottom: sizeContextOf(context, 4), left: indent * 16.0),
          padding: EdgeInsets.all(sizeContextOf(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              if (dataFields.isNotEmpty) ...[
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                ...dataFields,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrandTotalCard(NumberFormat formatter) {
    return Container(
      padding: EdgeInsets.all(sizeContextOf(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(
          left: BorderSide(color: Color(0xFF22C55E), width: 4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'GRAND TOTAL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            formatter.format(_grandTotal),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 12)),
      child: Row(
        children: _activeColumns.map<Widget>((colRaw) {
          final col = Map<String, dynamic>.from(colRaw);
          final label = col['label'] ?? '';
          final width = _getColumnWidth(col);
          final align = _getColumnAlignment(col);

          return Container(
            width: width,
            padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 12)),
            alignment: align,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTableRows(NumberFormat currencyFormat) {
    final List<Widget> rowWidgets = [];
    if (_result == null) return rowWidgets;

    for (int i = 0; i < _result!.length; i++) {
      final entryRaw = _result![i];
      if (entryRaw is! Map) continue;
      final entry = Map<String, dynamic>.from(entryRaw);

      if (entry['section'] == 'GRAND TOTAL') continue;
      if (!_isRowVisible(i)) continue;

      rowWidgets.add(_buildRow(i, entry, currencyFormat));
    }
    return rowWidgets;
  }

  Widget _buildRow(
    int index,
    Map<String, dynamic> entry,
    NumberFormat currencyFormat,
  ) {
    final isGroup = entry['is_group'] == 1;
    final indent = entry['indent'] ?? 0;
    final isCollapsed = _collapsedRowIndices.contains(index);

    Color rowBgColor = Colors.white;
    if (isGroup) {
      if (indent == 0) {
        rowBgColor = const Color(0xFFF1F5F9);
      } else {
        rowBgColor = const Color(0xFFF8FAFC);
      }
    }

    return InkWell(
      onTap: isGroup
          ? () {
              setState(() {
                if (isCollapsed) {
                  _collapsedRowIndices.remove(index);
                } else {
                  _collapsedRowIndices.add(index);
                }
              });
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 10)),
        decoration: BoxDecoration(
          color: rowBgColor,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: _activeColumns.map<Widget>((colRaw) {
            final col = Map<String, dynamic>.from(colRaw);
            final fieldname = col['fieldname'];
            final width = _getColumnWidth(col);
            final align = _getColumnAlignment(col);
            final val = entry[fieldname];

            Widget cellContent;

            if (fieldname == 'section') {
              cellContent = Padding(
                padding: EdgeInsets.only(left: (indent * 16.0)),
                child: Row(
                  children: [
                    if (isGroup)
                      Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_right
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: const Color(0xFF64748B),
                      )
                    else
                      const SizedBox(
                        width: 18,
                        child: Center(
                          child: Icon(
                            Icons.fiber_manual_record,
                            size: 6,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    SizedBox(width: sizeContextOf(context, 4)),
                    Expanded(
                      child: Text(
                        val?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isGroup
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isGroup
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF334155),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              String textVal = '';
              if (val != null) {
                final type = col['fieldtype'];
                if (type == 'Currency') {
                  final doubleVal = double.tryParse(val.toString()) ?? 0.0;
                  textVal = currencyFormat.format(doubleVal);
                } else if (type == 'Percent') {
                  final doubleVal = double.tryParse(val.toString()) ?? 0.0;
                  textVal = '${doubleVal.toStringAsFixed(1)}%';
                } else if (type == 'Float') {
                  final doubleVal = double.tryParse(val.toString()) ?? 0.0;
                  textVal = NumberFormat('#,##0.##').format(doubleVal);
                } else {
                  textVal = val.toString();
                }
              }

              cellContent = Text(
                textVal,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isGroup ? FontWeight.bold : FontWeight.normal,
                  color: isGroup
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF475569),
                ),
              );
            }

            return Container(
              width: width,
              padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 12)),
              alignment: align,
              child: cellContent,
            );
          }).toList(),
        ),
      ),
    );
  }
}
