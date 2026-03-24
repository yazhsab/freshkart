import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool? showBack;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBack ?? canPop;

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: VendorColors.textPrimary,
        ),
      ),
      centerTitle: false,
      backgroundColor: VendorColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: VendorColors.divider,
      automaticallyImplyLeading: false,
      leading: shouldShowBack
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: VendorColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }
}
