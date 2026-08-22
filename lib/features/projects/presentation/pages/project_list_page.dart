import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/features/purchase_receipts/presentation/bloc/purchase_receipt_bloc.dart';
import 'package:cms/features/purchase_receipts/presentation/widgets/purchase_receipt_list_view.dart';
import 'package:cms/features/stock_entry/presentation/bloc/stock_entry_bloc.dart';
import 'package:cms/features/stock_entry/presentation/widgets/material_transfer_list_view.dart';
import 'package:cms/features/stock_entry/presentation/widgets/material_issue_list_view.dart';
import 'package:cms/features/site_diary/presentation/bloc/site_diary_bloc.dart';
import 'package:cms/features/site_diary/presentation/widgets/site_diary_list_view.dart';
import 'package:cms/features/projects/domain/entities/project.dart';

class ProjectListPage extends StatelessWidget {
  final Project project;

  const ProjectListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ProjectListPage');
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: project.projectName,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            tabs: [
              Tab(text: 'Purchase Receipt'),
              Tab(text: 'Material Issue'),
              Tab(text: 'Stock Entry'),
              Tab(text: 'Material Transfer'),
              Tab(text: 'Site Diary'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (context) => sl<PurchaseReceiptBloc>(),
              child: PurchaseReceiptListView(project: project.name),
            ),
            BlocProvider(
              create: (context) => sl<StockEntryBloc>(),
              child: MaterialIssueListView(
                stockEntryType: 'Material Issue',
                project: project.name,
              ),
            ),
            BlocProvider(
              create: (context) => sl<StockEntryBloc>(),
              child: MaterialIssueListView(project: project.name),
            ),
            BlocProvider(
              create: (context) => sl<StockEntryBloc>(),
              child: MaterialTransferListView(project: project.name),
            ),
            BlocProvider(
              create: (context) => sl<SiteDiaryBloc>(),
              child: SiteDiaryListView(project: project.name),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  final String title;
  const _TabPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: sizeContextOf(context, 16)),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
