import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class NetworkImageWidget extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;
  final Widget? placeholder;

  const NetworkImageWidget({
    super.key,
    required this.url,
    required this.width,
    this.height = 0,
    this.radius = 8,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height > 0 ? height : width;

    if (url == null || url!.isEmpty) {
      return _buildErrorPlaceholder(effectiveHeight);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: effectiveHeight,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _buildShimmerPlaceholder(effectiveHeight),
        errorWidget: (context, url, error) =>
            _buildErrorPlaceholder(effectiveHeight),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(double h) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(double h) {
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textHint, size: 32),
      ),
    );
  }
}
