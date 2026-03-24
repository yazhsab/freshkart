import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/app_text_field.dart';

final _bookingReportProvider = FutureProvider.family<BookingModel?, String>((
  ref,
  id,
) async {
  final data = await Supabase.instance.client
      .from('bookings')
      .select()
      .eq('id', id)
      .maybeSingle();
  return data != null ? BookingModel.fromJson(data) : null;
});

class JobReportScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const JobReportScreen({super.key, required this.bookingId});

  @override
  ConsumerState<JobReportScreen> createState() => _JobReportScreenState();
}

class _JobReportScreenState extends ConsumerState<JobReportScreen> {
  final _descController = TextEditingController();
  final _materialsController = TextEditingController();
  final List<String> _afterPhotos = [];
  final List<String> _materials = [];

  @override
  void dispose() {
    _descController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  Future<void> _takeAfterPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (image == null) return;
    try {
      final supabase = Supabase.instance.client;
      final path =
          'jobs/${widget.bookingId}/after_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('job-photos').upload(path, File(image.path));
      final url = supabase.storage.from('job-photos').getPublicUrl(path);
      setState(() => _afterPhotos.add(url));
    } catch (e) {
      if (mounted) context.showSnackBar('Upload failed', isError: true);
    }
  }

  void _addMaterial() {
    final text = _materialsController.text.trim();
    if (text.isEmpty) return;
    setState(() => _materials.add(text));
    _materialsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(_bookingReportProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Job Report')),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (booking) {
          if (booking == null) return const Center(child: Text('Not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'After Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._afterPhotos.map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _takeAfterPhoto,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: WorkerColors.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_a_photo,
                          color: WorkerColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Work Description (min 20 chars)',
                hint: 'Describe work performed...',
                controller: _descController,
                maxLines: 4,
                maxLength: 500,
                validator: (v) =>
                    (v == null || v.length < 20) ? 'Min 20 characters' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Materials Used',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _materialsController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. PVC pipe 1 inch',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: WorkerColors.primary,
                    ),
                    onPressed: _addMaterial,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _materials
                    .map(
                      (m) => Chip(
                        label: Text(m, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setState(() => _materials.remove(m)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _priceRow('Base Amount', booking.baseAmount),
                    if (booking.additionalCharges != null &&
                        booking.additionalCharges! > 0)
                      _priceRow('Additional', booking.additionalCharges!),
                    const Divider(),
                    _priceRow('Total', booking.displayAmount, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Proceed to Payment',
                icon: Icons.arrow_forward,
                onPressed: () {
                  if (_descController.text.length < 20) {
                    context.showSnackBar(
                      'Description must be at least 20 characters',
                      isError: true,
                    );
                    return;
                  }
                  context.push('/job-complete/${widget.bookingId}');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyUtil.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
