import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showReconnected = false;
  bool _hasBeenOffline = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _onConnectivityChanged(results);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final offline =
        results.contains(ConnectivityResult.none) || results.isEmpty;

    if (offline && !_isOffline) {
      setState(() {
        _isOffline = true;
        _hasBeenOffline = true;
        _showReconnected = false;
      });
      _hideTimer?.cancel();
    } else if (!offline && _isOffline) {
      setState(() {
        _isOffline = false;
        if (_hasBeenOffline) {
          _showReconnected = true;
        }
      });
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showReconnected = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline
              ? 40
              : _showReconnected
              ? 32
              : 0,
          width: double.infinity,
          color: _isOffline ? DeliveryColors.newOrder : const Color(0xFF43A047),
          alignment: Alignment.center,
          child: _isOffline
              ? Text(
                  'No internet \u2022 Location updates paused',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                )
              : _showReconnected
              ? Text(
                  'Connected \u2713',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
