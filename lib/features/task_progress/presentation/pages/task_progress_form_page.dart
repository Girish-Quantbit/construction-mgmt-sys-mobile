import 'dart:io';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/widgets/link_search_bottom_sheet.dart';
import 'package:cms/core/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/services/project_selection_service.dart';
import 'package:cms/core/services/homepage_reload_notifier.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../bloc/task_progress_form_bloc.dart';
import '../bloc/task_progress_form_event.dart';
import '../bloc/task_progress_form_state.dart';

class TaskProgressFormPage extends StatelessWidget {
  final String? progressName;

  const TaskProgressFormPage({super.key, this.progressName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<TaskProgressFormBloc>()
            ..add(InitializeTaskProgressFormEvent(progressName: progressName)),
      child: _TaskProgressFormView(progressName: progressName),
    );
  }
}

class _TaskProgressFormView extends StatefulWidget {
  final String? progressName;

  const _TaskProgressFormView({this.progressName});

  @override
  State<_TaskProgressFormView> createState() => _TaskProgressFormViewState();
}

class _TaskProgressFormViewState extends State<_TaskProgressFormView> {
  // Form Fields
  String? _project;
  DateTime? _siteDate;
  String? _shift;
  String? _siteEngineer;
  String? _remarks;
  String? _existingServerId;

  // Items Child Table
  List<Map<String, dynamic>> _items = [];

  String? _baseUrl;

  // Controllers
  final _projectController = TextEditingController();
  final _siteDateController = TextEditingController();
  final _siteEngineerController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _projectController.dispose();
    _siteDateController.dispose();
    _siteEngineerController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _populateFromDocumentData(Map<String, dynamic>? data, String? baseUrl) {
    _baseUrl = baseUrl;
    if (data != null) {
      _existingServerId = data['name']?.toString();
      _project = data['project']?.toString();
      _shift = data['shift']?.toString() ?? 'Day';
      _siteEngineer = data['site_engineer']?.toString();
      _remarks = data['remarks']?.toString();

      if (data['site_date'] != null) {
        _siteDate = DateTime.tryParse(data['site_date'].toString());
      }

      final rawItems = data['task_progress_details'] as List? ?? [];
      _items = rawItems.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      // Defaults for new entry
      _siteDate = DateTime.now();
      _project = sl<ProjectSelectionService>().selectedProject;
      _shift = 'Day';
    }

    _projectController.text = _project ?? '';
    _remarksController.text = _remarks ?? '';
    if (_siteDate != null) {
      _siteDateController.text = DateFormat('yyyy-MM-dd').format(_siteDate!);
    }

    _siteEngineerController.text = _siteEngineer ?? '';
    if (_siteEngineer != null && _siteEngineer!.isNotEmpty) {
      _loadSiteEngineerName(_siteEngineer!);
    }
  }

  Future<void> _loadSiteEngineerName(String id) async {
    try {
      final sdk = sl<FrappeSDK>();
      final empData = await sdk.api.doctype.getByName('Employee', id);
      final empName = empData['employee_name']?.toString() ?? id;
      if (mounted) {
        setState(() {
          _siteEngineerController.text = empName;
        });
      }
    } catch (_) {}
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
    final initialItem = index != null
        ? Map<String, dynamic>.from(_items[index])
        : {
            'task': '',
            'parent_task': '',
            'task_subject': '',
            'total_qty': 0.0,
            'planned_today': 0.0,
            'achieved_today': 0.0,
            'total_achieved': 0.0,
            'percent_completed': 0.0,
            'task_level': '',
            'task_level1': '',
            'task_level2': '',
            'task_level3': '',
            'task_level4': '',
            'task_level5': '',
            'task_level6': '',
            'task_level7': '',
            'task_level8': '',
            'task_level9': '',
            'task_level10': '',
            'level1_subject': '',
            'level2_subject': '',
            'level3_subject': '',
            'level4_subject': '',
            'level5_subject': '',
            'level6_subject': '',
            'level7_subject': '',
            'level8_subject': '',
            'level9_subject': '',
            'level10_subject': '',
          };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ItemEditorBottomSheet(
          initialItem: initialItem,
          project: _project,
          baseUrl: _baseUrl,
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
    setState(() => _items.removeAt(index));
  }

  void _saveDocument(BuildContext context) {
    if (_project == null || _project!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }
    if (_siteDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Site Date')),
      );
      return;
    }

    final dateStr = _siteDate != null
        ? DateFormat('yyyy-MM-dd').format(_siteDate!)
        : null;

    final Map<int, List<String>> childFilesMap = {};
    final cleanItems = <Map<String, dynamic>>[];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final copy = Map<String, dynamic>.from(item);
      final pending = copy.remove('__pendingImages');
      if (pending is List && pending.isNotEmpty) {
        childFilesMap[i] = pending.map((f) => (f as File).path).toList();
      }
      cleanItems.add(copy);
    }

    final payload = {
      'project': _project,
      'site_date': dateStr,
      'shift': _shift,
      'site_engineer': _siteEngineer,
      'remarks': _remarks,
      'task_progress_details': cleanItems,
    };

    context.read<TaskProgressFormBloc>().add(
      SaveTaskProgressFormEvent(
        existingServerId: _existingServerId,
        payload: payload,
        parentImagesPaths: const [],
        childImagesPaths: childFilesMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskProgressFormBloc, TaskProgressFormState>(
      listener: (context, state) {
        if (state.status == TaskProgressFormStatus.loadSuccess &&
            !_initialized) {
          setState(() {
            _initialized = true;
            _populateFromDocumentData(state.documentData, state.baseUrl);
          });
        } else if (state.status == TaskProgressFormStatus.saveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task Progress saved successfully')),
          );
          sl<HomepageReloadNotifier>().notifySave();
          Navigator.pop(context, true);
        } else if (state.status == TaskProgressFormStatus.loadFailure ||
            state.status == TaskProgressFormStatus.saveFailure) {
          final err = state.error ?? 'Unknown error occurred';
          showErrorDialog(
            context,
            state.status == TaskProgressFormStatus.saveFailure
                ? 'Save Failed'
                : 'Load Failed',
            err,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == TaskProgressFormStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.progressName != null
                  ? 'Edit Task Progress'
                  : 'New Task Progress',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: isLoading && !(_initialized)
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(sizeContextOf(context, 16)),
                  child: Column(
                    children: [
                      _buildCard(
                        title: 'General Info',
                        icon: Icons.info_outline,
                        children: [
                          _buildTextField(
                            label: 'Project *',
                            controller: _projectController,
                            placeholder: 'Select Project',
                            onTap: () => _showLinkSearch('Project', (val) {
                              setState(() {
                                _project = val;
                                _projectController.text = val;
                              });
                            }),
                          ),
                          SizedBox(height: sizeContextOf(context, 16)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Site Date *',
                                  controller: _siteDateController,
                                  placeholder: 'Select Date',
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                  ),
                                  onTap: _selectDate,
                                ),
                              ),
                              SizedBox(width: sizeContextOf(context, 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Shift',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    SizedBox(height: sizeContextOf(context, 6)),
                                    DropdownButtonFormField<String>(
                                      initialValue: _shift,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: sizeContextOf(
                                            context,
                                            12,
                                          ),
                                          vertical: sizeContextOf(context, 12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFCDE0D5),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF4A8B5F),
                                          ),
                                        ),
                                      ),
                                      items: ['Day', 'Night']
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _shift = val),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizeContextOf(context, 16)),
                          _buildTextField(
                            label: 'Site Engineer',
                            controller: _siteEngineerController,
                            placeholder: 'Select Site Engineer',
                            onTap: () => _showLinkSearch('Employee', (
                              val,
                            ) async {
                              setState(() {
                                _siteEngineer = val;
                                _siteEngineerController.text = val;
                              });
                              try {
                                final sdk = sl<FrappeSDK>();
                                final empData = await sdk.api.doctype.getByName(
                                  'Employee',
                                  val,
                                );
                                final empName =
                                    empData['employee_name']?.toString() ?? val;
                                setState(() {
                                  _siteEngineerController.text = empName;
                                });
                              } catch (_) {}
                            }),
                          ),
                          SizedBox(height: sizeContextOf(context, 16)),
                          _buildTextField(
                            label: 'Remarks',
                            controller: _remarksController,
                            placeholder: 'Add remarks...',
                            onChanged: (val) => _remarks = val,
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 16)),

                      // Details Child Table
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
                                const Text(
                                  'Task Progress Rows',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _openItemEditor(),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Row'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF4A8B5F),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: sizeContextOf(context, 12)),
                            if (_items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'No details added yet.',
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
                                  final subject =
                                      item['task_subject']?.toString() ??
                                      'Unnamed Task';
                                  final planned =
                                      double.tryParse(
                                        item['planned_today']?.toString() ??
                                            '0',
                                      ) ??
                                      0.0;
                                  final achieved =
                                      double.tryParse(
                                        item['achieved_today']?.toString() ??
                                            '0',
                                      ) ??
                                      0.0;
                                  return Container(
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subject,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Planned: ${planned.toStringAsFixed(0)} | Achieved: ${achieved.toStringAsFixed(0)}',
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
                                                color: Colors.blueGrey,
                                              ),
                                              onPressed: () =>
                                                  _openItemEditor(index: index),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _removeItem(index),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
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
                              label: const Text('Save Details'),
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
        Text(
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
}

// ---------------------------------------------------------------------------
// Item Editor Bottom Sheet — local image picking details preserved
// ---------------------------------------------------------------------------
class _ItemEditorBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialItem;
  final String? project;
  final String? baseUrl;
  final Function(
    String,
    ValueChanged<String>, {
    List<List<dynamic>>? extraFilters,
  })
  showLinkSearch;
  final Function(Map<String, dynamic>) onSave;

  const _ItemEditorBottomSheet({
    required this.initialItem,
    this.project,
    this.baseUrl,
    required this.showLinkSearch,
    required this.onSave,
  });

  @override
  State<_ItemEditorBottomSheet> createState() => _ItemEditorBottomSheetState();
}

class _ItemEditorBottomSheetState extends State<_ItemEditorBottomSheet> {
  late Map<String, dynamic> _item;
  late TextEditingController _parentTaskController;
  late TextEditingController _taskController;
  late TextEditingController _totalQtyController;
  late TextEditingController _plannedTodayController;
  late TextEditingController _achievedTodayController;

  late TextEditingController _taskSubjectController;
  late TextEditingController _parentTaskSubjectController;

  final Map<int, TextEditingController> _levelTaskControllers = {};
  final Map<int, TextEditingController> _levelSubjectControllers = {};

  bool _taskIsGroup = false;
  final Map<int, bool> _levelIsGroup = {};

  final ImagePicker _picker = ImagePicker();
  final List<File> _pendingImages = [];
  final List<String> _uploadedUrls = [];

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
    _parentTaskController = TextEditingController(
      text: _item['parent_task']?.toString(),
    );
    _taskController = TextEditingController(text: _item['task']?.toString());
    _totalQtyController = TextEditingController(
      text: _item['total_qty']?.toString() ?? '0.0',
    );
    _plannedTodayController = TextEditingController(
      text: _item['planned_today']?.toString() ?? '0.0',
    );
    _achievedTodayController = TextEditingController(
      text: _item['achieved_today']?.toString() ?? '0.0',
    );

    _taskSubjectController = TextEditingController(
      text: _item['task_subject']?.toString(),
    );
    _parentTaskSubjectController = TextEditingController(
      text: _item['parent_task_subject']?.toString(),
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

    final base = widget.baseUrl ?? '';
    for (int i = 1; i <= 10; i++) {
      final val = _item['image$i']?.toString() ?? '';
      if (val.isNotEmpty) {
        _uploadedUrls.add(val.startsWith('http') ? val : '$base$val');
      }
    }

    final existingPending = _item['__pendingImages'];
    if (existingPending is List) {
      _pendingImages.addAll(existingPending.cast<File>());
    }
  }

  @override
  void dispose() {
    _parentTaskController.dispose();
    _taskController.dispose();
    _totalQtyController.dispose();
    _plannedTodayController.dispose();
    _achievedTodayController.dispose();
    _taskSubjectController.dispose();
    _parentTaskSubjectController.dispose();
    for (var c in _levelTaskControllers.values) {
      c.dispose();
    }
    for (var c in _levelSubjectControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _pickChildImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        _pendingImages.add(File(file.path));
        _item['__pendingImages'] = _pendingImages;
      });
    }
  }

  void _removePendingImage(int index) {
    setState(() {
      _pendingImages.removeAt(index);
      _item['__pendingImages'] = _pendingImages;
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickChildImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickChildImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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
                'Edit Row Details',
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
                              _item['parent_task'],
                            ]);
                          }
                          widget.showLinkSearch('Task', (val) {
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
                          }, extraFilters: extra);
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
                                  widget.project,
                                ]);
                              }
                              final parentVal = i == 1
                                  ? _taskController.text
                                  : _levelTaskControllers[i - 1]!.text;
                              if (parentVal.isNotEmpty) {
                                extra.add([
                                  'Task',
                                  'parent_task',
                                  '=',
                                  parentVal,
                                ]);
                              }
                              widget.showLinkSearch('Task', (val) {
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
                              }, extraFilters: extra);
                            },
                          ),
                        ],
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),
                  _buildInnerCard(
                    title: 'Quantities',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Total Quantity',
                              controller: _totalQtyController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) => _item['total_qty'] =
                                  double.tryParse(val) ?? 0.0,
                            ),
                          ),
                          SizedBox(width: sizeContextOf(context, 8)),
                          Expanded(
                            child: _buildTextField(
                              label: 'Planned Today',
                              controller: _plannedTodayController,
                              placeholder: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) => _item['planned_today'] =
                                  double.tryParse(val) ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizeContextOf(context, 12)),
                      _buildTextField(
                        label: 'Achieved Today *',
                        controller: _achievedTodayController,
                        placeholder: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) => _item['achieved_today'] =
                            double.tryParse(val) ?? 0.0,
                      ),
                    ],
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),
                  _buildInnerCard(
                    title: 'Images Upload',
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Photos',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Image'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4A8B5F),
                            ),
                          ),
                        ],
                      ),
                      if (_uploadedUrls.isEmpty && _pendingImages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'No images attached',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ..._uploadedUrls.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                              ..._pendingImages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final file = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          file,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _removePendingImage(index),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
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
              if (_taskController.text.isNotEmpty) {
                activeTask = _taskController.text;
              }
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

              _item['task'] = activeTask;
              _item['parent_task'] = _parentTaskController.text;

              for (int i = 1; i <= 10; i++) {
                _item[_getTaskKey(i)] = _levelTaskControllers[i]!.text;
                _item[_getSubjectKey(i)] = _levelSubjectControllers[i]!.text;
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
              'Save Row',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
