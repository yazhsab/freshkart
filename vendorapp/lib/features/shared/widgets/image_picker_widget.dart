import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? currentImageUrl;
  final ValueChanged<File> onImagePicked;
  final double height;
  final String placeholderText;

  const ImagePickerWidget({
    super.key,
    this.currentImageUrl,
    required this.onImagePicked,
    this.height = 200,
    this.placeholderText = 'Tap to add image',
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _pickedFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (xFile != null) {
      final file = File(xFile.path);
      setState(() => _pickedFile = file);
      widget.onImagePicked(file);
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: VendorColors.primary,
                ),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: VendorColors.primary,
                ),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return CustomPaint(
      painter: _DashedBorderPainter(color: VendorColors.disabled),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              size: 40,
              color: VendorColors.disabled,
            ),
            const SizedBox(height: 8),
            Text(
              widget.placeholderText,
              style: const TextStyle(
                color: VendorColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_pickedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _pickedFile!,
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.currentImageUrl!,
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _showPickerSheet, child: _buildImage());
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(rRect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}
