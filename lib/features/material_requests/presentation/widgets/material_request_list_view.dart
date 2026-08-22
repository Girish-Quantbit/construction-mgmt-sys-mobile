import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/material_request_bloc.dart';
import '../bloc/material_request_event.dart';
import '../bloc/material_request_state.dart';
import '../pages/material_request_detail_page.dart';
import '../pages/material_request_form_page.dart';
import '../../domain/entities/material_request.dart';

import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sort_chips.dart';
import '../../../../core/widgets/filter_button.dart';

class MaterialRequestListView extends StatefulWidget {
  final String? project;
  const MaterialRequestListView({super.key, this.project});

  @override
  State<MaterialRequestListView> createState() =>
      _MaterialRequestListViewState();
}

class _MaterialRequestListViewState extends State<MaterialRequestListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<MaterialRequestBloc>().add(
      LoadMaterialRequests(project: widget.project),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<MaterialRequestBloc>().add(LoadMoreMaterialRequests());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showFilterBottomSheet(BuildContext context) {
    final bloc = context.read<MaterialRequestBloc>();
    final currentState = bloc.state;
    String? selectedStatus = currentState.filterStatus;
    DateTimeRange? selectedRequiredBy = currentState.requiredByDateRange;
    DateTimeRange? selectedTransaction = currentState.transactionDateRange;

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
              title: 'Filter Material Requests',
              onReset: () {
                bloc.add(const FilterChanged());
              },
              onApply: () {
                bloc.add(
                  FilterChanged(
                    status: selectedStatus,
                    requiredByDateRange: selectedRequiredBy,
                    transactionDateRange: selectedTransaction,
                  ),
                );
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
                                  'Cancelled',
                                  'Pending',
                                  'Partially Ordered',
                                  'Ordered',
                                  'Issued',
                                  'Transferred',
                                  'Received',
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
                FilterDateRangePicker(
                  title: 'Required By Date Range',
                  fromDate: selectedRequiredBy?.start,
                  toDate: selectedRequiredBy?.end,
                  onRangeSelected: (range) {
                    setModalState(() {
                      selectedRequiredBy = range;
                    });
                  },
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                FilterDateRangePicker(
                  title: 'Transaction Date Range',
                  fromDate: selectedTransaction?.start,
                  toDate: selectedTransaction?.end,
                  onRangeSelected: (range) {
                    setModalState(() {
                      selectedTransaction = range;
                    });
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
      appBar: _buildAppBar(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              context.read<MaterialRequestBloc>().add(
                LoadMaterialRequests(isRefresh: true, project: widget.project),
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: sizeContextOf(context, 16),
                right: sizeContextOf(context, 16),
                top: sizeContextOf(context, 0),
                bottom: sizeContextOf(context, 80),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // _buildSummaryCard(),
                  // SizedBox(height: sizeContextOf(context, 16)),
                  _buildSortChips(),
                  SizedBox(height: sizeContextOf(context, 16)),
                  _buildRequestList(),
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
        'Material Requests',
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
    return BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
      builder: (context, state) {
        int totalRequests = state.requests.length;
        int pending = state.requests
            .where(
              (r) =>
                  r.status.toLowerCase() == 'pending' ||
                  r.status.toLowerCase() == 'draft' ||
                  r.status.toLowerCase() == 'partially ordered',
            )
            .length;

        int issuedCount = state.requests
            .where((r) => r.status.toLowerCase() == 'issued')
            .length;

        if (state.status == MaterialRequestStatus.loading &&
            state.requests.isEmpty) {
          totalRequests = 0;
          pending = 0;
          issuedCount = 0;
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 4.0)),
                  child: Column(
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Total Requests',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 8)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$totalRequests',
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
              ),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 4.0)),
                  child: Column(
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 8)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$pending',
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
              ),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizeContextOf(context, 4.0)),
                  child: Column(
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Issued',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 8)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$issuedCount',
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
        SortOption(label: 'Status', field: 'status'),
        SortOption(label: 'ID', field: 'id'),
      ],
      onSortChanged: (newSort) {
        setState(() {
          _sortBy = newSort;
        });
      },
    );
  }

  Widget _buildRequestList() {
    return BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
      builder: (context, state) {
        if (state.status == MaterialRequestStatus.loading &&
            state.requests.isEmpty) {
          return _buildLoadingSkeleton();
        }

        if (state.status == MaterialRequestStatus.failure &&
            state.requests.isEmpty) {
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
                Text(
                  state.errorMessage ?? 'Error loading requests',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s16),
                ElevatedButton(
                  onPressed: () => context.read<MaterialRequestBloc>().add(
                    LoadMaterialRequests(
                      isRefresh: true,
                      project: widget.project,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.requests.isEmpty) {
          return const Center(child: Text('No material requests found'));
        }

        final requests = List<MaterialRequest>.from(state.requests);

        requests.sort((a, b) {
          switch (_sortBy) {
            case 'date_desc':
              if (a.transactionDate == null && b.transactionDate == null) {
                return 0;
              }
              if (a.transactionDate == null) return 1;
              if (b.transactionDate == null) return -1;
              return b.transactionDate!.compareTo(a.transactionDate!);
            case 'date_asc':
              if (a.transactionDate == null && b.transactionDate == null) {
                return 0;
              }
              if (a.transactionDate == null) return 1;
              if (b.transactionDate == null) return -1;
              return a.transactionDate!.compareTo(b.transactionDate!);
            case 'type_asc':
              return a.materialRequestType.compareTo(b.materialRequestType);
            case 'type_desc':
              return b.materialRequestType.compareTo(a.materialRequestType);
            case 'status_asc':
              return a.status.compareTo(b.status);
            case 'status_desc':
              return b.status.compareTo(a.status);
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
          itemCount: state.hasReachedMax
              ? requests.length
              : requests.length + 1,
          separatorBuilder: (context, index) => SizedBox(height: sizeContextOf(context, 16)),
          itemBuilder: (context, index) {
            if (index >= requests.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.s8),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _MaterialRequestCard(request: requests[index]);
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
          height: 160,
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
              builder: (context) => const MaterialRequestFormPage(),
            ),
          );

          if (result == true && context.mounted) {
            context.read<MaterialRequestBloc>().add(
              LoadMaterialRequests(isRefresh: true, project: widget.project),
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
            '+ Raise Material Request',
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

class _MaterialRequestCard extends StatelessWidget {
  final MaterialRequest request;

  const _MaterialRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    double percentageOrdered = 0.0;
    if (request.status.toLowerCase() == 'submitted' ||
        request.status.toLowerCase() == 'ordered' ||
        request.status.toLowerCase() == 'received' ||
        request.status.toLowerCase() == 'issued' ||
        request.status.toLowerCase() == 'transferred') {
      percentageOrdered = 1.0;
    } else if (request.status.toLowerCase() == 'partially ordered') {
      percentageOrdered = 0.5;
    } else if (request.status.toLowerCase() == 'draft') {
      percentageOrdered = 0.0;
    }

    if (request.perOrdered != null) {
      percentageOrdered = request.perOrdered! / 100.0;
    }

    double totalQty = 0;
    if (request.items.isNotEmpty) {
      totalQty = request.items.fold(0.0, (sum, item) => sum + item.qty);
    } else if (request.rawData.containsKey('total_qty')) {
      totalQty = (request.rawData['total_qty'] as num).toDouble();
    }
    String qtyText = totalQty > 0
        ? '${totalQty.toStringAsFixed(0)} units'
        : '0 units';

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MaterialRequestDetailPage(requestName: request.name),
              ),
            );
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
                      request.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    StatusBadge(status: request.status),
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
                            (request.title != null && request.title!.isNotEmpty)
                                ? request.title!
                                : request.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                                request.transactionDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(request.transactionDate!)
                                    : 'Oct 24, 2023',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(width: sizeContextOf(context, 12)),
                              Text(
                                qtyText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: sizeContextOf(context, 12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          request.materialRequestType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 2)),
                        Text(
                          'Ordered ${(percentageOrdered * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: sizeContextOf(context, 8)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentageOrdered,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
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

