import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/profile.dart';
import '../../core/supabase/client.dart';

/// Holds the current admin [Profile] or null when not authenticated.
///
/// Uses the Riverpod 3.x AsyncNotifier pattern. Listens to Supabase
/// auth state changes so the UI reacts automatically to sign-in,
/// sign-out, and token-refresh events.
class AuthNotifier extends AsyncNotifier<Profile?> {
  StreamSubscription<AuthState>? _authSub;

  @override
  FutureOr<Profile?> build() {
    _listenAuthChanges();
    ref.onDispose(() => _authSub?.cancel());

    final session = supabase.auth.currentSession;
    if (session == null) return null;
    return _fetchAdminProfile(session.user.id);
  }

  void _listenAuthChanges() {
    _authSub?.cancel();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          final userId = data.session?.user.id;
          if (userId != null) {
            state = const AsyncLoading();
            _fetchAdminProfile(userId).then(
              (profile) => state = AsyncData(profile),
              onError: (e, st) => state = AsyncError(e, st),
            );
          }
        case AuthChangeEvent.signedOut:
          state = const AsyncData(null);
        default:
          break;
      }
    });
  }

  Future<Profile?> _fetchAdminProfile(String userId) async {
    final data = await adminClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;

    final profile = Profile.fromJson(data);
    if (profile.role != 'admin') {
      await supabase.auth.signOut();
      throw Exception('Access denied. Admin privileges required.');
    }
    return profile;
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Sign in failed. No user returned.');
      }
      final profile = await _fetchAdminProfile(userId);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, Profile?>(AuthNotifier.new);

/// A [ChangeNotifier] that fires whenever the Supabase auth state changes.
/// Used as [GoRouter.refreshListenable] so the router re-evaluates redirects.
class AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  AuthRefreshNotifier() {
    _sub = supabase.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authRefreshNotifierProvider = Provider<AuthRefreshNotifier>((ref) {
  final notifier = AuthRefreshNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});
