import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/models/service_category_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/features/bookings/providers/active_job_provider.dart';
import 'package:freshkart_worker/features/bookings/widgets/job_timer_widget.dart';
import 'package:freshkart_worker/features/bookings/widgets/job_checklist_widget.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/app_text_field.dart';

final _bookingProvider = FutureProvider.family<BookingModel?, String>((
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

class JobInProgressScreen extends ConsumerWidget {
  final String bookingId;
  const JobInProgressScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(_bookingProvider(bookingId));

    return bookingAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (booking) {
        if (booking == null)
          return const Scaffold(body: Center(child: Text('Not found')));
        final category = ServiceCategory.defaultCategories
            .where((c) => c.id == booking.serviceId)
            .firstOrNull;
        final checklist =
            category?.checklist ??
            ['Inspect', 'Fix', 'Clean up', 'Test', 'Done'];
        return _JobContent(booking: booking, checklist: checklist);
      },
    );
  }
}

class _JobContent extends ConsumerStatefulWidget {
  final BookingModel booking;
  final List<String> checklist;
  const _JobContent({required this.booking, required this.checklist});

  @override
  ConsumerState<_JobContent> createState() => _JobContentState();
}

class _JobContentState extends ConsumerState<_JobContent> {
  final _notesController = TextEditingController();
  final _chargesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _chargesController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(bool isBefore) async {
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
          'jobs/${widget.booking.id}/${isBefore ? 'before' : 'after'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('job-photos').upload(path, File(image.path));
      final url = supabase.storage.from('job-photos').getPublicUrl(path);

      final notifier = ref.read(
        activeJobProvider(widget.checklist.length).notifier,
      );
      if (isBefore) {
        notifier.addBeforePhoto(url);
      } else {
        notifier.addAfterPhoto(url);
      }
      if (mounted) context.showSnackBar('Photo uploaded');
    } catch (e) {
      if (mounted) context.showSnackBar('Upload failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(activeJobProvider(widget.checklist.length));
    final notifier = ref.read(
      activeJobProvider(widget.checklist.length).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.booking.serviceName ?? 'Job In Progress'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          JobTimerWidget(
            elapsed: jobState.elapsed,
            isOvertime: jobState.isOvertime,
          ),
          const SizedBox(height: 20),
          JobChecklistWidget(
            items: widget.checklist,
            checked: jobState.checklist,
            onToggle: notifier.toggleChecklistItem,
          ),
          const SizedBox(height: 20),
          const Text(
            'Before Photos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _PhotoRow(
            photos: jobState.beforePhotos,
            onAdd: () => _takePhoto(true),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Work Notes',
            hint: 'Describe the work done...',
            controller: _notesController,
            maxLines: 3,
            onChanged: notifier.updateNotes,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Additional Charges (₹)',
            hint: '0',
            controller: _chargesController,
            keyboardType: TextInputType.number,
            onChanged: (v) => notifier.updateAdditionalCharges(
              double.tryParse(v) ?? 0,
              'Materials',
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Complete Job',
            icon: Icons.check_circle,
            onPressed: () => context.push('/job-report/${widget.booking.id}'),
          ),
        ],
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAdd;
  const _PhotoRow({required this.photos, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...photos.map(
            (url) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: WorkerColors.primary,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: WorkerColors.primary.withValues(alpha: 0.05),
              ),
              child: const Icon(Icons.add_a_photo, color: WorkerColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
