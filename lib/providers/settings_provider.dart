import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SeasonMode {
  summer('summer', 'Verano', 1.0),
  winter('winter', 'Invierno', 1.5);

  final String id;
  final String label;
  final double multiplier;

  const SeasonMode(this.id, this.label, this.multiplier);

  static SeasonMode fromId(String id) {
    return SeasonMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => SeasonMode.summer,
    );
  }
}

class AppSettings {
  final bool remindersPaused;
  final DateTime? pausedUntil;
  final SeasonMode seasonMode;

  const AppSettings({
    this.remindersPaused = false,
    this.pausedUntil,
    this.seasonMode = SeasonMode.summer,
  });

  AppSettings copyWith({
    bool? remindersPaused,
    DateTime? pausedUntil,
    SeasonMode? seasonMode,
  }) =>
      AppSettings(
        remindersPaused: remindersPaused ?? this.remindersPaused,
        pausedUntil: pausedUntil ?? this.pausedUntil,
        seasonMode: seasonMode ?? this.seasonMode,
      );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        remindersPaused: (json['remindersPaused'] as bool?) ?? false,
        pausedUntil: json['pausedUntil'] != null
            ? DateTime.tryParse(json['pausedUntil'] as String)
            : null,
        seasonMode: json['seasonMode'] != null
            ? SeasonMode.fromId(json['seasonMode'] as String)
            : SeasonMode.summer,
      );

  Map<String, dynamic> toJson() => {
        'remindersPaused': remindersPaused,
        'pausedUntil': pausedUntil?.toIso8601String(),
        'seasonMode': seasonMode.id,
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

  Future<void> setSeasonMode(SeasonMode mode) async {
    state = state.copyWith(seasonMode: mode);
    await _save();
  }
}

