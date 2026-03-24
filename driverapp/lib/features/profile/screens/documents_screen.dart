import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/profile/providers/profile_provider.dart';
import 'package:freshkart_delivery/features/shared/widgets/network_image_widget.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _reuploadDocument(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return;

    final success = await ref
        .read(profileProvider.notifier)
        .uploadDocument(type, image.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Document uploaded successfully'
                : 'Failed to upload document',
            style: GoogleFonts.notoSans(),
          ),
          backgroundColor: success
              ? DeliveryColors.online
              : DeliveryColors.newOrder,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final agent = state.agent;

    final documents = [
      _DocumentItem(
        name: 'Aadhaar Card',
        type: 'aadhaar',
        icon: Icons.credit_card_outlined,
        imageUrl: agent?.aadhaarDocUrl,
        isVerified: agent?.aadhaarDocUrl != null,
        isPending:
            agent?.aadhaarDocUrl != null && !(agent?.isApproved ?? false),
      ),
      _DocumentItem(
        name: 'Driving License',
        type: 'driving_license',
        icon: Icons.badge_outlined,
        imageUrl: null,
        isVerified: false,
        isPending: false,
        hasExpiryWarning: true,
      ),
      _DocumentItem(
        name: 'Vehicle RC',
        type: 'vehicle_rc',
        icon: Icons.description_outlined,
        imageUrl: agent?.vehicleDocUrl,
        isVerified: agent?.vehicleDocUrl != null,
        isPending:
            agent?.vehicleDocUrl != null && !(agent?.isApproved ?? false),
      ),
      _DocumentItem(
        name: 'Profile Photo',
        type: 'profile_photo',
        icon: Icons.account_circle_outlined,
        imageUrl: agent?.avatarUrl,
        isVerified: agent?.avatarUrl != null,
        isPending: false,
        isPhoto: true,
      ),
    ];

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'My Documents',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: DeliveryColors.surface,
        foregroundColor: DeliveryColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: state.isLoading && agent == null
          ? const Center(
              child: CircularProgressIndicator(color: DeliveryColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DeliveryColors.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DeliveryColors.primaryLight.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: DeliveryColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All documents must be verified for you to receive deliveries. Re-upload if any document is rejected.',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: DeliveryColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...documents.map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDocumentTile(doc, state.isLoading),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDocumentTile(_DocumentItem doc, bool isUploading) {
    return Container(
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doc.hasExpiryWarning && !doc.isVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: DeliveryColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driving license document not uploaded. Please upload to continue deliveries.',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: DeliveryColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: DeliveryColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: doc.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: NetworkImageWidget(
                            imageUrl: doc.imageUrl,
                            width: 56,
                            height: 56,
                            borderRadius: 12,
                            errorIcon: doc.icon,
                          ),
                        )
                      : Icon(
                          doc.icon,
                          size: 28,
                          color: DeliveryColors.textSecondary,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: DeliveryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(doc),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: isUploading
                        ? null
                        : () => _reuploadDocument(doc.type),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DeliveryColors.primary,
                      side: const BorderSide(
                        color: DeliveryColors.primaryLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Re-upload'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(_DocumentItem doc) {
    if (doc.isPhoto) {
      final isUploaded = doc.imageUrl != null;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isUploaded
              ? DeliveryColors.online.withOpacity(0.1)
              : DeliveryColors.textSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isUploaded ? '\u2705 Uploaded' : 'Not uploaded',
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isUploaded
                ? DeliveryColors.online
                : DeliveryColors.textSecondary,
          ),
        ),
      );
    }

    if (doc.isVerified && !doc.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: DeliveryColors.online.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '\u2705 Verified',
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: DeliveryColors.online,
          ),
        ),
      );
    }

    if (doc.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: DeliveryColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '\u23F3 Pending Verification',
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: DeliveryColors.warning,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DeliveryColors.newOrder.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Not uploaded',
        style: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: DeliveryColors.newOrder,
        ),
      ),
    );
  }
}

class _DocumentItem {
  final String name;
  final String type;
  final IconData icon;
  final String? imageUrl;
  final bool isVerified;
  final bool isPending;
  final bool hasExpiryWarning;
  final bool isPhoto;

  const _DocumentItem({
    required this.name,
    required this.type,
    required this.icon,
    this.imageUrl,
    this.isVerified = false,
    this.isPending = false,
    this.hasExpiryWarning = false,
    this.isPhoto = false,
  });
}
