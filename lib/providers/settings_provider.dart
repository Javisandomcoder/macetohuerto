import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool remindersPaused;
  final DateTime? pausedUntil;

  const AppSettings({this.remindersPaused = false, this.pausedUntil});

  AppSettings copyWith({bool? remindersPaused, DateTime? pausedUntil}) => AppSettings(
        remindersPaused: remindersPaused ?? this.remindersPaused,
        pausedUntil: pausedUntil ?? this.pausedUntil,
      );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        remindersPaused: (json['remindersPaused'] as bool?) ?? false,
        pausedUntil: json['pausedUntil'] != null ? DateTime.tryParse(json['pausedUntil'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'remindersPaused': remindersPaused,
        'pausedUntil': pausedUntil?.toIso8601String(),
      };
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier()..load();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _key = 'app_settings';
  SettingsNotifier() : super(const AppSettings());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = AppSettings.fromJson(map);
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> setRemindersPaused(bool paused) async {
    state = state.copyWith(remindersPaused: paused);
    await _save();
  }

  Future<void> setPausedUntil(DateTime? date) async {
    state = state.copyWith(pausedUntil: date);
    await _save();
  }
}

