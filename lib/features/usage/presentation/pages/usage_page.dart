import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/manpower_usage_bloc.dart';
import '../bloc/equipment_usage_bloc.dart';
import '../widgets/manpower_usage_list_view.dart';
import '../widgets/equipment_usage_list_view.dart';
import '../../../material_requests/presentation/bloc/material_request_bloc.dart';
import '../../../material_requests/presentation/widgets/material_request_list_view.dart';

class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(
          title: 'Usage',
          bottom: TabBar(
            tabs: [
              Tab(text: 'Manpower'),
              Tab(text: 'Equipment'),
              Tab(text: 'Material Request'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (context) => sl<ManpowerUsageBloc>(),
              child: const ManpowerUsageListView(),
            ),
            BlocProvider(
              create: (context) => sl<EquipmentUsageBloc>(),
              child: const EquipmentUsageListView(),
            ),
            BlocProvider(
              create: (context) => sl<MaterialRequestBloc>(),
              child: const MaterialRequestListView(),
            ),
          ],
        ),
      ),
    );
  }
}
