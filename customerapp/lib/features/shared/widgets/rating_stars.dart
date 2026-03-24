import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.interactive = false,
    this.onRatingChanged,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (interactive) {
      return RatingBar.builder(
        initialRating: rating,
        minRating: 0.5,
        direction: Axis.horizontal,
        allowHalfRating: true,
        itemCount: 5,
        itemSize: size,
        unratedColor: AppColors.divider,
        itemBuilder: (context, _) =>
            const Icon(Icons.star_rounded, color: AppColors.primaryAmber),
        onRatingUpdate: (value) {
          onRatingChanged?.call(value);
        },
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starPosition = index + 1;
          IconData iconData;
          if (rating >= starPosition) {
            iconData = Icons.star_rounded;
          } else if (rating >= starPosition - 0.5) {
            iconData = Icons.star_half_rounded;
          } else {
            iconData = Icons.star_outline_rounded;
          }
          return Icon(
            iconData,
            size: size,
            color: rating > 0 ? AppColors.primaryAmber : AppColors.divider,
          );
        }),
        if (totalRatings > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
