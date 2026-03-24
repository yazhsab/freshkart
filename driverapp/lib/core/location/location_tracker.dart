import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../config/supabase_config.dart';
import '../storage/local_storage.dart';
import 'location_service.dart';

class LocationTrackerState {
  final bool isTracking;
  final double? currentLat;
  final double? currentLng;
  final String? currentOrderId;
  final DateTime? lastUpdateTime;
  final double totalKmToday;
  final String? error;

  const LocationTrackerState({
    this.isTracking = false,
    this.currentLat,
    this.currentLng,
    this.currentOrderId,
    this.lastUpdateTime,
    this.totalKmToday = 0.0,
    this.error,
  });

  bool get hasPosition => currentLat != null && currentLng != null;

  LocationTrackerState copyWith({
    bool? isTracking,
    double? currentLat,
    double? currentLng,
    String? currentOrderId,
    DateTime? lastUpdateTime,
    double? totalKmToday,
    String? error,
  }) {
    return LocationTrackerState(
      isTracking: isTracking ?? this.isTracking,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      totalKmToday: totalKmToday ?? this.totalKmToday,
      error: error,
    );
  }
}

class LocationTrackerNotifier extends StateNotifier<LocationTrackerState> {
  LocationTrackerNotifier() : super(const LocationTrackerState());

  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastUploadTime;
  static const _uploadThrottleSeconds = 5;

  Future<void> startTracking(String? orderId) async {
    if (state.isTracking) return;

    final hasPermission = await LocationService.initialize();
    if (!hasPermission) {
      state = state.copyWith(error: 'Location permission denied');
      return;
    }

    await WakelockPlus.enable();

    state = state.copyWith(
      isTracking: true,
      currentOrderId: orderId,
      error: null,
    );

    _positionSubscription = LocationService.getPositionStream().listen(
      _onPositionUpdate,
      onError: (e) {
        state = state.copyWith(error: e.toString());
      },
    );
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastUploadTime = null;

    await WakelockPlus.disable();

    state = state.copyWith(isTracking: false, currentOrderId: null);
  }

  void _onPositionUpdate(Position position) {
    double addedKm = 0.0;
    if (state.hasPosition) {
      addedKm = LocationService.calculateDistance(
        state.currentLat!,
        state.currentLng!,
        position.latitude,
        position.longitude,
      );
    }

    state = state.copyWith(
      currentLat: position.latitude,
      currentLng: position.longitude,
      lastUpdateTime: DateTime.now(),
      totalKmToday: state.totalKmToday + addedKm,
    );

    _throttledUpload(position);
  }

  Future<void> _throttledUpload(Position position) async {
    final now = DateTime.now();
    if (_lastUploadTime != null &&
        now.difference(_lastUploadTime!).inSeconds < _uploadThrottleSeconds) {
      return;
    }
    _lastUploadTime = now;

    final agentId = LocalStorage.agentId;
    if (agentId == null) return;

    try {
      await SupabaseConfig.client.from('delivery_locations').upsert({
        'agent_id': agentId,
        'order_id': state.currentOrderId,
        'lat': position.latitude,
        'lng': position.longitude,
        'updated_at': now.toIso8601String(),
      }, onConflict: 'agent_id');
    } catch (_) {
      // Silently fail - location uploads are best-effort
    }
  }

  void resetDailyKm() {
    state = state.copyWith(totalKmToday: 0.0);
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

final locationTrackerProvider =
    StateNotifierProvider<LocationTrackerNotifier, LocationTrackerState>((ref) {
      return LocationTrackerNotifier();
    });
