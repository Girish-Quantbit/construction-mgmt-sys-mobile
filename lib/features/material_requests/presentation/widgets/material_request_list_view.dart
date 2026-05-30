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
    context.read<MaterialRequestBloc>().add(LoadMaterialRequests(project: widget.project));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
              builder: (context, state) {
                if (state.status == MaterialRequestStatus.loading &&
                    state.requests.isEmpty) {
                  return _buildLoadingSkeleton();
                }

                if (state.status == MaterialRequestStatus.failure &&
                    state.requests.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.s24),
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
                            onPressed: () =>
                                context.read<MaterialRequestBloc>().add(
                                  LoadMaterialRequests(isRefresh: true, project: widget.project),
                                ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.requests.isEmpty) {
                  return const Center(
                    child: Text('No material requests found'),
                  );
                }

                final requests = List<MaterialRequest>.from(state.requests);
                requests.sort((a, b) {
                  switch (_sortBy) {
                    case 'date_desc':
                      if (a.transactionDate == null && b.transactionDate == null) return 0;
                      if (a.transactionDate == null) return 1;
                      if (b.transactionDate == null) return -1;
                      return b.transactionDate!.compareTo(a.transactionDate!);
                    case 'date_asc':
                      if (a.transactionDate == null && b.transactionDate == null) return 0;
                      if (a.transactionDate == null) return 1;
                      if (b.transactionDate == null) return -1;
                      return a.transactionDate!.compareTo(b.transactionDate!);
                    case 'type_asc':
                      return a.materialRequestType.compareTo(b.materialRequestType);
                    case 'status_asc':
                      return a.status.compareTo(b.status);
                    case 'id_desc':
                      return b.name.compareTo(a.name);
                    case 'id_asc':
                      return a.name.compareTo(b.name);
                    default:
                      return 0;
                  }
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<MaterialRequestBloc>().add(
                      LoadMaterialRequests(isRefresh: true, project: widget.project),
                    );
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSizes.s16),
                    itemCount: state.hasReachedMax
                        ? requests.length
                        : requests.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.s12),
                    itemBuilder: (context, index) {
                      if (index >= requests.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizes.s8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final request = requests[index];
                      return _MaterialRequestCard(request: request);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Request ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s12,
              ),
            ),
            onChanged: (value) {
              context.read<MaterialRequestBloc>().add(SearchChanged(value));
            },
          ),
          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<MaterialRequestBloc, MaterialRequestState>(
                  builder: (context, state) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.r8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.filterStatus,
                          hint: const Text('All Status'),
                          isExpanded: true,
                          items:
                              [
                                'Draft',
                                'Submitted',
                                'Cancelled',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (value) {
                            context.read<MaterialRequestBloc>().add(
                              FilterChanged(value),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.r8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Newest Date')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Oldest Date')),
                        DropdownMenuItem(value: 'type_asc', child: Text('Sort by Type')),
                        DropdownMenuItem(value: 'status_asc', child: Text('Sort by Status')),
                        DropdownMenuItem(value: 'id_desc', child: Text('ID (Z-A)')),
                        DropdownMenuItem(value: 'id_asc', child: Text('ID (A-Z)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(AppSizes.s16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.s12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSizes.r12),
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
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.r12),
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
          padding: const EdgeInsets.all(AppSizes.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      (request.title != null && request.title!.isNotEmpty)
                          ? request.title!
                          : request.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: AppSizes.s8),
              if (request.title != null &&
                  request.title!.isNotEmpty &&
                  request.title != request.name) ...[
                Text(
                  request.name,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.merge_type_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: Text(
                      'Type: ${request.materialRequestType}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Text(
                    request.transactionDate != null
                        ? DateFormat('MMM dd, yyyy').format(request.transactionDate!)
                        : '-',
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'submitted':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      case 'stopped':
        color = Colors.blueGrey;
        break;
      case 'partially ordered':
        color = Colors.purple;
        break;
      case 'ordered':
        color = Colors.teal;
        break;
      case 'issued':
        color = Colors.lightBlue;
        break;
      case 'transferred':
      case 'received':
        color = AppColors.success;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8,
        vertical: AppSizes.s4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
