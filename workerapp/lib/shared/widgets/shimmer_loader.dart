import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget list({int count = 3, double itemHeight = 80}) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoader(height: itemHeight),
        ),
      ),
    );
  }
}
