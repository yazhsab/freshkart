import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';

class NewOrderAlertScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;

  const NewOrderAlertScreen({super.key, required this.order});

  @override
  ConsumerState<NewOrderAlertScreen> createState() =>
      _NewOrderAlertScreenState();
}

class _NewOrderAlertScreenState extends ConsumerState<NewOrderAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _bellController;
  late AnimationController _pulseController;
  late Animation<double> _bellAnimation;
  late Animation<double> _pulseAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _countdownTimer;
  int _remainingSeconds = VendorAppConfig.orderAutoConfirmSeconds;
  bool _handled = false;

  @override
  void initState() {
    super.initState();

    // Bell shake animation
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _bellAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );

    // Pulse animation for timer
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
    _playAlertSound();
    _vibrate();
  }

  void _startCountdown() {
    // Calculate remaining based on order creation time
    final createdAt =
        DateTime.tryParse(widget.order['created_at'] ?? '') ?? DateTime.now();
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    _remainingSeconds = VendorAppConfig.orderAutoConfirmSeconds - elapsed;
    if (_remainingSeconds < 0) _remainingSeconds = 0;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoAccept();
      }
    });
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/new_order.mp3'));
    } catch (_) {
      // Audio file may not exist in dev
    }
  }

  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500], repeat: 0);
      }
    } catch (_) {}
  }

  void _stopAlerts() {
    _audioPlayer.stop();
    Vibration.cancel();
  }

  void _autoAccept() {
    if (_handled) return;
    _handled = true;
    _stopAlerts();
    _showAutoConfirmAnimation();
  }

  void _showAutoConfirmAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: VendorColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'Order auto-confirmed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        Navigator.of(context).pop(true); // return accepted
      }
    });
  }

  void _acceptOrder() {
    if (_handled) return;
    _handled = true;
    _countdownTimer?.cancel();
    _stopAlerts();
    Navigator.of(context).pop(true);
  }

  void _rejectOrder() {
    if (_handled) return;
    _countdownTimer?.cancel();
    _stopAlerts();
    _showRejectReasonPicker();
  }

  void _showRejectReasonPicker() {
    final reasons = [
      'Out of stock',
      'Shop closing',
      'Too many orders',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reason for rejection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (reason) => ListTile(
                  title: Text(reason),
                  leading: const Icon(Icons.circle_outlined, size: 20),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handled = true;
                    Navigator.of(
                      context,
                    ).pop({'rejected': true, 'reason': reason});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((value) {
      // If bottom sheet dismissed without selecting, resume timer
      if (!_handled && mounted) {
        _handled = false;
        _startCountdown();
        _playAlertSound();
        _vibrate();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bellController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = (widget.order['id']?.toString() ?? '--------').substring(
      0,
      8,
    );
    final totalAmount = (widget.order['total_amount'] ?? 0).toDouble();
    final customerName = widget.order['customer']?['name'] ?? 'Customer';
    final customerArea = widget.order['delivery_address']?['area'] ?? '';
    final items = widget.order['items'] as List? ?? [];
    final progress = VendorAppConfig.orderAutoConfirmSeconds > 0
        ? _remainingSeconds / VendorAppConfig.orderAutoConfirmSeconds
        : 0.0;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF6F00), Color(0xFFE65100), Color(0xFFBF360C)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Flashing bell
                AnimatedBuilder(
                  animation: _bellAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _bellAnimation.value,
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 16),

                // NEW ORDER text
                const Text(
                  'NEW ORDER!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),

                // Order details card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#$orderId',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${VendorAppConfig.currency}${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (customerArea.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                customerArea,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (items.isNotEmpty) ...[
                        const Divider(color: Colors.white24, height: 24),
                        ...items.take(4).map((item) {
                          final name = item['product_name'] ?? 'Item';
                          final qty = item['quantity'] ?? 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${qty}x',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    name.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (items.length > 4)
                          Text(
                            '+${items.length - 4} more items',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Countdown timer
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '$_remainingSeconds',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // REJECT
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _rejectOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VendorColors.cancelledOrder,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'REJECT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // ACCEPT
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _acceptOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VendorColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'ACCEPT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget that wraps AnimatedWidget for rotation building
class AnimatedBuilder extends AnimatedWidget {
  final Widget? child;
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
