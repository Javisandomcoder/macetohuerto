import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/plant.dart';
import '../utils/feedback_overlay.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _timeZoneName;
  final StreamController<String> _tapStreamController =
      StreamController<String>.broadcast();
  String? _pendingTapPayload;
  static const String _channelId = 'watering_reminders_v2';
  static const String _channelName = 'Watering Reminders';
  static const String _channelDescription = 'Reminders to water plants';

  Future<void> init() async {
    if (_initialized) return;
    // Timezone
    tz.initializeTimeZones();
    // Ajusta tz.local al huso horario del dispositivo; si falla usa un fallback con el offset actual.
    try {
      final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _timeZoneName = timeZoneName;
    } catch (error) {
      _applyLocalFallbackTimezone(error);
    }
    // ignore: avoid_print
    print("NotificationService timezone: ${_timeZoneName ?? 'unknown'}");

    // Platform init (Android + iOS/macOS)
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
        android: androidInit, iOS: darwinInit, macOS: darwinInit);
    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
    await _captureInitialTapPayload();

    // Do not force permissions here; handled by ensurePermissions()
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

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
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  /// Ensures notifications permissions are granted on the current platform.
  /// Returns true if notifications are enabled.
  Future<bool> ensurePermissions() async {
    if (!_initialized) await init();

    // ANDROID
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
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
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final res =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return res ?? true;
    }

    // macOS
    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      final res =
          await macos.requestPermissions(alert: true, badge: true, sound: true);
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

  Stream<String> get tapStream => _tapStreamController.stream;

  String? consumeInitialTapPayload() {
    final payload = _pendingTapPayload;
    _pendingTapPayload = null;
    return payload;
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

    final interval = max(1, plant.wateringIntervalDays ?? 2);
    final timeStr = plant.wateringTime ?? '09:00';
    final parts = timeStr.split(':');
    final hh = int.tryParse(parts[0]) ?? 9;
    final mm = int.tryParse(parts[1]) ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    final baseSource = plant.lastWateredAt ?? plant.plantedAt;
    final effectiveBase =
        baseSource != null ? tz.TZDateTime.from(baseSource, tz.local) : now;

    var nextDt = tz.TZDateTime(tz.local, effectiveBase.year,
        effectiveBase.month, effectiveBase.day, hh, mm);
    if (!nextDt.isAfter(effectiveBase)) {
      nextDt = nextDt.add(Duration(days: interval));
    }
    while (!nextDt.isAfter(now)) {
      nextDt = nextDt.add(Duration(days: interval));
    }
    // ignore: avoid_print
    print('Programando recordatorio para  -> , ahora: , tz: ');
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    final details = NotificationDetails(
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

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (error) {
      // ignore: avoid_print
      print('Fallo al programar exacto: $error -> se usa modo inexacto');
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> scheduleTestInSeconds(int seconds) async {
    if (!_initialized) await init();
    final allowed = await ensurePermissions();
    if (!allowed) return;
    final now = tz.TZDateTime.now(tz.local);
    final when = now.add(Duration(seconds: seconds));
    // ignore: avoid_print
    print(
        'Programando test en ${when.toIso8601String()}, tz: ${_timeZoneName ?? 'desconocido'}');

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    Future<void> schedule(AndroidScheduleMode mode) async {
      await _plugin.zonedSchedule(
        999991,
        'Notificacion de prueba',
        'Esto es un test de recordatorio',
        when,
        details,
        androidScheduleMode: mode,
        matchDateTimeComponents: null,
        payload: 'test',
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (error) {
      // ignore: avoid_print
      print('Fallo al programar exacto (test): $error -> se usa modo inexacto');
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }

    // Debug: show how many are pending and the scheduled time.
    try {
      final pending = await _plugin.pendingNotificationRequests();
      // Best-effort feedback: requires a BuildContext, so we only log if available.
      // Callers can use debugShowPending from UI.
      // ignore: avoid_print
      print('Scheduled test for: $when | pending: ${pending.length}');
    } catch (_) {}

    // Disparo inmediato adicional para verificar canal/permiso (visible al instante)
    await _plugin.show(
      999990,
      'Notificacion de prueba',
      'Mostrada inmediatamente',
      details,
      payload: 'test-immediate-2',
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _tapStreamController.add(payload);
  }

  Future<void> _captureInitialTapPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final payload = details?.notificationResponse?.payload;
      if ((details?.didNotificationLaunchApp ?? false) &&
          payload != null &&
          payload.isNotEmpty) {
        _pendingTapPayload = payload;
      }
    } catch (_) {}
  }

  Future<void> debugShowPending(BuildContext context) async {
    final pending = await _plugin.pendingNotificationRequests();
    final count = pending.length;
    if (!context.mounted) return;
    FeedbackOverlay.show(context, text: 'Pendientes: $count');
  }

  void _applyLocalFallbackTimezone(Object error) {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final abbreviation =
          now.timeZoneName.isEmpty ? 'Local' : now.timeZoneName;
      final location = tz.Location('LocalFallback', [
        tz.minTime
      ], [
        0
      ], [
        tz.TimeZone(offset.inMilliseconds,
            isDst: false, abbreviation: abbreviation),
      ]);
      tz.setLocalLocation(location);
      _timeZoneName = 'offset:${offset.inMinutes}';
      // ignore: avoid_print
      print(
          'Fallback timezone applied (${_timeZoneName ?? 'unknown'}) | error: $error');
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      _timeZoneName = 'UTC';
      // ignore: avoid_print
      print('Fallback timezone defaulted to UTC');
    }
  }

  Future<void> openExactAlarmSettingsIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final canExact = await android.canScheduleExactNotifications() ?? false;
    if (!canExact) {
      await android.requestExactAlarmsPermission();
    }
  }
}



