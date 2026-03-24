import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerLoader({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.margin,
  });

  /// Creates a single shimmer line (useful for text placeholders).
  factory ShimmerLoader.line({
    Key? key,
    double width = double.infinity,
    double height = 14,
    double borderRadius = 6,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }

  /// Creates a circular shimmer (useful for avatar placeholders).
  factory ShimmerLoader.circle({Key? key, double size = 48}) {
    return ShimmerLoader(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Creates a default card-shaped shimmer placeholder.
  factory ShimmerLoader.card({
    Key? key,
    double? height,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoader(
      key: key,
      height: height ?? 120,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shimmerWidget = Shimmer.fromColors(
      baseColor: DeliveryColors.divider,
      highlightColor: Colors.white,
      child: child ?? _defaultChild(),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: shimmerWidget);
    }

    return shimmerWidget;
  }

  Widget _defaultChild() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 120,
      decoration: BoxDecoration(
        color: DeliveryColors.divider,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
