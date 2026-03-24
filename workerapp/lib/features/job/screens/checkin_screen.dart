import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/features/bookings/providers/bookings_provider.dart';
import 'package:freshkart_worker/features/bookings/widgets/checkin_otp_widget.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const CheckinScreen({super.key, required this.bookingId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndCheckin(String otp) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(bookingsProvider.notifier).checkin(widget.bookingId, otp);
      if (mounted) {
        context.showSnackBar('Checked in successfully!');
        context.pushReplacement('/job-in-progress/${widget.bookingId}');
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WorkerColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: WorkerColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Check-in OTP',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the customer for the 4-digit OTP\nவாடிக்கையாளரிடம் OTP கேளுங்கள்',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CheckinOtpWidget(
              controller: _otpController,
              onCompleted: _verifyAndCheckin,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Verify & Check In',
              onPressed: () => _verifyAndCheckin(_otpController.text),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Steps:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _step('1', 'Arrive at customer location'),
                  _step('2', 'Greet the customer'),
                  _step('3', 'Ask for the OTP shown in their app'),
                  _step('4', 'Enter it above to start the job'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: WorkerColors.primary,
            child: Text(
              num,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
