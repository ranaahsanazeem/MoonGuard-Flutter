import "package:flutter/material.dart";

import "../data/mg_models.dart";

/// Helpers for prayer / routine times of day (HH:mm from Supabase).
class RoutineTimeUtils {
  RoutineTimeUtils._();

  static TimeOfDay? parseTime(Routine r) {
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
    return TimeOfDay(hour: h, minute: m);
  }

  /// Today's instance of this routine has passed (same calendar day).
  static bool isMissed(Routine r) {
    if (!r.isEnabled) {
      return false;
    }
    final t = parseTime(r);
    if (t == null) {
      return false;
    }
    final now = TimeOfDay.now();
    final n = now.hour * 60 + now.minute;
    final rt = t.hour * 60 + t.minute;
    return rt < n;
  }

  /// Next enabled [kind == prayer] routine: first today still in the future, else first of the list (tomorrow’s first).
  static Routine? getNextPrayer(List<Routine> routines) {
    final prayers = routines.where((r) => r.isEnabled && r.kind == "prayer").toList();
    if (prayers.isEmpty) {
      return null;
    }
    prayers.sort(_compareRoutinesByTime);
    final now = TimeOfDay.now();
    for (final r in prayers) {
      final t = parseTime(r);
      if (t == null) {
        continue;
      }
      if (t.hour > now.hour || (t.hour == now.hour && t.minute > now.minute)) {
        return r;
      }
    }
    return prayers.first;
  }

  /// Next alarm across all enabled routines (chronological next occurrence).
  static Routine? getNextScheduledRoutine(List<Routine> routines) {
    final now = DateTime.now();
    Routine? bestR;
    DateTime? bestAt;
    for (final r in routines) {
      if (!r.isEnabled) {
        continue;
      }
      final t = parseTime(r);
      if (t == null) {
        continue;
      }
      var d = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      if (!d.isAfter(now)) {
        d = d.add(const Duration(days: 1));
      }
      if (bestAt == null || d.isBefore(bestAt!)) {
        bestAt = d;
        bestR = r;
      }
    }
    return bestR;
  }

  static int _compareRoutinesByTime(Routine a, Routine b) {
    final ta = parseTime(a);
    final tb = parseTime(b);
    if (ta == null) {
      return 1;
    }
    if (tb == null) {
      return -1;
    }
    final ma = ta.hour * 60 + ta.minute;
    final mb = tb.hour * 60 + tb.minute;
    return ma.compareTo(mb);
  }
}
