import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';

class TaskSelectionResult {
  final String? parentTask;
  final String? parentTaskSubject;
  final String? task;
  final String? taskSubject;
  final Map<int, String> levels;
  final Map<int, String> levelSubjects;
  final String? activeTask;

  TaskSelectionResult({
    this.parentTask,
    this.parentTaskSubject,
    this.task,
    this.taskSubject,
    required this.levels,
    required this.levelSubjects,
    this.activeTask,
  });
}

class TaskSelectionWidget extends StatefulWidget {
  final String? project;
  final String? initialParentTask;
  final String? initialTask;
  final Map<int, String>? initialLevels;
  final Function(
    String doctype,
    ValueChanged<String> callback, {
    List<List<dynamic>>? extraFilters,
  }) showLinkSearch;
  final Function(TaskSelectionResult result) onTaskChanged;

  const TaskSelectionWidget({
    super.key,
    required this.project,
    this.initialParentTask,
    this.initialTask,
    this.initialLevels,
    required this.showLinkSearch,
    required this.onTaskChanged,
  });

  @override
  State<TaskSelectionWidget> createState() => _TaskSelectionWidgetState();
}

class _TaskSelectionWidgetState extends State<TaskSelectionWidget> {
  late TextEditingController _parentTaskController;
  late TextEditingController _taskController;
  late TextEditingController _parentTaskSubjectController;
  late TextEditingController _taskSubjectController;

  final Map<int, TextEditingController> _levelTaskControllers = {};
  final Map<int, TextEditingController> _levelSubjectControllers = {};

  bool _taskIsGroup = false;
  final Map<int, bool> _levelIsGroup = {};

  @override
  void initState() {
    super.initState();
    _parentTaskController = TextEditingController(text: widget.initialParentTask);
    final hasParent = widget.initialParentTask != null && widget.initialParentTask!.isNotEmpty;
    _taskController = TextEditingController(
      text: hasParent ? widget.initialTask : null,
    );
    _parentTaskSubjectController = TextEditingController();
    _taskSubjectController = TextEditingController();

    for (int i = 1; i <= 10; i++) {
      _levelTaskControllers[i] = TextEditingController(
        text: widget.initialLevels?[i],
      );
      _levelSubjectControllers[i] = TextEditingController();
    }

    _initializeTaskData();
  }

  @override
  void didUpdateWidget(covariant TaskSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      // Clear all fields if project changes
      _clearAllSelection();
    }
  }

  void _clearAllSelection() {
    _parentTaskController.clear();
    _parentTaskSubjectController.clear();
    _taskController.clear();
    _taskSubjectController.clear();
    _taskIsGroup = false;
    _levelIsGroup.clear();
    for (int i = 1; i <= 10; i++) {
      _levelTaskControllers[i]?.clear();
      _levelSubjectControllers[i]?.clear();
    }
    _triggerChanged();
  }

  Future<void> _initializeTaskData() async {
    if (widget.initialTask != null &&
        widget.initialTask!.isNotEmpty &&
        (widget.initialParentTask == null || widget.initialParentTask!.isEmpty)) {
      try {
        final sdk = sl<FrappeSDK>();
        final List<Map<String, dynamic>> hierarchy = [];
        String? currentTask = widget.initialTask;

        while (currentTask != null && currentTask.isNotEmpty) {
          final taskData = await sdk.api.doctype.getByName('Task', currentTask);
          final subject = taskData['subject']?.toString() ?? '';
          final isGroup = (taskData['is_group'] as num?)?.toInt() == 1 ||
              taskData['is_group'] == true ||
              taskData['is_group']?.toString() == 'Yes';
          hierarchy.insert(0, {
            'task': currentTask,
            'subject': subject,
            'is_group': isGroup,
          });
          currentTask = taskData['parent_task']?.toString();
        }

        if (mounted && hierarchy.isNotEmpty) {
          setState(() {
            _parentTaskController.text = hierarchy[0]['task'] as String;
            _parentTaskSubjectController.text = hierarchy[0]['subject'] as String;

            if (hierarchy.length > 1) {
              _taskController.text = hierarchy[1]['task'] as String;
              _taskSubjectController.text = hierarchy[1]['subject'] as String;
              _taskIsGroup = hierarchy[1]['is_group'] as bool;
            }

            for (int i = 2; i < hierarchy.length; i++) {
              final levelIndex = i - 1;
              if (levelIndex <= 10) {
                _levelTaskControllers[levelIndex]!.text = hierarchy[i]['task'] as String;
                _levelSubjectControllers[levelIndex]!.text = hierarchy[i]['subject'] as String;
                _levelIsGroup[levelIndex] = hierarchy[i]['is_group'] as bool;
              }
            }
          });
          _triggerChanged();
        }
      } catch (_) {}
      return;
    }

    if (_parentTaskController.text.isNotEmpty) {
      _fetchTaskSubject(_parentTaskController.text, (subject) {
        if (mounted) {
          setState(() {
            _parentTaskSubjectController.text = subject;
          });
        }
      });
    }
    if (_taskController.text.isNotEmpty) {
      _fetchTaskIsGroup(_taskController.text, (subject, isGroup) {
        if (mounted) {
          setState(() {
            _taskSubjectController.text = subject;
            _taskIsGroup = isGroup;
          });
        }
      });
    }
    for (int i = 1; i <= 10; i++) {
      final taskVal = _levelTaskControllers[i]?.text ?? '';
      if (taskVal.isNotEmpty) {
        final levelIndex = i;
        _fetchTaskIsGroup(taskVal, (subject, isGroup) {
          if (mounted) {
            setState(() {
              _levelSubjectControllers[levelIndex]?.text = subject;
              _levelIsGroup[levelIndex] = isGroup;
            });
          }
        });
      }
    }
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

  String? _getActiveTask() {
    for (int i = 10; i >= 1; i--) {
      if (_levelTaskControllers[i]!.text.isNotEmpty) {
        return _levelTaskControllers[i]!.text;
      }
    }
    if (_taskController.text.isNotEmpty) {
      return _taskController.text;
    }
    if (_parentTaskController.text.isNotEmpty) {
      return _parentTaskController.text;
    }
    return null;
  }

  void _triggerChanged() {
    final levels = <int, String>{};
    final levelSubjects = <int, String>{};
    for (int i = 1; i <= 10; i++) {
      if (_levelTaskControllers[i]!.text.isNotEmpty) {
        levels[i] = _levelTaskControllers[i]!.text;
        levelSubjects[i] = _levelSubjectControllers[i]!.text;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onTaskChanged(
          TaskSelectionResult(
            parentTask: _parentTaskController.text.isNotEmpty ? _parentTaskController.text : null,
            parentTaskSubject: _parentTaskSubjectController.text.isNotEmpty ? _parentTaskSubjectController.text : null,
            task: _taskController.text.isNotEmpty ? _taskController.text : null,
            taskSubject: _taskSubjectController.text.isNotEmpty ? _taskSubjectController.text : null,
            levels: levels,
            levelSubjects: levelSubjects,
            activeTask: _getActiveTask(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _parentTaskController.dispose();
    _taskController.dispose();
    _parentTaskSubjectController.dispose();
    _taskSubjectController.dispose();
    for (var controller in _levelTaskControllers.values) {
      controller.dispose();
    }
    for (var controller in _levelSubjectControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        SizedBox(height: sizeContextOf(context, 6)),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextField(
              controller: controller,
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
    return _buildInnerCard(
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
                _parentTaskController.text = val;
                // Clear child fields
                _taskController.text = '';
                _taskSubjectController.text = '';
                _taskIsGroup = false;
                _levelIsGroup.clear();
                for (int j = 1; j <= 10; j++) {
                  _levelTaskControllers[j]?.text = '';
                  _levelSubjectControllers[j]?.text = '';
                }
              });
              _triggerChanged();
              _fetchTaskSubject(val, (subject) {
                if (mounted) {
                  setState(() {
                    _parentTaskSubjectController.text = subject;
                  });
                  _triggerChanged();
                }
              });
            },
            extraFilters: widget.project != null && widget.project!.isNotEmpty
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
            if (widget.project != null && widget.project!.isNotEmpty) {
              extra.add(['Task', 'project', '=', widget.project]);
            }
            if (_parentTaskController.text.isNotEmpty) {
              extra.add([
                'Task',
                'parent_task',
                '=',
                _parentTaskController.text,
              ]);
            }
            widget.showLinkSearch('Task', (val) {
              setState(() {
                _taskController.text = val;
                // Clear levels below
                _levelIsGroup.clear();
                for (int j = 1; j <= 10; j++) {
                  _levelTaskControllers[j]?.text = '';
                  _levelSubjectControllers[j]?.text = '';
                }
              });
              _triggerChanged();
              _fetchTaskIsGroup(val, (subject, isGroup) {
                if (mounted) {
                  setState(() {
                    _taskSubjectController.text = subject;
                    _taskIsGroup = isGroup;
                  });
                  _triggerChanged();
                }
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
                if (widget.project != null && widget.project!.isNotEmpty) {
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
                    _levelTaskControllers[i]!.text = val;
                    // Clear levels below
                    for (int j = i + 1; j <= 10; j++) {
                      _levelTaskControllers[j]?.text = '';
                      _levelSubjectControllers[j]?.text = '';
                      _levelIsGroup.remove(j);
                    }
                  });
                  _triggerChanged();
                  _fetchTaskIsGroup(val, (subject, isGroup) {
                    if (mounted) {
                      setState(() {
                        _levelSubjectControllers[i]!.text = subject;
                        _levelIsGroup[i] = isGroup;
                      });
                      _triggerChanged();
                    }
                  });
                }, extraFilters: extra);
              },
            ),
          ],
      ],
    );
  }
}
