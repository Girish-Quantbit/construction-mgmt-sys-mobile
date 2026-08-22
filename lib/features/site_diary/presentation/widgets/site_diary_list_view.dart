import 'package:cms/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/site_diary_bloc.dart';
import '../bloc/site_diary_event.dart';
import '../bloc/site_diary_state.dart';
import '../pages/site_diary_form_page.dart';
import '../pages/site_diary_detail_page.dart';
import '../../domain/entities/site_diary.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sort_chips.dart';
import '../../../../core/widgets/filter_button.dart';

class SiteDiaryListView extends StatefulWidget {
  final String? project;
  const SiteDiaryListView({super.key, this.project});

  @override
  State<SiteDiaryListView> createState() => _SiteDiaryListViewState();
}

class _SiteDiaryListViewState extends State<SiteDiaryListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<SiteDiaryBloc>().add(LoadSiteDiaries(project: widget.project));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SiteDiaryBloc>().add(LoadMoreSiteDiaries());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showFilterBottomSheet(BuildContext context) {
    final bloc = context.read<SiteDiaryBloc>();
    final currentState = bloc.state;
    String? selectedStatus = currentState.filterStatus;

    String sortLabel = 'Newest Date';
    if (_sortBy == 'date_asc') sortLabel = 'Oldest Date';
    if (_sortBy == 'id_desc') sortLabel = 'ID (Z-A)';
    if (_sortBy == 'id_asc') sortLabel = 'ID (A-Z)';

    String? selectedSort = sortLabel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FilterBottomSheet(
              title: 'Filter & Sort Site Diaries',
              onReset: () {
                bloc.add(FilterChanged(null));
                setState(() {
                  _sortBy = 'date_desc';
                });
              },
              onApply: () {
                bloc.add(FilterChanged(selectedStatus));
                setState(() {
                  if (selectedSort == 'Newest Date') _sortBy = 'date_desc';
                  if (selectedSort == 'Oldest Date') _sortBy = 'date_asc';
                  if (selectedSort == 'ID (Z-A)') _sortBy = 'id_desc';
                  if (selectedSort == 'ID (A-Z)') _sortBy = 'id_asc';
                });
              },
              children: [
                FilterDropdownSelector(
                  title: 'Status',
                  hintText: 'Select Status',
                  value: selectedStatus,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Status'),
                        children:
                            [
                                  'Draft',
                                  'Submitted',
                                  'Approved by PM',
                                  'Acknowledged by Consultant',
                                ]
                                .map(
                                  (status) => SimpleDialogOption(
                                    onPressed: () {
                                      setModalState(() {
                                        selectedStatus = status;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  },
                ),
                FilterDropdownSelector(
                  title: 'Sort By',
                  hintText: 'Select Sort Order',
                  value: selectedSort,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Sort Order'),
                        children:
                            [
                                  'Newest Date',
                                  'Oldest Date',
                                  'ID (Z-A)',
                                  'ID (A-Z)',
                                ]
                                .map(
                                  (sort) => SimpleDialogOption(
                                    onPressed: () {
                                      setModalState(() {
                                        selectedSort = sort;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Text(sort),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: widget.project == null ? _buildAppBar(context) : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              context.read<SiteDiaryBloc>().add(
                LoadSiteDiaries(isRefresh: true, project: widget.project),
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: sizeContextOf(context, 16),
                right: sizeContextOf(context, 16),
                top: sizeContextOf(context, 0),
                bottom: sizeContextOf(context, 80), // space for floating bottom button
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(),
                  SizedBox(height: sizeContextOf(context, 16)),
                  _buildSortChips(),
                  SizedBox(height: sizeContextOf(context, 16)),
                  _buildDiaryList(),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF4F8F6),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: EdgeInsets.only(left: sizeContextOf(context, 12.0), top: sizeContextOf(context, 8.0), bottom: sizeContextOf(context, 8.0)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: const Text(
        'Site Diaries',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        FilterIconButton(
          onTap: () => _showFilterBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return BlocBuilder<SiteDiaryBloc, SiteDiaryState>(
      builder: (context, state) {
        int totalDiaries = state.diaries.length;
        int activeSubmitted = state.diaries
            .where(
              (d) => d.status == 'Submitted' || d.status == 'Approved by PM',
            )
            .length;
        int draftDiaries = state.diaries
            .where((d) => d.status == 'Draft')
            .length;

        if (state.status == SiteDiaryStatus.loading && state.diaries.isEmpty) {
          totalDiaries = 0;
          activeSubmitted = 0;
          draftDiaries = 0;
        }

        return Container(
          padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Total Diaries',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    SizedBox(height: sizeContextOf(context, 4)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$totalDiaries',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              Expanded(
                child: Column(
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Submitted / PM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    SizedBox(height: sizeContextOf(context, 4)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$activeSubmitted',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A8B5F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              Expanded(
                child: Column(
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Drafts',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    SizedBox(height: sizeContextOf(context, 4)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$draftDiaries',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortChips() {
    return SortChips(
      sortBy: _sortBy,
      options: const [
        SortOption(label: 'Date', field: 'date'),
        SortOption(label: 'ID', field: 'id'),
      ],
      onSortChanged: (newSort) {
        setState(() {
          _sortBy = newSort;
        });
      },
    );
  }

  Widget _buildDiaryList() {
    return BlocBuilder<SiteDiaryBloc, SiteDiaryState>(
      builder: (context, state) {
        if (state.status == SiteDiaryStatus.loading && state.diaries.isEmpty) {
          return _buildLoadingSkeleton();
        }

        if (state.status == SiteDiaryStatus.failure && state.diaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                Text(
                  state.errorMessage ?? 'Error loading diaries',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                ElevatedButton(
                  onPressed: () => context.read<SiteDiaryBloc>().add(
                    LoadSiteDiaries(isRefresh: true, project: widget.project),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.diaries.isEmpty) {
          return  Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 32.0)),
              child: Text('No site diaries found'),
            ),
          );
        }

        final diaries = List<SiteDiary>.from(state.diaries);
        diaries.sort((a, b) {
          switch (_sortBy) {
            case 'date_desc':
              if (a.siteDate == null && b.siteDate == null) return 0;
              if (a.siteDate == null) return 1;
              if (b.siteDate == null) return -1;
              return b.siteDate!.compareTo(a.siteDate!);
            case 'date_asc':
              if (a.siteDate == null && b.siteDate == null) return 0;
              if (a.siteDate == null) return 1;
              if (b.siteDate == null) return -1;
              return a.siteDate!.compareTo(b.siteDate!);
            case 'id_desc':
              return b.name.compareTo(a.name);
            case 'id_asc':
              return a.name.compareTo(b.name);
            default:
              return 0;
          }
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.hasReachedMax ? diaries.length : diaries.length + 1,
          separatorBuilder: (context, index) => SizedBox(height: sizeContextOf(context, 12)),
          itemBuilder: (context, index) {
            if (index >= diaries.length) {
              return  Center(
                child: Padding(
                  padding: EdgeInsets.all(sizeContextOf(context, 8)),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _SiteDiaryCard(
              diary: diaries[index],
              project: widget.project,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: sizeContextOf(context, 16)),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Positioned(
      bottom: sizeContextOf(context, 24),
      left: sizeContextOf(context, 16),
      right: sizeContextOf(context, 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SiteDiaryFormPage(project: widget.project),
            ),
          );

          if (result == true && context.mounted) {
            context.read<SiteDiaryBloc>().add(
              LoadSiteDiaries(isRefresh: true, project: widget.project),
            );
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sizeContextOf(context, 16)),
          decoration: BoxDecoration(
            color: AppColors.primaryButton,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '+ Create Site Diary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _SiteDiaryCard extends StatelessWidget {
  final SiteDiary diary;
  final String? project;

  const _SiteDiaryCard({required this.diary, this.project});

  @override
  Widget build(BuildContext context) {
    double percentageBilled = 0.0;
    if (diary.status == 'Draft') {
      percentageBilled = 0.25;
    } else if (diary.status == 'Submitted') {
      percentageBilled = 0.50;
    } else if (diary.status == 'Approved by PM') {
      percentageBilled = 0.75;
    } else if (diary.status == 'Acknowledged by Consultant') {
      percentageBilled = 1.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SiteDiaryDetailPage(diaryName: diary.name),
              ),
            );

            if (result == true && context.mounted) {
              context.read<SiteDiaryBloc>().add(
                LoadSiteDiaries(isRefresh: true, project: project),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.all(sizeContextOf(context, 12.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      diary.project ?? 'No Project', // Check if it exists first
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    StatusBadge(status: diary.status),
                  ],
                ),
                SizedBox(height: sizeContextOf(context, 6)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diary.name ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: sizeContextOf(context, 4)),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: sizeContextOf(context, 4)),
                              Text(
                                diary.siteDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(diary.siteDate!)
                                    : '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (diary.weatherAm != null ||
                                  diary.weatherPm != null) ...[
                                SizedBox(width: sizeContextOf(context, 12)),
                                Icon(
                                  Icons.wb_sunny_outlined,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: sizeContextOf(context, 4)),
                                Text(
                                  '${diary.weatherAm ?? '-'} / ${diary.weatherPm ?? '-'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sizeContextOf(context, 10)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentageBilled,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A8B5F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

