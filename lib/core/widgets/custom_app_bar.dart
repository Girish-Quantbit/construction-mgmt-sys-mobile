import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final VoidBinding? onMenuPressed;
  final VoidBinding? onSearchPressed;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title = 'BuildX',
    this.showSearch = true,
    this.onMenuPressed,
    this.onSearchPressed,
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    ModalRoute.of(context)?.canPop == true
                        ? Icons.arrow_back
                        : Icons.menu,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed:
                      onMenuPressed ??
                      () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else if (Scaffold.maybeOf(context)?.hasDrawer ??
                            false) {
                          Scaffold.of(context).openDrawer();
                        }
                      },
                  style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actions != null) ...actions!,
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outlineVariant,
                      width: 1,
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));
}

typedef VoidBinding = void Function();
