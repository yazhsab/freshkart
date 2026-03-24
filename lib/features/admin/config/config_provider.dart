import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── Config Notifier ──────────────────────────────────────────────

final configProvider =
    AsyncNotifierProvider<ConfigNotifier, Map<String, String>>(
  ConfigNotifier.new,
);

class ConfigNotifier extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() => _fetch();

  Future<Map<String, String>> _fetch() async {
    final rows = await adminClient.from('platform_config').select();
    final map = <String, String>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String? ?? '';
    }
    return map;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Saves a map of changed key-value pairs.
  /// Each key is upserted into platform_config and logged into config_change_log.
  Future<void> saveConfig(Map<String, String> changes) async {
    for (final entry in changes.entries) {
      // Get old value
      final current = state.value;
      final oldValue = current?[entry.key] ?? '';

      // Upsert config
      await adminClient.from('platform_config').upsert({
        'key': entry.key,
        'value': entry.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');

      // Log change
      await adminClient.from('config_change_log').insert({
        'config_key': entry.key,
        'old_value': oldValue,
        'new_value': entry.value,
        'changed_at': DateTime.now().toIso8601String(),
      });
    }

    await refresh();
  }
}

// ── Config change log ────────────────────────────────────────────

final configChangeLogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await adminClient
      .from('config_change_log')
      .select()
      .order('changed_at', ascending: false)
      .limit(50);
});
