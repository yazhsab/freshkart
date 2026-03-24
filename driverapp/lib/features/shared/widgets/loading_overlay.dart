import 'package:flutter/material.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? overlayColor;
  final Color? progressColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.overlayColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: AnimatedOpacity(
                opacity: isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: overlayColor ?? Colors.black.withOpacity(0.3),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DeliveryColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor ?? DeliveryColors.primary,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
