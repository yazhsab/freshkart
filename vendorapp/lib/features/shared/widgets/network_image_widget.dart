import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class NetworkImageWidget extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  const NetworkImageWidget({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 8,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: VendorColors.shimmerBase,
          highlightColor: VendorColors.shimmerHighlight,
          child: Container(
            width: width,
            height: height,
            color: VendorColors.shimmerBase,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(
            Icons.broken_image_rounded,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }
}
