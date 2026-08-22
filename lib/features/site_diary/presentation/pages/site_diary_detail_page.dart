import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/site_diary_bloc.dart';
import '../bloc/site_diary_event.dart';
import '../bloc/site_diary_state.dart';
import 'site_diary_form_page.dart';
import '../../domain/entities/site_diary.dart';

class SiteDiaryDetailPage extends StatefulWidget {
  final String diaryName;

  const SiteDiaryDetailPage({super.key, required this.diaryName});

  @override
  State<SiteDiaryDetailPage> createState() => _SiteDiaryDetailPageState();
}

class _SiteDiaryDetailPageState extends State<SiteDiaryDetailPage> {
  int _selectedLogTab = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedLogTab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _selectedLogTab) return;
    setState(() {
      _selectedLogTab = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
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

  String _getTabCountText(SiteDiary diary, int index) {
    switch (index) {
      case 0:
        return '${diary.tasks.length}';
      case 1:
        return '${diary.activityProgress.length}';
      case 2:
        return '${diary.materialsReceived.length}';
      case 3:
        return '${diary.materialsDelivered.length}';
      case 4:
        return '${diary.manpowerLogs.length}';
      case 5:
        return '${diary.equipmentLogs.length}';
      case 6:
        return '${diary.visitors.length}';
      default:
        return '0';
    }
  }

  Widget _buildCarouselNavigator(BuildContext context, SiteDiary diary) {
    final countText = _getTabCountText(diary, _selectedLogTab);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sizeContextOf(context, 8.0),
          vertical: sizeContextOf(context, 8.0),
        ),
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
                : SizedBox(width: sizeContextOf(context, 48)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTabIcon(_selectedLogTab),
                  color: const Color(0xFF5A8B6C),
                ),
                SizedBox(width: sizeContextOf(context, 10)),
                Text(
                  _getTabLabel(_selectedLogTab),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 8)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sizeContextOf(context, 8),
                    vertical: sizeContextOf(context, 2),
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
                : SizedBox(width: sizeContextOf(context, 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: sizeContextOf(context, 32),
        horizontal: sizeContextOf(context, 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          SizedBox(height: sizeContextOf(context, 12)),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<SiteDiaryBloc>()..add(LoadSiteDiaryDetails(widget.diaryName)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
          title: BlocBuilder<SiteDiaryBloc, SiteDiaryState>(
            builder: (context, state) {
              final diary = state.selectedDiary;
              if (diary == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diary.project ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    widget.diaryName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            BlocBuilder<SiteDiaryBloc, SiteDiaryState>(
              builder: (context, state) {
                final diary = state.selectedDiary;
                if (diary == null) return const SizedBox.shrink();
                final docstatus = diary.rawData['docstatus'];
                final isSubmitted =
                    docstatus == 1 || docstatus == '1' || docstatus == 1.0;

                if (!isSubmitted) {
                  return IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black87),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SiteDiaryFormPage(diaryName: widget.diaryName),
                        ),
                      );
                      if (result == true && context.mounted) {
                        context.read<SiteDiaryBloc>().add(
                          LoadSiteDiaryDetails(widget.diaryName),
                        );
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(width: sizeContextOf(context, 8)),
          ],
        ),
        body: BlocBuilder<SiteDiaryBloc, SiteDiaryState>(
          builder: (context, state) {
            if (state.detailStatus == SiteDiaryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.detailStatus == SiteDiaryStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSizes.s16),
                    Text(state.errorMessage ?? 'Error loading details'),
                    const SizedBox(height: AppSizes.s16),
                    ElevatedButton(
                      onPressed: () => context.read<SiteDiaryBloc>().add(
                        LoadSiteDiaryDetails(widget.diaryName),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final diary = state.selectedDiary;
            if (diary == null) {
              return const Center(child: Text('No details found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'General Information',
                    icon: Icons.info_outline,
                  ),
                  _buildGeneralInfoCard(context, diary),
                  const SizedBox(height: AppSizes.s24),

                  _SectionHeader(
                    title: 'Weather Details',
                    icon: Icons.wb_sunny_outlined,
                  ),
                  _buildWeatherCard(context, diary),
                  const SizedBox(height: AppSizes.s24),

                  if (diary.generalRemarks != null &&
                      diary.generalRemarks!.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Remarks',
                      icon: Icons.notes_outlined,
                    ),
                    _buildRemarksCard(context, diary),
                    const SizedBox(height: AppSizes.s24),
                  ],

                  // Unified Carousel Log Navigator & Headers
                  _buildCarouselNavigator(context, diary),
                  SizedBox(height: sizeContextOf(context, 16)),

                  _buildActiveSection(context, diary),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveSection(BuildContext context, SiteDiary diary) {
    switch (_selectedLogTab) {
      case 0:
        return _buildTasksSection(context, diary);
      case 1:
        return _buildActivityProgressSection(context, diary);
      case 2:
        return _buildMaterialReceivedSection(context, diary);
      case 3:
        return _buildMaterialDeliverySection(context, diary);
      case 4:
        return _buildManpowerSection(context, diary);
      case 5:
        return _buildEquipmentSection(context, diary);
      case 6:
        return _buildVisitorsSection(context, diary);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'submitted':
        bgColor = const Color(0xFFA7D5B0);
        textColor = Colors.white;
        icon = Icons.star;
        break;
      case 'draft':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case 'cancelled':
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      default:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, 10),
        vertical: sizeContextOf(context, 4),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            SizedBox(width: sizeContextOf(context, 4)),
          ],
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard(BuildContext context, SiteDiary diary) {
    final data = diary.rawData;
    final siteDateStr = diary.siteDate != null
        ? DateFormat('dd MMM yyyy').format(diary.siteDate!)
        : 'N/A';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    diary.project ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildStatusBadge(context, diary.status),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 16)),
            const Divider(color: Color(0xFFEEEEEE), height: 1),
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diary No',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['name'] ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Site Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        siteDateStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Day No of Contract',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['day_no_of_contract']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shift',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['shift'] ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Site Engineer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['site_engineer_name'] ??
                            data['site_engineer'] ??
                            '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Work Stopped',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['work_stopped'] == 1 ||
                                data['work_stopped'] == true
                            ? 'Yes'
                            : 'No',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data['site_photos'] != null) ...[
              SizedBox(height: sizeContextOf(context, 20)),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Site Photos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 6)),
                        const Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, SiteDiary diary) {
    final data = diary.rawData;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weather (AM)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        diary.weatherAm ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weather (PM)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        diary.weatherPm ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Max Temp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['max_temp'] != null
                            ? '${data['max_temp']}°C'
                            : '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Min Temp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['min_temp'] != null
                            ? '${data['min_temp']}°C'
                            : '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wind Speed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 6)),
                      Text(
                        data['wind_speed_kmh'] != null
                            ? '${data['wind_speed_kmh']} km/h'
                            : '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard(BuildContext context, SiteDiary diary) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diary.generalRemarks ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, SiteDiary diary) {
    final tasks = diary.tasks;
    if (tasks.isEmpty) {
      return _buildEmptyState(
        context,
        'No Tasks recorded',
        Icons.task_alt_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: tasks.map((item) {
        return _ExpandableLogCard(
          title: item.task,
          subtitle: 'Task ID',
          collapsedSummary: 'Subject: ${item.taskSubject ?? "-"}',
          detailRows: [
            [
              _LogField(label: 'Task ID', value: item.task),
              _LogField(label: 'Subject', value: item.taskSubject ?? '-'),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActivityProgressSection(BuildContext context, SiteDiary diary) {
    final progress = diary.activityProgress;
    if (progress.isEmpty) {
      return _buildEmptyState(
        context,
        'No Activity Progress recorded',
        Icons.trending_up_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: progress.map((item) {
        return _ExpandableLogCard(
          title: item.taskSubject ?? item.task ?? 'Activity',
          subtitle: item.parentTaskSubject ?? item.parentTask ?? 'Parent Task',
          badgeText: '${item.percentCompleted}%',
          badgeColor: const Color(0xFFE1F2E9),
          badgeTextColor: const Color(0xFF5A8B6C),
          collapsedSummary:
              'Achieved: ${item.achievedToday} ${item.uom ?? "Units"} • Planned: ${item.plannedToday}',
          detailRows: [
            [
              _LogField(label: 'Parent Task', value: item.parentTask ?? '-'),
              _LogField(
                label: 'Parent Subject',
                value: item.parentTaskSubject ?? '-',
              ),
            ],
            [
              _LogField(label: 'Task ID', value: item.task ?? '-'),
              _LogField(label: 'Task Subject', value: item.taskSubject ?? '-'),
            ],
            [
              _LogField(
                label: 'Achieved Today',
                value: item.achievedToday.toString(),
              ),
              _LogField(
                label: 'Planned Today',
                value: item.plannedToday.toString(),
              ),
            ],
            [
              _LogField(label: 'Total Qty', value: item.totalQty.toString()),
              _LogField(
                label: 'Total Achieved',
                value: item.totalAchieved.toString(),
              ),
            ],
            [
              _LogField(
                label: 'Completed %',
                value: '${item.percentCompleted}%',
                valueColor: const Color(0xFF5A8B6C),
              ),
              _LogField(label: 'UOM', value: item.uom ?? '-'),
            ],
            [
              _LogField(
                label: 'Construction Type',
                value: item.constructionType ?? '-',
              ),
              _LogField(label: '', value: ''),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildManpowerSection(BuildContext context, SiteDiary diary) {
    final logs = diary.manpowerLogs;
    if (logs.isEmpty) {
      return _buildEmptyState(
        context,
        'No Manpower Logs recorded',
        Icons.people_outline,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: logs.map((item) {
        return _ExpandableLogCard(
          title: item.tradeCategory ?? 'Manpower',
          subtitle: item.subcontractor ?? item.contractor ?? 'Contractor',
          badgeText: '${item.total} Pax',
          badgeColor: const Color(0xFFF7F3EE),
          badgeTextColor: const Color(0xFF6B5E52),
          collapsedSummary:
              'Total Wage: ₹${item.totalWage} • Gang No: ${item.gangNo ?? "-"}',
          detailRows: [
            [
              _LogField(label: 'Parent Task', value: item.parentTask ?? '-'),
              _LogField(label: 'Task ID', value: item.task ?? '-'),
            ],
            [
              _LogField(
                label: 'Subcontractor',
                value: item.subcontractor ?? '-',
              ),
              _LogField(label: 'Contractor', value: item.contractor ?? '-'),
            ],
            [
              _LogField(
                label: 'Trade Category',
                value: item.tradeCategory ?? '-',
              ),
              _LogField(label: 'Item Type', value: item.itemType ?? '-'),
            ],
            [
              _LogField(label: 'Gang No', value: item.gangNo ?? '-'),
              _LogField(label: 'Daily Wages', value: '₹${item.dailyWages}'),
            ],
            [
              _LogField(
                label: 'Skilled Workers',
                value: item.skilled.toString(),
              ),
              _LogField(
                label: 'Unskilled Workers',
                value: item.unskilled.toString(),
              ),
            ],
            [
              _LogField(
                label: 'Hours Worked',
                value: '${item.hoursWorked} hrs',
              ),
              _LogField(label: 'OT Hours', value: '${item.overtimeHours} hrs'),
            ],
            [
              _LogField(label: 'Work Area', value: item.workArea ?? '-'),
              _LogField(label: 'Activity', value: item.activity ?? '-'),
            ],
            [
              _LogField(
                label: 'Total Wage',
                value: '₹${item.totalWage}',
                valueColor: Colors.black87,
              ),
              _LogField(label: '', value: ''),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentSection(BuildContext context, SiteDiary diary) {
    final logs = diary.equipmentLogs;
    if (logs.isEmpty) {
      return _buildEmptyState(
        context,
        'No Equipment Logs recorded',
        Icons.construction_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: logs.map((item) {
        return _ExpandableLogCard(
          title: item.equipmentName ?? item.item ?? 'Equipment',
          subtitle: item.contractor ?? 'Contractor',
          badgeText: 'Qty: ${item.quantity}',
          collapsedSummary:
              'Total: ₹${item.totalAmount} • Working Hours: ${item.workingHours} hrs',
          detailRows: [
            [
              _LogField(label: 'Parent Task', value: item.parentTask ?? '-'),
              _LogField(label: 'Task ID', value: item.task ?? '-'),
            ],
            [
              _LogField(
                label: 'Equipment Name',
                value: item.equipmentName ?? '-',
              ),
              _LogField(label: 'Item', value: item.item ?? '-'),
            ],
            [
              _LogField(label: 'Owner Type', value: item.ownerType ?? '-'),
              _LogField(label: 'Supplier', value: item.hireSupplier ?? '-'),
            ],
            [
              _LogField(label: 'Quantity', value: item.quantity.toString()),
              _LogField(label: 'Rate', value: '₹${item.rate}'),
            ],
            [
              _LogField(
                label: 'Working Hours',
                value: '${item.workingHours} hrs',
              ),
              _LogField(
                label: 'Total Amount',
                value: '₹${item.totalAmount}',
                valueColor: Colors.black87,
              ),
            ],
            [
              _LogField(label: 'Contractor', value: item.contractor ?? '-'),
              _LogField(label: 'Remarks', value: item.remarks ?? '-'),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMaterialReceivedSection(BuildContext context, SiteDiary diary) {
    final materials = diary.materialsReceived;
    if (materials.isEmpty) {
      return _buildEmptyState(
        context,
        'No Material Received logs recorded',
        Icons.input_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: materials.map((item) {
        return _ExpandableLogCard(
          title: item.itemCode ?? 'Material',
          subtitle: 'Item Code',
          badgeText: '${item.quantity} ${item.uom ?? "Units"}',
          collapsedSummary: 'Amount: ₹${item.amount} • Rate: ₹${item.rate}',
          detailRows: [
            [
              _LogField(label: 'Item Code', value: item.itemCode ?? '-'),
              _LogField(label: 'UOM', value: item.uom ?? '-'),
            ],
            [
              _LogField(label: 'Quantity', value: item.quantity.toString()),
              _LogField(label: 'Rate', value: '₹${item.rate}'),
            ],
            [
              _LogField(label: 'Amount', value: '₹${item.amount}'),
              _LogField(label: 'Warehouse', value: item.warehouse ?? '-'),
            ],
            [
              _LogField(label: 'Transaction', value: item.transaction ?? '-'),
              _LogField(label: 'Type', value: item.transactionType ?? '-'),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMaterialDeliverySection(BuildContext context, SiteDiary diary) {
    final deliveries = diary.materialsDelivered;
    if (deliveries.isEmpty) {
      return _buildEmptyState(
        context,
        'No Material Deliveries recorded',
        Icons.local_shipping_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: deliveries.map((item) {
        return _ExpandableLogCard(
          title: item.item ?? 'Delivery',
          subtitle: item.supplier ?? 'Supplier',
          badgeText: '${item.quantity} ${item.unit ?? "Units"}',
          collapsedSummary:
              'Warehouse: ${item.warehouse ?? "-"} • Delivery Note: ${item.deliveryNote ?? "-"}',
          detailRows: [
            [
              _LogField(label: 'Parent Task', value: item.parentTask ?? '-'),
              _LogField(label: 'Task ID', value: item.task ?? '-'),
            ],
            [
              _LogField(label: 'Item', value: item.item ?? '-'),
              _LogField(label: 'Type', value: item.itemType ?? '-'),
            ],
            [
              _LogField(label: 'Unit', value: item.unit ?? '-'),
              _LogField(label: 'Supplier', value: item.supplier ?? '-'),
            ],
            [
              _LogField(label: 'Warehouse', value: item.warehouse ?? '-'),
              _LogField(label: 'Quantity', value: item.quantity.toString()),
            ],
            [
              _LogField(
                label: 'Delivery Note',
                value: item.deliveryNote ?? '-',
              ),
              _LogField(label: 'Linked PO', value: item.linkedPo ?? '-'),
            ],
            [
              _LogField(
                label: 'Insp. Required',
                value: item.inspectionRequired ? 'Yes' : 'No',
              ),
              _LogField(
                label: 'Insp. Done',
                value: item.inspectionDone ? 'Yes' : 'No',
              ),
            ],
            [
              _LogField(
                label: 'Accepted',
                value: item.accepted ? 'Yes' : 'No',
                valueColor: item.accepted ? const Color(0xFF5A8B6C) : null,
              ),
              _LogField(
                label: 'Rejection Reason',
                value: item.rejectionReason ?? '-',
              ),
            ],
            [
              _LogField(label: 'Description', value: item.description ?? '-'),
              _LogField(label: '', value: ''),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildVisitorsSection(BuildContext context, SiteDiary diary) {
    final visitors = diary.visitors;
    if (visitors.isEmpty) {
      return _buildEmptyState(
        context,
        'No Visitors recorded',
        Icons.person_pin_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: visitors.map((item) {
        return _ExpandableLogCard(
          title: item.visitorName ?? 'Visitor',
          subtitle: item.company ?? 'Company',
          badgeText: '${item.timeIn ?? "-"} - ${item.timeOut ?? "-"}',
          collapsedSummary: 'Purpose: ${item.purpose ?? "-"}',
          detailRows: [
            [
              _LogField(label: 'Visitor Name', value: item.visitorName ?? '-'),
              _LogField(label: 'Company', value: item.company ?? '-'),
            ],
            [
              _LogField(label: 'Purpose', value: item.purpose ?? '-'),
              _LogField(
                label: 'Accompanied By',
                value: item.accompaniedBy ?? '-',
              ),
            ],
            [
              _LogField(label: 'Time In', value: item.timeIn ?? '-'),
              _LogField(label: 'Time Out', value: item.timeOut ?? '-'),
            ],
            [
              _LogField(
                label: 'Safety Inducted',
                value: item.safetyInducted ? 'Yes' : 'No',
              ),
              _LogField(label: 'Notes', value: item.notes ?? '-'),
            ],
          ],
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: sizeContextOf(context, 8),
        bottom: AppSizes.s12,
        left: AppSizes.s4,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: AppSizes.s8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableLogCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final String collapsedSummary;
  final List<List<_LogField>> detailRows;

  const _ExpandableLogCard({
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.collapsedSummary,
    required this.detailRows,
  });

  @override
  State<_ExpandableLogCard> createState() => _ExpandableLogCardState();
}

class _ExpandableLogCardState extends State<_ExpandableLogCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: sizeContextOf(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isExpanded ? const Color(0xFFE1F2E9) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sizeContextOf(context, 16.0),
            vertical: sizeContextOf(context, 12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty)
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.badgeText != null &&
                          widget.badgeText!.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: sizeContextOf(context, 8),
                            vertical: sizeContextOf(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: widget.badgeColor ?? const Color(0xFFF7F3EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.badgeText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.badgeTextColor ??
                                  const Color(0xFF6B5E52),
                            ),
                          ),
                        ),
                      SizedBox(width: sizeContextOf(context, 8)),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (!_isExpanded) ...[
                SizedBox(height: sizeContextOf(context, 6)),
                Text(
                  widget.collapsedSummary,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: sizeContextOf(context, 10)),
                          const Divider(color: Color(0xFFEEEEEE), height: 1),
                          SizedBox(height: sizeContextOf(context, 10)),
                          ...widget.detailRows.map((row) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: sizeContextOf(context, 10.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: row.map((field) {
                                  if (field.label.isEmpty &&
                                      field.value.isEmpty) {
                                    return const Expanded(child: SizedBox());
                                  }
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: sizeContextOf(context, 8.0),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            field.label,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            height: sizeContextOf(context, 2),
                                          ),
                                          Text(
                                            field.value,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  field.valueColor ??
                                                  Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogField {
  final String label;
  final String value;
  final Color? valueColor;

  _LogField({required this.label, required this.value, this.valueColor});
}
