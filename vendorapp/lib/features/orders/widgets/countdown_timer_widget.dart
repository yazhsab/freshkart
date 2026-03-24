import 'dart:async';
import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime orderCreatedAt;
  final int totalSeconds;
  final VoidCallback? onTimeout;
  final double size;

  const CountdownTimerWidget({
    super.key,
    required this.orderCreatedAt,
    this.totalSeconds = 60,
    this.onTimeout,
    this.size = 56,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  int _remaining = 0;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final elapsed = DateTime.now().difference(widget.orderCreatedAt).inSeconds;
    final remaining = widget.totalSeconds - elapsed;

    if (remaining <= 0 && !_timedOut) {
      _timedOut = true;
      _timer?.cancel();
      setState(() => _remaining = 0);
      widget.onTimeout?.call();
      return;
    }

    if (remaining >= 0) {
      setState(() => _remaining = remaining);
    }
  }

  Color get _progressColor {
    if (_remaining > 30) return VendorColors.primaryLight;
    if (_remaining > 10) return VendorColors.newOrder;
    return VendorColors.cancelledOrder;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds > 0
        ? _remaining / widget.totalSeconds
        : 0.0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: VendorColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
            ),
          ),
          Text(
            '${_remaining}s',
            style: TextStyle(
              fontSize: widget.size * 0.28,
              fontWeight: FontWeight.bold,
              color: _progressColor,
            ),
          ),
        ],
      ),
    );
  }
}
