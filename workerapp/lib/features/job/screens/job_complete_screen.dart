import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/features/bookings/providers/bookings_provider.dart';
import 'package:freshkart_worker/features/bookings/widgets/payment_collection_widget.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';

final _bookingCompleteProvider = FutureProvider.family<BookingModel?, String>((
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

class JobCompleteScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const JobCompleteScreen({super.key, required this.bookingId});

  @override
  ConsumerState<JobCompleteScreen> createState() => _JobCompleteScreenState();
}

class _JobCompleteScreenState extends ConsumerState<JobCompleteScreen> {
  bool _paymentCollected = false;
  bool _isSubmitting = false;
  List<Offset> _signaturePoints = [];
  String? _signatureBase64;

  void _clearSignature() {
    setState(() {
      _signaturePoints = [];
      _signatureBase64 = null;
    });
  }

  Future<void> _submitCompletion() async {
    if (!_paymentCollected) {
      context.showSnackBar('Please collect payment first', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? signatureUrl;
      if (_signatureBase64 != null) {
        final bytes = base64Decode(_signatureBase64!);
        final path = 'signatures/${widget.bookingId}.png';
        await Supabase.instance.client.storage
            .from('signatures')
            .uploadBinary(path, Uint8List.fromList(bytes));
        signatureUrl = Supabase.instance.client.storage
            .from('signatures')
            .getPublicUrl(path);
      }

      await ref.read(bookingsProvider.notifier).completeBooking(
        widget.bookingId,
        {'payment_status': 'paid', 'signature_url': signatureUrl},
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Job Completed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'வேலை வெற்றிகரமாக முடிந்தது!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Back to Home',
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(_bookingCompleteProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Job')),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (booking) {
          if (booking == null) return const Center(child: Text('Not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PaymentCollectionWidget(
                amount: booking.displayAmount,
                paymentMethod: booking.paymentMethod,
                isCollected: _paymentCollected,
                onCollected: () => setState(() => _paymentCollected = true),
              ),
              const SizedBox(height: 24),
              const Text(
                'Customer Signature',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() => _signaturePoints.add(details.localPosition));
                  },
                  onPanEnd: (_) {
                    setState(() => _signaturePoints.add(Offset.infinite));
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(_signaturePoints),
                    size: Size.infinite,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Submit & Complete',
                icon: Icons.check_circle,
                onPressed: _submitCompletion,
                isLoading: _isSubmitting,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
