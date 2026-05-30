import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../bloc/stock_entry_bloc.dart';
import '../bloc/stock_entry_event.dart';
import '../bloc/stock_entry_state.dart';
import '../pages/material_transfer_detail_page.dart';
import '../../domain/entities/stock_entry.dart';

import '../pages/material_transfer_form_page.dart';

class MaterialTransferListView extends StatefulWidget {
  final String? project;
  const MaterialTransferListView({super.key, this.project});

  @override
  State<MaterialTransferListView> createState() =>
      _MaterialTransferListViewState();
}

class _MaterialTransferListViewState extends State<MaterialTransferListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<StockEntryBloc>().add(
      LoadStockEntries(
        isRefresh: true,
        stockEntryType: 'Material Transfer',
        project: widget.project,
      ),
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
      context.read<StockEntryBloc>().add(
        LoadStockEntries(
          stockEntryType: 'Material Transfer',
          project: widget.project,
        ),
      );
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
            child: BlocBuilder<StockEntryBloc, StockEntryState>(
              builder: (context, state) {
                if (state.listStatus == StockEntryStatus.loading &&
                    state.entries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.listStatus == StockEntryStatus.failure &&
                    state.entries.isEmpty) {
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
                            state.errorMessage ?? 'Failed to load material transfers',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSizes.s24),
                          ElevatedButton(
                            onPressed: () {
                              context.read<StockEntryBloc>().add(
                                LoadStockEntries(
                                  isRefresh: true,
                                  stockEntryType: 'Material Transfer',
                                  project: widget.project,
                                ),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final displayEntries = state.entries.where((entry) {
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch = entry.name.toLowerCase().contains(query) ||
                      entry.purpose.toLowerCase().contains(query) ||
                      (entry.fromWarehouse ?? '').toLowerCase().contains(query) ||
                      (entry.toWarehouse ?? '').toLowerCase().contains(query);
                  
                  final matchesStatus = _filterStatus == 'All' ||
                      entry.status.toLowerCase() == _filterStatus.toLowerCase();
                      
                  return matchesSearch && matchesStatus;
                }).toList();

                displayEntries.sort((a, b) {
                  switch (_sortBy) {
                    case 'date_desc':
                      if (a.postingDate == null && b.postingDate == null) return 0;
                      if (a.postingDate == null) return 1;
                      if (b.postingDate == null) return -1;
                      return b.postingDate!.compareTo(a.postingDate!);
                    case 'date_asc':
                      if (a.postingDate == null && b.postingDate == null) return 0;
                      if (a.postingDate == null) return 1;
                      if (b.postingDate == null) return -1;
                      return a.postingDate!.compareTo(b.postingDate!);
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

                if (displayEntries.isEmpty) {
                  return const Center(child: Text('No material transfers found'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<StockEntryBloc>().add(
                      LoadStockEntries(
                        isRefresh: true,
                        stockEntryType: 'Material Transfer',
                        project: widget.project,
                      ),
                    );
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSizes.s16),
                    itemCount: state.hasReachedMax
                        ? displayEntries.length
                        : displayEntries.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.s12),
                    itemBuilder: (context, index) {
                      if (index >= displayEntries.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizes.s8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final entry = displayEntries[index];
                      return _MaterialTransferCard(entry: entry);
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
              builder: (context) => const MaterialTransferFormPage(
                stockEntryType: 'Material Transfer',
              ),
            ),
          );

          if (result == true && context.mounted) {
            context.read<StockEntryBloc>().add(
              LoadStockEntries(
                isRefresh: true,
                stockEntryType: 'Material Transfer',
                project: widget.project,
              ),
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
              hintText: 'Search Transfer ID, Warehouses, Purpose...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.r8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      isExpanded: true,
                      items: ['All', 'Draft', 'Submitted', 'Cancelled'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _filterStatus = value;
                          });
                        }
                      },
                    ),
                  ),
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
}

class _MaterialTransferCard extends StatelessWidget {
  final StockEntry entry;

  const _MaterialTransferCard({required this.entry});

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
                  MaterialTransferDetailPage(entryName: entry.name),
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
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _StatusBadge(status: entry.status),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  Expanded(
                    child: _buildLocationInfo(
                      label: 'From',
                      location: entry.fromWarehouse ?? '-',
                      icon: Icons.outbox_outlined,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.s8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: _buildLocationInfo(
                      label: 'To',
                      location: entry.toWarehouse ?? '-',
                      icon: Icons.move_to_inbox_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s12),
              const Divider(height: 1, color: AppColors.outlineVariant),
              const SizedBox(height: AppSizes.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSizes.s4),
                      Text(
                        entry.postingDate != null
                            ? DateFormat(
                                'dd-MM-yyyy',
                              ).format(entry.postingDate!)
                            : '-',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (entry.purpose.isNotEmpty)
                    Text(
                      entry.purpose,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
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

  Widget _buildLocationInfo({
    required String label,
    required String location,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
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
      case 'submitted':
        color = AppColors.success;
        break;
      case 'draft':
        color = AppColors.warning;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
