import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        final isOffline =
            results.contains(ConnectivityResult.none) || results.isEmpty;

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.red.shade700,
          child: const Text(
            'No internet connection',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
