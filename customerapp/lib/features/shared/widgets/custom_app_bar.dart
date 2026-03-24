import 'package:flutter/material.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            )
          : null,
      centerTitle: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading:
          leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                )
              : null),
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      bottom: bottom,
    );
  }
}
