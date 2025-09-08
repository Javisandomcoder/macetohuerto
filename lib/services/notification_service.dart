import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/plant.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    // Timezone
    tz.initializeTimeZones();
    final String localName = tz.local.name; // uses device default
    tz.setLocalLocation(tz.getLocation(localName));

    // Android init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (resp) async {},
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

    // Request permissions (Android 13+) and iOS if needed
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    _initialized = true;
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
      'watering_reminders',
      'Watering Reminders',
      channelDescription: 'Reminders to water plants',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    );
    const details = NotificationDetails(android: androidDetails);

    Future<void> _schedule(AndroidScheduleMode mode) async {
      await _plugin.zonedSchedule(
        _idForPlant(plant),
        'Riego: ${plant.name}',
        'Toca para ver detalles y registrar riego',
        nextDt,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        payload: plant.id,
      );
    }

    try {
      await _schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await _schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } else {
        rethrow;
      }
    }
  }
}
