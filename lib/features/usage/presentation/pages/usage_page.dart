import 'package:cms/core/theme/app_sizes.dart';
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
import '../../../../core/services/project_selection_service.dart';

class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final activeProject = sl<ProjectSelectionService>().selectedProject;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: const CustomAppBar(title: 'Usage Modules'),
      body: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: sizeContextOf(context, 8)),
            _buildModuleCard(
              context: context,
              icon: Icons.people_outline,
              title: 'Manpower Usage',
              subtitle: 'Subcontractor daily logs & wage tracking',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => sl<ManpowerUsageBloc>(),
                    child: ManpowerUsageListView(project: activeProject),
                  ),
                ),
              ),
            ),
            SizedBox(height: sizeContextOf(context, 16)),
            _buildModuleCard(
              context: context,
              icon: Icons.handyman_outlined,
              title: 'Equipment Usage',
              subtitle: 'Machinery run-time, fuel & cost tracking',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => sl<EquipmentUsageBloc>(),
                    child: EquipmentUsageListView(project: activeProject),
                  ),
                ),
              ),
            ),
            SizedBox(height: sizeContextOf(context, 16)),
            _buildModuleCard(
              context: context,
              icon: Icons.shopping_cart_outlined,
              title: 'Material Requests',
              subtitle: 'Structural site demands & material requests',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => sl<MaterialRequestBloc>(),
                    child: MaterialRequestListView(project: activeProject),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizeContextOf(context, 20),
              vertical: sizeContextOf(context, 24),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(sizeContextOf(context, 14)),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                SizedBox(width: sizeContextOf(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 4)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
