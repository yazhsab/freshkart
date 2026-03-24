import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final double? height;
  final double? width;
  final double radius;

  const ShimmerLoader({super.key, this.height, this.width, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: VendorColors.shimmerBase,
      highlightColor: VendorColors.shimmerHighlight,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: VendorColors.shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
