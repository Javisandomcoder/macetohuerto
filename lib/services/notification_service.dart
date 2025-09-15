import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/plant.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const String _channelId = 'watering_reminders_v2';
  static const String _channelName = 'Watering Reminders';
  static const String _channelDescription = 'Reminders to water plants';

  Future<void> init() async {
    if (_initialized) return;
    // Timezone
    tz.initializeTimeZones();
    final String localName = tz.local.name; // uses device default
    tz.setLocalLocation(tz.getLocation(localName));

    // Platform init (Android + iOS/macOS)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit);
    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (resp) async {},
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

    // Do not force permissions here; handled by ensurePermissions()
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Proactively create/update notification channel on Android 8.0+
    try {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      );
      await android?.createNotificationChannel(channel);
    } catch (_) {}

    // iOS/macOS permissions
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    final macos = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  /// Ensures notifications permissions are granted on the current platform.
  /// Returns true if notifications are enabled.
  Future<bool> ensurePermissions() async {
    if (!_initialized) await init();

    // ANDROID
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final bool? areEnabled = await android.areNotificationsEnabled();
      bool enabled = areEnabled ?? true;
      if (!enabled) {
        final bool? granted = await android.requestNotificationsPermission();
        enabled = granted ?? false;
      }
      // Request exact alarms on Android 12+
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {}
      return enabled;
    }

    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final res = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return res ?? true;
    }

    // macOS
    final macos = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      final res = await macos.requestPermissions(alert: true, badge: true, sound: true);
      return res ?? true;
    }

    return true;
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    // No-op in MVP
  }

  int _idForPlant(Plant p) => p.id.hashCode & 0x7fffffff;

  Future<void> cancelForPlant(Plant p) async {
    await _plugin.cancel(_idForPlant(p));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> scheduleNextForPlant({
    required Plant plant,
    required bool globallyPaused,
    DateTime? pausedUntil,
  }) async {
    if (!_initialized) await init();
    final allowed = await ensurePermissions();
    if (!allowed) return;

    await cancelForPlant(plant);

    if (!plant.reminderEnabled || plant.reminderPaused || globallyPaused) {
      return;
    }
    if (pausedUntil != null && DateTime.now().isBefore(pausedUntil)) {
      return;
    }

    final interval = plant.wateringIntervalDays ?? 2;
    final timeStr = plant.wateringTime ?? '09:00';
    final parts = timeStr.split(':');
    final hh = int.tryParse(parts[0]) ?? 9;
    final mm = int.tryParse(parts[1]) ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    DateTime baseline = plant.lastWateredAt ?? plant.plantedAt ?? DateTime.now();
    baseline = DateTime(baseline.year, baseline.month, baseline.day);

    int daysSince = DateTime(now.year, now.month, now.day).difference(baseline).inDays;
    int k = (daysSince / max(1, interval)).ceil();
    if (k < 1) k = 1;
    var nextDate = baseline.add(Duration(days: k * interval));
    var nextDt = tz.TZDateTime(tz.local, nextDate.year, nextDate.month, nextDate.day, hh, mm);
    if (!nextDt.isAfter(now)) {
      nextDate = nextDate.add(Duration(days: interval));
      nextDt = tz.TZDateTime(tz.local, nextDate.year, nextDate.month, nextDate.day, hh, mm);
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    Future<void> schedule(AndroidScheduleMode mode) async {
      await _plugin.zonedSchedule(
        _idForPlant(plant),
        'Riego: ${plant.name}',
        'Toca para ver detalles y registrar riego',
        nextDt,
        details,
        androidScheduleMode: mode,
        matchDateTimeComponents: null,
        payload: plant.id,
      );
    }
    // Prefer inexact to avoid exact alarm restrictions on Android 12+
    await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
  }

  Future<void> scheduleTestInSeconds(int seconds) async {
    if (!_initialized) await init();
    final allowed = await ensurePermissions();
    if (!allowed) return;
    final now = tz.TZDateTime.now(tz.local);
    final when = now.add(Duration(seconds: seconds));

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    Future<void> schedule(AndroidScheduleMode mode) async {
      await _plugin.zonedSchedule(
        999991,
        'Notificación de prueba',
        'Esto es un test de recordatorio',
        when,
        details,
        androidScheduleMode: mode,
        matchDateTimeComponents: null,
        payload: 'test',
      );
    }

    await schedule(AndroidScheduleMode.inexactAllowWhileIdle);

    // Disparo inmediato adicional para verificar canal/permiso (visible al instante)
    await _plugin.show(
      999990,
      'Notificación de prueba',
      'Mostrada inmediatamente',
      details,
      payload: 'test-immediate-2',
    );
  }
}
