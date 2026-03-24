import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class NetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final IconData errorIcon;
  final double errorIconSize;
  final Color? errorIconColor;
  final Color? backgroundColor;

  const NetworkImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.errorIconSize = 32,
    this.errorIconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: DeliveryColors.divider,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: DeliveryColors.divider,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? DeliveryColors.background,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          errorIcon,
          size: errorIconSize,
          color:
              errorIconColor ?? DeliveryColors.textSecondary.withOpacity(0.4),
        ),
      ),
    );
  }
}
