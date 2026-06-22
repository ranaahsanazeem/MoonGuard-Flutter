import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_timezone/flutter_timezone.dart";
import "package:timezone/data/latest.dart" as tz_data;
import "package:timezone/timezone.dart" as tz;

import "package:get/get.dart";

import "../../data/mg_models.dart";
import "../../data/moon_guard_repository.dart";

/// Local alarms for child routines (works offline; not Supabase timers).
class RoutineNotificationService {
  RoutineNotificationService._();
  static final RoutineNotificationService instance = RoutineNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Last scheduled routine ids per child (for cancel removed).
  final Map<String, Set<String>> _lastRoutineIdsByChild = {};

  static int notificationIdForRoutine(String routineId) {
    var h = 0;
    for (final c in routineId.codeUnits) {
      h = 0x1fffffff & (h + c);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= h >> 6;
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= h >> 11;
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    h ^= h >> 10;
    return h == 0 ? 1 : h;
  }

  String _kindLabel(String k) {
    switch (k) {
      case "prayer":
        return "Prayer";
      case "sleep":
        return "Sleep";
      case "study":
        return "Study";
      case "reminder":
        return "Reminder";
      case "custom":
        return "Custom";
      default:
        if (k.isEmpty) {
          return "Routine";
        }
        return "${k[0].toUpperCase()}${k.substring(1)}";
    }
  }

  (int, int)? _parseHhMm(Routine r) {
    final s = r.timeOfDay;
    if (s == null || s.isEmpty) {
      return null;
    }
    final parts = s.split(":");
    if (parts.length < 2) {
      return null;
    }
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) {
      return null;
    }
    return (h, m);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    if (_ready) {
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings("@mipmap/ic_launcher");
    const ios = DarwinInitializationSettings();
    const init = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        final p = r.payload;
        debugPrint("Routine notification: $p");
        // Azan is system-only (res/raw) to avoid double playback on tap. Log tap for FYP.
        if (Get.isRegistered<MoonGuardRepository>()) {
          unawaited(Get.find<MoonGuardRepository>().tryLogRoutineFromNotificationPayload(p));
        }
      },
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _ready = true;
  }

  /// Cancel notifications for routines that disappeared; schedule current enabled rows.
  void rescheduleForChild(String childProfileId, List<Routine> routines) {
    if (kIsWeb || !_ready) {
      return;
    }

    final prev = _lastRoutineIdsByChild[childProfileId] ?? {};
    final nextIds = routines.map((e) => e.id).toSet();
    for (final id in prev) {
      if (!nextIds.contains(id)) {
        _plugin.cancel(notificationIdForRoutine(id));
      }
    }
    _lastRoutineIdsByChild[childProfileId] = nextIds;

    for (final r in routines) {
      final nid = notificationIdForRoutine(r.id);
      _plugin.cancel(nid);
      if (!r.isEnabled) {
        continue;
      }
      final hm = _parseHhMm(r);
      if (hm == null) {
        continue;
      }
      _scheduleZoned(r, hm.$1, hm.$2);
    }
  }

  Future<void> _scheduleZoned(Routine r, int hour, int minute) async {
    final when = _nextInstanceOfTime(hour, minute);
    final isPrayer = r.kind == "prayer";
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isPrayer ? "prayer_channel" : "moon_guard_routines",
        isPrayer ? "Prayer Alerts" : "Routines",
        channelDescription: isPrayer
            ? "Salah reminders — put azan in android/.../res/raw/azan.mp3"
            : "Sleep, study, and custom schedule alarms",
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: isPrayer && Platform.isAndroid ? const RawResourceAndroidNotificationSound("azan") : null,
        styleInformation: isPrayer
            ? BigTextStyleInformation(
                "Time for ${r.title} prayer — open Moon Guard to log or view.",
                contentTitle: "Prayer time",
                summaryText: "Moon Guard",
              )
            : null,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        notificationIdForRoutine(r.id),
        _kindLabel(r.kind),
        r.title,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: r.repeatsDaily ? DateTimeComponents.time : null,
        payload: isPrayer ? "prayer:${r.id}" : "other:${r.id}",
      );
    } catch (e, st) {
      debugPrint("Routine schedule: $e\n$st");
    }
  }

  /// Clear all routine notifications for a child (e.g. sign out).
  void clearForChild(String childProfileId) {
    final ids = _lastRoutineIdsByChild.remove(childProfileId);
    if (ids == null) {
      return;
    }
    for (final id in ids) {
      _plugin.cancel(notificationIdForRoutine(id));
    }
  }
}
