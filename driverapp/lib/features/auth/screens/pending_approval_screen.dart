import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/config/supabase_config.dart';
import 'package:freshkart_delivery/core/storage/local_storage.dart';
import 'package:freshkart_delivery/features/auth/providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _subscribeToAgentChanges();
  }

  void _subscribeToAgentChanges() {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = SupabaseConfig.client
        .channel('agent-approval-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'agents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final isApproved = newRecord['is_approved'] as bool? ?? false;

            if (isApproved && mounted) {
              // Agent approved - save data and navigate to home
              final agentId = newRecord['id'] as String? ?? '';
              final agentName = newRecord['full_name'] as String? ?? '';
              final vehicleType = newRecord['vehicle_type'] as String? ?? '';

              LocalStorage.setAgentId(agentId);
              LocalStorage.setAgentName(agentName);
              LocalStorage.setVehicleType(vehicleType);

              context.go('/home');
            }
          },
        )
        .subscribe();
  }

  Future<void> _onLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeliveryColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Rocket icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: DeliveryColors.primaryBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DeliveryColors.primaryLight.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Text('\u{1F680}', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Application Submitted!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'re verifying your documents',
                style: TextStyle(
                  fontSize: 16,
                  color: DeliveryColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Typically takes 24 hours',
                style: TextStyle(
                  fontSize: 14,
                  color: DeliveryColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Checklist card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildChecklistItem(
                      icon: Icons.check_circle,
                      iconColor: DeliveryColors.stepDone,
                      label: 'Application submitted',
                      isCompleted: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            color: DeliveryColors.divider,
                            thickness: 2,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    _buildChecklistItem(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: DeliveryColors.warning,
                      label: 'Document verification',
                      isCompleted: false,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            color: DeliveryColors.divider,
                            thickness: 2,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    _buildChecklistItem(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: DeliveryColors.stepPending,
                      label: 'Background check',
                      isCompleted: false,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            color: DeliveryColors.divider,
                            thickness: 2,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    _buildChecklistItem(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: DeliveryColors.stepPending,
                      label: 'Account activation',
                      isCompleted: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Earnings teaser
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      DeliveryColors.primaryDark,
                      DeliveryColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.currency_rupee_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expected earnings',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '\u20B9500\u2013800/day on bike',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DeliveryColors.textSecondary,
                    side: const BorderSide(color: DeliveryColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted
                  ? DeliveryColors.textPrimary
                  : DeliveryColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
