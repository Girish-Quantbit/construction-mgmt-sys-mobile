import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/services/project_selection_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class SiteDiaryFormPage extends StatefulWidget {
  final String? diaryName;
  final String? project;
  const SiteDiaryFormPage({super.key, this.diaryName, this.project});

  @override
  State<SiteDiaryFormPage> createState() => _SiteDiaryFormPageState();
}

class _SiteDiaryFormPageState extends State<SiteDiaryFormPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  DocTypeMeta? _meta;
  Document? _document;

  // State fields
  DateTime? _siteDate;
  final _siteDateController = TextEditingController();
  final _dayNoController = TextEditingController();
  String? _shift;
  String? _siteEngineer;
  final _siteEngineerNameController = TextEditingController();
  final _siteEngineerDisplayController = TextEditingController();
  String? _weatherAm;
  String? _weatherPm;
  final _maxTempController = TextEditingController();
  final _minTempController = TextEditingController();
  final _windSpeedController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _workStopped = false;
  String? _status;
  int _selectedLogTab = 0;
  late final PageController _pageController;
  final Set<String> _expandedItems = {};
  final Map<String, int> _selectedImageTabs = {};
  File? _pickedSitePhoto;
  String? _existingSitePhotoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedLogTab);
    _fetchMeta();
  }

  @override
  void dispose() {
    _siteDateController.dispose();
    _dayNoController.dispose();
    _siteEngineerNameController.dispose();
    _siteEngineerDisplayController.dispose();
    _maxTempController.dispose();
    _minTempController.dispose();
    _windSpeedController.dispose();
    _remarksController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _selectedLogTab) return;
    setState(() {
      _selectedLogTab = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  String _getTabLabel(int index) {
    switch (index) {
      case 0:
        return 'Tasks';
      case 1:
        return 'Progress';
      case 2:
        return 'Mat. Recd';
      case 3:
        return 'Mat. Deliv';
      case 4:
        return 'Manpower';
      case 5:
        return 'Equipment';
      case 6:
        return 'Visitors';
      default:
        return '';
    }
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.task_alt_outlined;
      case 1:
        return Icons.trending_up_outlined;
      case 2:
        return Icons.input_outlined;
      case 3:
        return Icons.local_shipping_outlined;
      case 4:
        return Icons.people_outline;
      case 5:
        return Icons.construction_outlined;
      case 6:
        return Icons.person_pin_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getTabCountText(int index) {
    if (_document == null) return '0';
    final data = _document!.data;
    switch (index) {
      case 0:
        return '${(data['task'] as List?)?.length ?? 0}';
      case 1:
        return '${(data['activity_progress'] as List?)?.length ?? 0}';
      case 2:
        return '${(data['material_received'] as List?)?.length ?? 0}';
      case 3:
        return '${(data['material_deliveries'] as List?)?.length ?? 0}';
      case 4:
        return '${(data['manpower_log'] as List?)?.length ?? 0}';
      case 5:
        return '${(data['equipment_log'] as List?)?.length ?? 0}';
      case 6:
        return '${(data['visitors'] as List?)?.length ?? 0}';
      default:
        return '0';
    }
  }

  double _calculatePageViewHeight() {
    final int count = int.tryParse(_getTabCountText(_selectedLogTab)) ?? 0;
    if (count == 0) return 180.0;
    final double estimatedHeight = count * 115.0 + 20.0;
    if (estimatedHeight < 220.0) return 220.0;
    if (estimatedHeight > 550.0) return 550.0;
    return estimatedHeight;
  }

  Widget _buildCarouselNavigator() {
    final countText = _getTabCountText(_selectedLogTab);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _selectedLogTab > 0
                ? IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF5A8B6C),
                    ),
                    onPressed: () => _onTabChanged(_selectedLogTab - 1),
                  )
                : const SizedBox(width: 48),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTabIcon(_selectedLogTab),
                  color: const Color(0xFF5A8B6C),
                ),
                const SizedBox(width: 10),
                Text(
                  _getTabLabel(_selectedLogTab),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F2E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    countText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A8B6C),
                    ),
                  ),
                ),
              ],
            ),
            _selectedLogTab < 6
                ? IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF5A8B6C),
                    ),
                    onPressed: () => _onTabChanged(_selectedLogTab + 1),
                  )
                : const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchMeta() async {
    try {
      final sdk = sl<FrappeSDK>();
      final meta = await sdk.meta.getMeta('Site Diary', forceRefresh: true);

      final allowedFields = [
        'site_date',
        'day_no_of_contract',
        'shift',
        'site_engineer',
        'site_engineer_name',
        'weather_am',
        'weather_pm',
        'max_temp',
        'min_temp',
        'wind_speed_kmh',
        'general_remarks',
        'site_photos',
        'status',
        'work_stopped',
        'get_site_diary_details',
        'task',
        'activity_progress',
        'material_received',
        'material_deliveries',
        'manpower_log',
        'equipment_log',
        'visitors',
      ];

      meta.fields.retainWhere((f) => allowedFields.contains(f.fieldname));
      meta.fields.sort((a, b) {
        final indexA = allowedFields.indexOf(a.fieldname ?? '');
        final indexB = allowedFields.indexOf(b.fieldname ?? '');
        return indexA.compareTo(indexB);
      });

      Document? doc;
      if (widget.diaryName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName(
            'Site Diary',
            widget.diaryName!,
          );
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Site Diary',
            serverId: widget.diaryName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(
            widget.diaryName!,
            'Site Diary',
          );
        }
      } else {
        final activeProject =
            widget.project ?? sl<ProjectSelectionService>().selectedProject;
        doc = await sdk.repository.createDocument(
          doctype: 'Site Diary',
          data: {'project': activeProject},
        );
      }

      // Initialize form variables
      final data = doc!.data;
      if (data['site_date'] != null) {
        _siteDate = DateTime.tryParse(data['site_date'].toString());
      } else {
        _siteDate = DateTime.now();
      }
      if (_siteDate != null) {
        _siteDateController.text = DateFormat('yyyy-MM-dd').format(_siteDate!);
      }
      _dayNoController.text = data['day_no_of_contract']?.toString() ?? '';
      _shift = data['shift']?.toString() ?? 'Day';
      _siteEngineer = data['site_engineer']?.toString();
      _siteEngineerNameController.text =
          data['site_engineer_name']?.toString() ?? '';
      _siteEngineerDisplayController.text =
          _siteEngineerNameController.text.isNotEmpty
          ? _siteEngineerNameController.text
          : (_siteEngineer ?? '');
      _weatherAm = data['weather_am']?.toString() ?? 'Clear';
      _weatherPm = data['weather_pm']?.toString() ?? 'Clear';
      _maxTempController.text = data['max_temp']?.toString() ?? '';
      _minTempController.text = data['min_temp']?.toString() ?? '';
      _windSpeedController.text = data['wind_speed_kmh']?.toString() ?? '';
      _remarksController.text = data['general_remarks']?.toString() ?? '';
      _workStopped = data['work_stopped'] == 1 || data['work_stopped'] == true;
      _status = data['status']?.toString() ?? 'Draft';
      _existingSitePhotoUrl = data['site_photos']?.toString();

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

  List<String> getSelectOptions(String fieldname) {
    final field = _meta?.fields.firstWhere((f) => f.fieldname == fieldname);
    if (field != null && field.options != null) {
      return field.options!
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<void> _onGetDetails() async {
    final project =
        widget.project ?? sl<ProjectSelectionService>().selectedProject;
    final dateStr = _siteDate != null
        ? DateFormat('yyyy-MM-dd').format(_siteDate!)
        : null;

    if (project == null || dateStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Project and Site Date first'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final sdk = sl<FrappeSDK>();

      final responses = await Future.wait([
        sdk.api.call(
          'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_site_diary_details',
          args: {'project': project, 'site_date': dateStr},
        ),
        sdk.api
            .call(
              'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_latest_task_progress',
              args: {'project': project, 'site_date': dateStr},
            )
            .catchError((_) => null),
        sdk.api
            .call(
              'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_material_deliveries',
              args: {'project': project, 'site_date': dateStr},
            )
            .catchError((_) => null),
        sdk.api
            .call(
              'quantbit_construction_management.site_diary.doctype.site_diary.site_diary.get_material_received',
              args: {'project': project, 'site_date': dateStr},
            )
            .catchError((_) => null),
      ]);

      final mainResponse = responses[0];
      final taskProgressResponse = responses[1];
      final materialDeliveriesResponse = responses[2];
      final materialReceivedResponse = responses[3];

      if (mainResponse != null && mainResponse is Map<String, dynamic>) {
        final updatedData = Map<String, dynamic>.from(_document?.data ?? {});
        updatedData['site_date'] = dateStr;
        updatedData['project'] = project;

        final childTables = [
          'task',
          'activity_progress',
          'material_received',
          'material_deliveries',
          'manpower_log',
          'equipment_log',
          'visitors',
        ];

        final data = mainResponse.containsKey('message')
            ? mainResponse['message']
            : mainResponse;

        for (final table in childTables) {
          if (data is Map && data.containsKey(table)) {
            updatedData[table] = data[table];
          }
        }

        dynamic extractData(dynamic response) {
          if (response is Map<String, dynamic>) {
            return response.containsKey('message')
                ? response['message']
                : response;
          }
          return response;
        }

        final rawProgressData = extractData(taskProgressResponse);
        final List<Map<String, dynamic>> taskProgressData = [];
        if (rawProgressData is List) {
          for (final item in rawProgressData) {
            if (item is Map) {
              final mapItem = Map<String, dynamic>.from(item);
              final docNameVal = mapItem['doc_name']?.toString() ?? mapItem['docname']?.toString();
              if (docNameVal != null && (docNameVal.startsWith('TP') || docNameVal.contains('TP-') || docNameVal.contains('TP -'))) {
                mapItem['id'] = docNameVal.trim();
                mapItem['doc_name'] = 'Task Progress';
              }
              taskProgressData.add(mapItem);
            }
          }
        }

        if (taskProgressData.isNotEmpty) {
          updatedData['activity_progress'] = taskProgressData;
        }

        // Collect unique task IDs and subjects
        final Map<String, String> taskSubjects = {};

        // 1. Check existing tasks in updatedData['task'] to preserve existing subjects
        final existingTasks = updatedData['task'];
        if (existingTasks is List) {
          for (final item in existingTasks) {
            if (item is Map) {
              final taskId = item['task']?.toString();
              final subject = item['task_subject']?.toString();
              if (taskId != null && taskId.isNotEmpty) {
                taskSubjects[taskId] = subject ?? '';
              }
            }
          }
        }

        // 2. Extract task IDs from taskProgressData
        for (final item in taskProgressData) {
          final taskId =
              item['task']?.toString() ?? item['task_id']?.toString();
          if (taskId != null && taskId.isNotEmpty) {
            if (!taskSubjects.containsKey(taskId)) {
              taskSubjects[taskId] = '';
            }
          }
        }

        // 3. Fetch subject for any task ID that doesn't have one
        final List<Map<String, dynamic>> finalTaskList = [];
        for (final entry in taskSubjects.entries) {
          final taskId = entry.key;
          var subject = entry.value;

          if (subject.isEmpty) {
            try {
              final response = await sdk.api.call(
                'frappe.client.get_value',
                args: {
                  'doctype': 'Task',
                  'fieldname': 'subject',
                  'filters': taskId,
                },
              );
              if (response != null && response is Map<String, dynamic>) {
                final message = response['message'];
                if (message is Map) {
                  subject = message['subject']?.toString() ?? '';
                } else if (message is String) {
                  subject = message;
                }
              }
            } catch (e) {
              debugPrint('Error fetching subject for task $taskId: $e');
            }
          }
          finalTaskList.add({'task': taskId, 'task_subject': subject});
        }

        updatedData['task'] = finalTaskList;

        final materialDeliveriesData = extractData(materialDeliveriesResponse);
        if (materialDeliveriesData != null) {
          updatedData['material_deliveries'] = materialDeliveriesData;
        }

        final materialReceivedData = extractData(materialReceivedResponse);
        if (materialReceivedData != null) {
          updatedData['material_received'] = materialReceivedData;
        }

        setState(() {
          _document = _document?.copyWith(data: updatedData);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details fetched successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching details: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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

  Future<void> _saveDocument() async {
    if (_siteDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select Site Date')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final sdk = sl<FrappeSDK>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_siteDate!);

    String? photoUrl = _existingSitePhotoUrl;
    if (_pickedSitePhoto != null && widget.diaryName != null) {
      photoUrl = await _uploadSitePhoto(widget.diaryName!);
    }

    final payload = {
      'project':
          widget.project ?? sl<ProjectSelectionService>().selectedProject,
      'site_date': dateStr,
      'day_no_of_contract': int.tryParse(_dayNoController.text),
      'shift': _shift,
      'site_engineer': _siteEngineer,
      'site_engineer_name': _siteEngineerNameController.text,
      'weather_am': _weatherAm,
      'weather_pm': _weatherPm,
      'max_temp': double.tryParse(_maxTempController.text),
      'min_temp': double.tryParse(_minTempController.text),
      'wind_speed_kmh': double.tryParse(_windSpeedController.text),
      'general_remarks': _remarksController.text,
      'work_stopped': _workStopped ? 1 : 0,
      'status': _status ?? 'Draft',
      'site_photos': photoUrl,
      // Include child tables
      'task': _document?.data['task'] ?? [],
      'activity_progress': _document?.data['activity_progress'] ?? [],
      'material_received': _document?.data['material_received'] ?? [],
      'material_deliveries': _document?.data['material_deliveries'] ?? [],
      'manpower_log': _document?.data['manpower_log'] ?? [],
      'equipment_log': _document?.data['equipment_log'] ?? [],
      'visitors': _document?.data['visitors'] ?? [],
    };

    try {
      if (widget.diaryName == null) {
        // Create new doc
        final result = await sdk.api.document.createDocument(
          'Site Diary',
          payload,
        );
        final serverName =
            result['name']?.toString() ?? result['docname']?.toString();
        if (serverName != null) {
          if (_pickedSitePhoto != null) {
            photoUrl = await _uploadSitePhoto(serverName);
          }
          final merged = Map<String, dynamic>.from(payload)
            ..['name'] = serverName;
          if (photoUrl != null) {
            merged['site_photos'] = photoUrl;
          }
          await sdk.repository.saveServerDocument(
            doctype: 'Site Diary',
            serverId: serverName,
            data: merged,
          );
        }
      } else {
        // Update existing doc
        final existingData = Map<String, dynamic>.from(_document!.data)
          ..addAll(payload);
        await sdk.api.document.updateDocument(
          'Site Diary',
          widget.diaryName!,
          existingData,
        );
        await sdk.repository.updateDocumentData(
          _document!.localId,
          existingData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site Diary saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
      builder: (context) => _LinkSearchBottomSheet(
        doctype: doctype,
        onSelected: (val) {
          onSelected(val);
          Navigator.pop(context);
        },
      ),
    );
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
        appBar: AppBar(title: const Text('Site Diary')),
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
          widget.diaryName != null ? 'Edit Site Diary' : 'New Site Diary',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                            label: 'Site Date',
                            controller: _siteDateController,
                            placeholder: 'YYYY-MM-DD',
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                            ),
                            onTap: _selectDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            label: 'Day No. of Contract',
                            controller: _dayNoController,
                            placeholder: 'e.g. 10',
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
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
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            label: 'Site Engineer',
                            controller: _siteEngineerDisplayController,
                            placeholder: 'Select site engineer',
                            onTap: () => _showLinkSearch('Employee', (
                              val,
                            ) async {
                              setState(() {
                                _siteEngineer = val;
                                _siteEngineerDisplayController.text = val;
                              });
                              try {
                                final sdk = sl<FrappeSDK>();
                                final empData = await sdk.api.doctype.getByName(
                                  'Employee',
                                  val,
                                );
                                final name =
                                    empData['employee_name']?.toString() ?? '';
                                setState(() {
                                  _siteEngineerNameController.text = name;
                                  _siteEngineerDisplayController.text = name;
                                });
                              } catch (_) {
                                setState(() {
                                  _siteEngineerNameController.text = val;
                                  _siteEngineerDisplayController.text = val;
                                });
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _onGetDetails,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync, size: 18),
                        label: const Text(
                          'Get Site Diary Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Weather Details Card
                _buildCard(
                  title: 'Weather Details',
                  icon: Icons.cloud_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Weather AM',
                            value: _weatherAm,
                            items: getSelectOptions('weather_am'),
                            onChanged: (val) {
                              setState(() {
                                _weatherAm = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Weather PM',
                            value: _weatherPm,
                            items: getSelectOptions('weather_pm'),
                            onChanged: (val) {
                              setState(() {
                                _weatherPm = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Max Temp (°C)',
                            controller: _maxTempController,
                            placeholder: 'e.g. 35',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Min Temp (°C)',
                            controller: _minTempController,
                            placeholder: 'e.g. 20',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Wind Speed (km/h)',
                      controller: _windSpeedController,
                      placeholder: 'e.g. 15',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Unified Carousel Log Navigator & Headers
                _buildCarouselNavigator(),
                const SizedBox(height: 16),

                // Active Log Pages inside PageView for smooth swiping animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: _calculatePageViewHeight(),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedLogTab = index;
                        _expandedItems.clear();
                        _selectedImageTabs.clear();
                      });
                    },
                    children: [
                      _buildTasksPageContent(),
                      _buildActivityProgressPageContent(),
                      _buildMaterialReceivedPageContent(),
                      _buildMaterialDeliveriesPageContent(),
                      _buildManpowerPageContent(),
                      _buildEquipmentPageContent(),
                      _buildVisitorsPageContent(),
                    ],
                  ),
                ),
                // Remarks & Settings Card
                _buildCard(
                  title: 'Remarks',
                  icon: Icons.settings_suggest_outlined,
                  children: [
                    _buildTextField(
                      label: 'General Remarks',
                      controller: _remarksController,
                      placeholder: 'Enter remarks...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                'Work Stopped',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _workStopped,
                                activeThumbColor: AppColors.primaryButton,
                                onChanged: (val) {
                                  setState(() {
                                    _workStopped = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildSitePhotosSelector(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bottom Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCDE0D5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveDocument,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Save Site Diary'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<String?> _uploadSitePhoto(String serverName) async {
    final sdk = sl<FrappeSDK>();
    final String baseUrl = sdk.baseUrl.endsWith('/')
        ? sdk.baseUrl.substring(0, sdk.baseUrl.length - 1)
        : sdk.baseUrl;
    final String uploadUrl = '$baseUrl/api/method/upload_file';
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers.addAll(sdk.api.requestHeaders);
      request.fields['doctype'] = 'Site Diary';
      request.fields['docname'] = serverName;
      request.fields['docfield'] = 'site_photos';
      request.fields['is_private'] = '0';
      final fileName = _pickedSitePhoto!.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _pickedSitePhoto!.path,
          filename: fileName,
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['message']?['file_url']?.toString();
      } else {
        debugPrint('Failed to upload site photo: ${response.body}');
      }
    } catch (uploadError) {
      debugPrint('Error uploading site photo: $uploadError');
    }
    return null;
  }

  Future<void> _pickSitePhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  setState(() {
                    _pickedSitePhoto = File(file.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(source: ImageSource.camera);
                if (file != null) {
                  setState(() {
                    _pickedSitePhoto = File(file.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSitePhotosSelector() {
    final sdk = sl<FrappeSDK>();
    final baseUrl = sdk.baseUrl.endsWith('/')
        ? sdk.baseUrl.substring(0, sdk.baseUrl.length - 1)
        : sdk.baseUrl;

    final String? currentPhotoUrl = _pickedSitePhoto != null
        ? null
        : (_existingSitePhotoUrl != null
            ? (_existingSitePhotoUrl!.startsWith('http')
                ? _existingSitePhotoUrl
                : '$baseUrl$_existingSitePhotoUrl')
            : null);

    final hasPhoto = _pickedSitePhoto != null || currentPhotoUrl != null;

    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickSitePhoto,
        child: Container(
          width: 110,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBF9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFCDE0D5),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 18),
              SizedBox(width: 6),
              Text(
                'Add Photo',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Stack(
                  children: [
                    _pickedSitePhoto != null
                        ? Image.file(_pickedSitePhoto!)
                        : Image.network(currentPhotoUrl!),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _pickedSitePhoto != null
                ? Image.file(
                    _pickedSitePhoto!,
                    width: 110,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    currentPhotoUrl!,
                    width: 110,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 60,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _pickedSitePhoto = null;
                _existingSitePhotoUrl = null;
              });
            },
            child: const CircleAvatar(
              radius: 9,
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),
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
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
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
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: maxLines,
              keyboardType: keyboardType,
              readOnly: readOnly,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: readOnly ? const Color(0xFFF5F7F6) : Colors.white,
                suffixIcon: suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCDE0D5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
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

  Widget _buildChildTableSection({
    required String title,
    required IconData icon,
    required List<dynamic> items,
    required Widget Function(Map<String, dynamic> item, int index) itemBuilder,
  }) {
    return _buildCard(
      title: title,
      icon: icon,
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No logs found',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = Map<String, dynamic>.from(items[index]);
              return itemBuilder(item, index);
            },
          ),
      ],
    );
  }

  Widget _buildTabChip(int index, String label, IconData icon) {
    final isSelected = _selectedLogTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        selected: isSelected,
        selectedColor: AppColors.primaryButton,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedLogTab = index;
              _expandedItems.clear();
              _selectedImageTabs.clear();
            });
          }
        },
      ),
    );
  }

  Widget _buildExpandedContent(Map<String, dynamic> item, String itemKey) {
    final keys = item.keys.where((k) {
      return k != 'name' &&
          k != 'owner' &&
          k != 'creation' &&
          k != 'modified' &&
          k != 'modified_by' &&
          k != 'docstatus' &&
          k != 'idx' &&
          k != 'parent' &&
          k != 'parentfield' &&
          k != 'parenttype' &&
          k != 'doctype';
    }).toList();

    if (keys.isEmpty) return const SizedBox.shrink();

    final sdk = sl<FrappeSDK>();
    final baseUrl = sdk.baseUrl.endsWith('/')
        ? sdk.baseUrl.substring(0, sdk.baseUrl.length - 1)
        : sdk.baseUrl;

    // Identify image fields
    final imageKeys = keys.where((key) {
      final val = item[key];
      if (val == null || val.toString().isEmpty) return false;
      final valStr = val.toString();
      return (key.toLowerCase().contains('image') ||
              key.toLowerCase().contains('photo') ||
              valStr.startsWith('/files/') ||
              valStr.startsWith('/private/files/')) &&
          (valStr.toLowerCase().endsWith('.png') ||
              valStr.toLowerCase().endsWith('.jpg') ||
              valStr.toLowerCase().endsWith('.jpeg') ||
              valStr.toLowerCase().endsWith('.webp') ||
              valStr.toLowerCase().endsWith('.gif'));
    }).toList();

    // Identify non-image fields
    final nonImageKeys = keys.where((key) => !imageKeys.contains(key)).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render non-image fields
          ...nonImageKeys.map((key) {
            final val = item[key];
            if (val == null || val.toString().isEmpty) {
              return const SizedBox.shrink();
            }

            final formattedKey = key
                .split('_')
                .map((word) {
                  if (word.isEmpty) return '';
                  return word[0].toUpperCase() + word.substring(1);
                })
                .join(' ');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      formattedKey,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      val.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Render image fields (single or multiple in tabs)
          if (imageKeys.isNotEmpty) ...[
            if (imageKeys.length == 1) ...[
              // Single Image
              Builder(
                builder: (context) {
                  final key = imageKeys[0];
                  final valStr = item[key].toString();
                  final fullUrl = valStr.startsWith('http')
                      ? valStr
                      : '$baseUrl$valStr';
                  final formattedKey = key
                      .split('_')
                      .map((word) {
                        if (word.isEmpty) return '';
                        return word[0].toUpperCase() + word.substring(1);
                      })
                      .join(' ');

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            formattedKey,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildImageWidget(fullUrl)),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              // Multiple Images - tabbed view
              Builder(
                builder: (context) {
                  final selectedTab = _selectedImageTabs[itemKey] ?? 0;
                  final activeImgKey =
                      imageKeys[selectedTab < imageKeys.length
                          ? selectedTab
                          : 0];
                  final valStr = item[activeImgKey].toString();
                  final fullUrl = valStr.startsWith('http')
                      ? valStr
                      : '$baseUrl$valStr';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 140,
                          child: Text(
                            'Images',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImageWidget(fullUrl),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_left,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImageTabs[itemKey] =
                                            (selectedTab -
                                                1 +
                                                imageKeys.length) %
                                            imageKeys.length;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${selectedTab + 1} / ${imageKeys.length}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_right,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImageTabs[itemKey] =
                                            (selectedTab + 1) %
                                            imageKeys.length;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildImageWidget(String fullUrl) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Stack(
              children: [
                Image.network(fullUrl),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          fit: BoxFit.cover,
          height: 120,
          errorBuilder: (_, _, _) => Container(
            height: 120,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildLogItemRow({
    required String title,
    required String subtitle,
    String? trailing,
    bool isExpanded = false,
    VoidCallback? onTap,
    Widget? expandedContent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCDE0D5)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailing,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF4A8B5F),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
            if (isExpanded && expandedContent != null) ...[
              const Divider(color: Color(0xFFCDE0D5), height: 16),
              expandedContent,
            ],
          ],
        ),
  Widget _buildTasksPageContent() {
    final items = _document?.data['task'] as List? ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No Tasks recorded', Icons.task_alt_outlined);
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(items[index]);
        final taskId = item['task']?.toString() ?? '-';
        final subject = item['task_subject']?.toString() ?? '-';
        final itemKey = "0_$index";
        final isExpanded = _expandedItems.contains(itemKey);
        return _buildLogItemRow(
          title: taskId,
          subtitle: subject,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(itemKey);
              } else {
                _expandedItems.add(itemKey);
              }
            });
          },
          expandedContent: _buildExpandedContent(item, itemKey),
        );
      },
    );
  }

  Widget _buildActivityProgressPageContent() {
    final items = _document?.data['activity_progress'] as List? ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No Activity Progress recorded', Icons.trending_up_outlined);
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(items[index]);
        final taskSubject = item['task_subject']?.toString() ??
            item['parent_task_subject']?.toString() ?? '-';
        final achieved = item['achieved_today']?.toString() ?? '0';
        final planned = item['planned_today']?.toString() ?? '0';
        final total = item['total_qty']?.toString() ?? '0';
        final percent = item['percent_completed']?.toString() ?? '0';
        final uom = item['uom']?.toString() ?? '';
        final itemKey = "1_$index";
        final isExpanded = _expandedItems.contains(itemKey);
        return _buildLogItemRow(
          title: taskSubject,
          subtitle: 'Achieved: $achieved $uom / Planned: $planned $uom (Total: $total $uom)',
          trailing: '$percent%',
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(itemKey);
              } else {
                _expandedItems.add(itemKey);
              }
            });
          },
          expandedContent: _buildExpandedContent(item, itemKey),
        );
      },
    );
  }

  Widget _buildMaterialReceivedPageContent() {
    final items = _document?.data['material_received'] as List? ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No Material Received logs recorded', Icons.input_outlined);
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(items[index]);
        final itemCode = item['item_code']?.toString() ?? '-';
        final qty = item['quantity']?.toString() ?? '0';
        final warehouse = item['warehouse']?.toString() ?? '-';
        final uom = item['uom']?.toString() ?? '';
        final amount = item['amount']?.toString() ?? '';
        final itemKey = "2_$index";
        final isExpanded = _expandedItems.contains(itemKey);
        return _buildLogItemRow(
          title: itemCode,
          subtitle: 'Qty: $qty $uom | Warehouse: $warehouse',
          trailing: amount.isNotEmpty && amount != '0' ? '₹$amount' : null,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(itemKey);
              } else {
                _expandedItems.add(itemKey);
              }
            });
          },
          expandedContent: _buildExpandedContent(item, itemKey),
        );
      },
    );
  }

  Widget _buildMaterialDeliveriesPageContent() {
    final items = _document?.data['material_deliveries'] as List? ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No Material Deliveries recorded', Icons.local_shipping_outlined);
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(items[index]);
        final itemCode = item['item']?.toString() ?? '-';
        final qty = item['quantity']?.toString() ?? '0';
        final warehouse = item['warehouse']?.toString() ?? '-';
        final unit = item['unit']?.toString() ?? '';
        final itemKey = "3_$index";
        final isExpanded = _expandedItems.contains(itemKey);
        return _buildLogItemRow(
          title: itemCode,
          subtitle: 'Qty: $qty $unit | Warehouse: $warehouse',
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(itemKey);
              } else {
                _expandedItems.add(itemKey);
              }
            });
          },
          expandedContent: _buildExpandedContent(item, itemKey),
        );
      },
    );
  }

  Widget _buildManpowerPageContent() {
    final items = _document?.data['manpower_log'] as List? ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No Manpower Logs recorded', Icons.people_outline);
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(items[index]);
        final trade = item['trade_category']?.toString() ?? '-';
        final type = item['item_type']?.toString() ?? '-';
        final count = item['total']?.toString() ?? '0';
        final hours = item['hours_worked']?.toString() ?? '0';
        final itemKey = "4_$index";
        final isExpanded = _expandedItems.contains(itemKey);
        return _buildLogItemRow(
          title: '$trade ($type)',
          subtitle: 'Workers: $count | Hours: $hours',
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(itemKey);
              } else {
                _expandedItems.add(itemKey);
              }
            });
          },
          expandedContent: _buildExpandedContent(item, itemKey),
        );
      },
    );
  }

  Widget _buildEquipmentPageContent() {
    final items = _document?.data['equipment_log'] as List? ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No Equipment Logs recorded', Icons.construction_outlined);
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(items[index]);
        final name = item['equipment_name']?.toString() ?? '-';
        final qty = item['quantity']?.toString() ?? '0';
        final hours = item['working_hours']?.toString() ?? '0';
        final itemKey = "5_$index";
        final isExpanded = _expandedItems.contains(itemKey);
        return _buildLogItemRow(
          title: name,
          subtitle: 'Qty: $qty | Hours: $hours',
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(itemKey);
              } else {
                _expandedItems.add(itemKey);
              }
            });
          },
          expandedContent: _buildExpandedContent(item, itemKey),
        );
      },
    );
  }

  Widget _buildVisitorsPageContent() {
    final items = _document?.data['visitors'] as List? ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No Visitors recorded', Icons.person_pin_outlined);
    }
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(items[index]);
        final name = item['visitor_name']?.toString() ?? '-';
        final company = item['company']?.toString() ?? '-';
        final purpose = item['purpose']?.toString() ?? '-';
        final itemKey = "6_$index";
        final isExpanded = _expandedItems.contains(itemKey);
        return _buildLogItemRow(
          title: name,
          subtitle: 'Company: $company | Purpose: $purpose',
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(itemKey);
              } else {
                _expandedItems.add(itemKey);
              }
            });
          },
          expandedContent: _buildExpandedContent(item, itemKey),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkSearchBottomSheet extends StatefulWidget {
  final String doctype;
  final ValueChanged<String> onSelected;

  const _LinkSearchBottomSheet({
    required this.doctype,
    required this.onSelected,
  });

  @override
  State<_LinkSearchBottomSheet> createState() => _LinkSearchBottomSheetState();
}

class _LinkSearchBottomSheetState extends State<_LinkSearchBottomSheet> {
  final _searchController = TextEditingController();
  List<LinkOptionEntity> _options = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOptions([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sdk = sl<FrappeSDK>();
      final List<List<dynamic>> filters = [];
      if (query.isNotEmpty) {
        filters.add([widget.doctype, 'name', 'like', '%$query%']);
      }
      final options = await sdk.linkOptions.getLinkOptions(
        widget.doctype,
        filters: filters.isNotEmpty ? filters : null,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select ${widget.doctype}',
                style: const TextStyle(
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
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (val) => _fetchOptions(val),
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF2FAF6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _options.isEmpty
                ? const Center(child: Text('No options found'))
                : ListView.builder(
                    itemCount: _options.length,
                    itemBuilder: (context, idx) {
                      final option = _options[idx];
                      return ListTile(
                        title: Text(option.label ?? option.name),
                        subtitle: Text(option.name),
                        onTap: () => widget.onSelected(option.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
