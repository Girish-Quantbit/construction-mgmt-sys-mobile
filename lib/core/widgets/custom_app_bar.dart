import 'package:flutter/material.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/theme/app_sizes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showSearch;
  final VoidBinding? onMenuPressed;
  final VoidBinding? onSearchPressed;
  final VoidCallback? onTitleTap;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title = 'BuildX',
    this.subtitle,
    this.showSearch = true,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onTitleTap,
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bottomWidget = bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, AppSizes.s24),
      ),
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
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.all(
                      sizeContextOf(context, AppSizes.s8),
                    ),
                  ),
                ),
                SizedBox(width: sizeContextOf(context, AppSizes.s8)),
                Expanded(
                  child: GestureDetector(
                    onTap: onTitleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onTitleTap != null) ...[
                              SizedBox(
                                width: sizeContextOf(context, AppSizes.s4),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: sizeContextOf(context, 2),
                            ),
                            child: Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ...?actions,
                SizedBox(width: sizeContextOf(context, AppSizes.s8)),
                Container(
                  width: sizeContextOf(context, 40),
                  height: sizeContextOf(context, 40),
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
            ?bottomWidget,
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
