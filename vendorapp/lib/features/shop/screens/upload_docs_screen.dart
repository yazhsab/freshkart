import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/features/shop/providers/shop_provider.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';

class UploadDocsScreen extends ConsumerStatefulWidget {
  const UploadDocsScreen({super.key});

  @override
  ConsumerState<UploadDocsScreen> createState() => _UploadDocsScreenState();
}

class _UploadDocsScreenState extends ConsumerState<UploadDocsScreen> {
  File? _fssaiFile;
  File? _gstinFile;
  File? _cancelledChequeFile;

  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<File?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<void> _uploadAll() async {
    if (_fssaiFile == null &&
        _gstinFile == null &&
        _cancelledChequeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one document to upload'),
          backgroundColor: VendorColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      // Simulate progress for user feedback
      setState(() => _uploadProgress = 0.3);

      await ref
          .read(shopProvider.notifier)
          .uploadDocs(
            fssaiFile: _fssaiFile,
            gstinFile: _gstinFile,
            cancelledChequeFile: _cancelledChequeFile,
          );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents uploaded successfully'),
            backgroundColor: VendorColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: VendorColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(shopProvider).valueOrNull;
    final hasFssai =
        vendor?.fssaiDocUrl != null && vendor!.fssaiDocUrl!.isNotEmpty;
    final hasGstin =
        vendor?.gstinDocUrl != null && vendor!.gstinDocUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Upload progress
          if (_isUploading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: VendorColors.primaryBg,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  VendorColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // --- FSSAI Certificate ---
          _buildDocSection(
            title: 'FSSAI Certificate',
            subtitle: 'Food Safety and Standards Authority of India license',
            isRequired: true,
            isUploaded: hasFssai,
            currentFile: _fssaiFile,
            onPick: () async {
              final file = await _pickFile();
              if (file != null) setState(() => _fssaiFile = file);
            },
            onRemove: () => setState(() => _fssaiFile = null),
          ),

          const SizedBox(height: 16),

          // --- GSTIN Certificate ---
          _buildDocSection(
            title: 'GSTIN Certificate',
            subtitle: 'GST Identification Number certificate',
            isRequired: false,
            isUploaded: hasGstin,
            currentFile: _gstinFile,
            onPick: () async {
              final file = await _pickFile();
              if (file != null) setState(() => _gstinFile = file);
            },
            onRemove: () => setState(() => _gstinFile = null),
          ),

          const SizedBox(height: 16),

          // --- Bank Cancelled Cheque ---
          _buildDocSection(
            title: 'Bank Cancelled Cheque',
            subtitle: 'Cancelled cheque or bank passbook front page',
            isRequired: false,
            isUploaded: false,
            currentFile: _cancelledChequeFile,
            onPick: () async {
              final file = await _pickFile();
              if (file != null) setState(() => _cancelledChequeFile = file);
            },
            onRemove: () => setState(() => _cancelledChequeFile = null),
          ),

          const SizedBox(height: 24),

          // Info note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VendorColors.primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: VendorColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Accepted formats: PDF, JPG, PNG. Maximum size: 5MB per file. Documents will be verified within 24 hours.',
                    style: TextStyle(
                      fontSize: 12,
                      color: VendorColors.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Upload button
          AppButton(
            label: 'Upload Documents',
            isLoading: _isUploading,
            icon: Icons.cloud_upload_rounded,
            onPressed: _isUploading ? null : _uploadAll,
          ),
        ],
      ),
    );
  }

  Widget _buildDocSection({
    required String title,
    required String subtitle,
    required bool isRequired,
    required bool isUploaded,
    required File? currentFile,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: VendorColors.textPrimary,
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: VendorColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: VendorColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: VendorColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status icon
              Icon(
                isUploaded
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
                color: isUploaded
                    ? VendorColors.inStock
                    : VendorColors.textHint,
                size: 28,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // File selection area
          if (currentFile != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VendorColors.primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: VendorColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentFile.path.split('/').last,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: VendorColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: VendorColors.textSecondary,
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: VendorColors.divider,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: VendorColors.primary.withValues(alpha: 0.6),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isUploaded ? 'Tap to re-upload' : 'Tap to select file',
                      style: TextStyle(
                        fontSize: 13,
                        color: VendorColors.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
