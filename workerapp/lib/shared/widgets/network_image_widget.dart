import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData placeholderIcon;

  const NetworkImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.placeholderIcon = Icons.image,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(placeholderIcon, color: Colors.grey.shade400, size: 32),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}
