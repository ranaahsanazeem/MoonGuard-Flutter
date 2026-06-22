import "dart:convert";

import "package:http/http.dart" as http;

/// Fetches today's prayer times (Fajr–Isha) from [Aladhan](https://aladhan.com/prayer-times-api) by location.
class PrayerService {
  PrayerService._();

  /// [method] 2 = Islamic Society of North America (ISNA); see API docs for others.
  static Future<Map<String, String>> getPrayerTimes(
    double lat,
    double lng, {
    int method = 2,
  }) async {
    final url = Uri.parse(
      "https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lng&method=$method",
    );
    final res = await http.get(url);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError("Aladhan API error: ${res.statusCode} ${res.body}");
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final d = data["data"] as Map<String, dynamic>?;
    if (d == null) {
      throw StateError("Aladhan: missing data");
    }
    final timings = d["timings"] as Map<String, dynamic>?;
    if (timings == null) {
      throw StateError("Aladhan: missing timings");
    }
    return {
      "Fajr": _hhMm(timings["Fajr"] as String?),
      "Dhuhr": _hhMm(timings["Dhuhr"] as String?),
      "Asr": _hhMm(timings["Asr"] as String?),
      "Maghrib": _hhMm(timings["Maghrib"] as String?),
      "Isha": _hhMm(timings["Isha"] as String?),
    };
  }

  /// API may return "16:20" or "16:20 (GMT+3)"; normalize to HH:mm for Postgres time.
  static String _hhMm(String? raw) {
    if (raw == null || raw.isEmpty) {
      return "12:00";
    }
    final t = raw.trim();
    final paren = t.indexOf("(");
    final s = paren < 0 ? t : t.substring(0, paren).trim();
    if (s.length >= 5 && s[2] == ":") {
      return s.substring(0, 5);
    }
    return s;
  }
}
