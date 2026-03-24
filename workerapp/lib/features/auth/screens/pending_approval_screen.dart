import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/storage/local_storage.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/status_badge.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  String _bgvStatus = 'pending';
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _listenForApproval();
  }

  void _listenForApproval() {
    final workerId = LocalStorage.workerId;
    if (workerId == null) return;

    _subscription = Supabase.instance.client
        .from('workers')
        .stream(primaryKey: ['id'])
        .eq('id', workerId)
        .listen((data) {
          if (data.isNotEmpty) {
            final status = data.first['bgv_status'] as String? ?? 'pending';
            setState(() => _bgvStatus = status);
            if (status == 'approved' && mounted) {
              context.go('/home');
            }
          }
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _bgvStatus == 'rejected';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                size: 80,
                color: isRejected ? Colors.red : WorkerColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                isRejected ? 'Verification Failed' : 'Verification In Progress',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              StatusBadge(status: _bgvStatus, isBgv: true),
              const SizedBox(height: 16),
              Text(
                isRejected
                    ? 'Your background verification was not successful. Please contact support for more details.'
                    : 'Your documents are being verified. This usually takes 24-48 hours. We\'ll notify you once approved.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!isRejected)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WorkerColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: WorkerColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: WorkerColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This page will automatically update when your verification is complete.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (isRejected)
                AppButton(
                  label: 'Contact Support',
                  icon: Icons.support_agent,
                  onPressed: () => context.push('/support'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
