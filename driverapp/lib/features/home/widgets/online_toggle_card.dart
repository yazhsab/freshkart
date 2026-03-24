import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/features/home/providers/home_provider.dart';

class OnlineToggleCard extends ConsumerStatefulWidget {
  const OnlineToggleCard({super.key});

  @override
  ConsumerState<OnlineToggleCard> createState() => _OnlineToggleCardState();
}

class _OnlineToggleCardState extends ConsumerState<OnlineToggleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _onlineTimer;
  Duration _onlineDuration = Duration.zero;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _onlineTimer?.cancel();
    super.dispose();
  }

  void _startOnlineTimer(DateTime onlineSince) {
    _onlineTimer?.cancel();
    _onlineDuration = DateTime.now().difference(onlineSince);
    _onlineTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        setState(() {
          _onlineDuration = DateTime.now().difference(onlineSince);
        });
      }
    });
  }

  String _formatOnlineDuration() {
    final hours = _onlineDuration.inHours;
    final minutes = _onlineDuration.inMinutes.remainder(60);
    if (hours > 0) {
      return 'Online for $hours hrs $minutes mins';
    }
    return 'Online for $minutes mins';
  }

  Future<void> _handleToggle() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      await ref.read(homeProvider.notifier).toggleOnline();
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final isOnline = state.isOnline;
    final screenHeight = MediaQuery.of(context).size.height;

    // Manage pulse animation
    if (isOnline) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      if (state.onlineSince != null) {
        _onlineDuration = DateTime.now().difference(state.onlineSince!);
        if (_onlineTimer == null || !_onlineTimer!.isActive) {
          _startOnlineTimer(state.onlineSince!);
        }
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _onlineTimer?.cancel();
      _onlineTimer = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: screenHeight * 0.20,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isOnline ? DeliveryColors.primary : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? DeliveryColors.primary.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isToggling ? null : _handleToggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: isOnline
                ? _buildOnlineContent()
                : _buildOfflineContent(state),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineContent(HomeState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Grey toggle indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(3),
              alignment: Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'YOU ARE OFFLINE',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Tap to start accepting deliveries',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '\u0B9F\u0BC6\u0BB2\u0BBF\u0BB5\u0BB0\u0BBF \u0B8F\u0BB1\u0BCD\u0B95 \u0BA4\u0B9F\u0BCD\u0B9F\u0BB5\u0BC1\u0BAE\u0BCD',
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        if (state.todayEarnings > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Today: ${CurrencyUtil.format(state.todayEarnings)}',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOnlineContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Teal toggle indicator (right position)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: DeliveryColors.online,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(3),
              alignment: Alignment.centerRight,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Pulsing green dot
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: DeliveryColors.online,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DeliveryColors.online.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'YOU ARE ONLINE',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Accepting deliveries',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Location active',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              _formatOnlineDuration(),
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
