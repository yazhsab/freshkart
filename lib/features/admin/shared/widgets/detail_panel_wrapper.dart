import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class DetailPanelWrapper extends StatelessWidget {
  const DetailPanelWrapper({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return _buildFullScreen(context);
        }
        return _buildSidePanel(context);
      },
    );
  }

  Widget _buildSidePanel(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 440,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildFullScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onClose ?? () => Navigator.pop(context),
        ),
      ),
      body: child,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
