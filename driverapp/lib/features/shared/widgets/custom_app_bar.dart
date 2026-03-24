import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Widget? leading;
  final bool centerTitle;
  final double? elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
    this.backgroundColor,
    this.leading,
    this.centerTitle = false,
    this.elevation,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    (subtitle != null ? 64.0 : kToolbarHeight) +
        (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: backgroundColor ?? DeliveryColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0.5,
      centerTitle: centerTitle,
      leading:
          leading ??
          (showBackButton && canPop
              ? IconButton(
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: DeliveryColors.textPrimary,
                    size: 20,
                  ),
                )
              : null),
      automaticallyImplyLeading: false,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
      actions: actions,
      bottom: bottom,
    );
  }
}
