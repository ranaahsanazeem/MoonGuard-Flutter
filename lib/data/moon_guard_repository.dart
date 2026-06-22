import "dart:typed_data";

import "package:flutter/foundation.dart";
import "package:latlong2/latlong.dart" show LatLng;
import "package:mime/mime.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:uuid/uuid.dart";

import "mg_models.dart";

const int kMaxChildProfiles = 5;

class MoonGuardRepository {
  MoonGuardRepository(this._c);
  final SupabaseClient _c;
  static const _uuid = Uuid();

  String get _userId {
    final u = _c.auth.currentUser;
    if (u == null) {
      throw StateError("Not signed in");
    }
    return u.id;
  }

  // ——— Children ———
  Future<List<ChildProfile>> listChildren() async {
    final res = await _c
        .from("child_profiles")
        .select()
        .eq("parent_id", _userId)
        .order("created_at", ascending: true);
    return (res as List).map((e) => ChildProfile.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<({String? error, ChildProfile? child})> addChild({required String name, int? age, String? deviceLabel}) async {
    final cur = await _c.from("child_profiles").select("id").eq("parent_id", _userId);
    final n = (cur as List).length;
    if (n >= kMaxChildProfiles) {
      return (error: "You can have at most $kMaxChildProfiles child profiles.", child: null);
    }
    try {
      final row = await _c
          .from("child_profiles")
          .insert({
            "parent_id": _userId,
            "name": name.trim(),
            "age": age,
            "device_label": deviceLabel,
          })
          .select()
          .single();
      return (error: null, child: ChildProfile.fromMap(Map<String, dynamic>.from(row)));
    } on PostgrestException catch (e) {
      return (error: e.message, child: null);
    }
  }

  Future<String?> updateChild(String id, {String? name, int? age, String? deviceLabel}) async {
    try {
      final map = <String, dynamic>{};
      if (name != null) map["name"] = name;
      if (age != null) map["age"] = age;
      if (deviceLabel != null) map["device_label"] = deviceLabel;
      if (map.isEmpty) return null;
      await _c.from("child_profiles").update(map).eq("id", id).eq("parent_id", _userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteChild(String id) async {
    try {
      await _c.from("child_profiles").delete().eq("id", id).eq("parent_id", _userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  // ——— Location ———
  Future<String?> addLocationPoint(String childId, double lat, double lng, {double? accuracyM}) async {
    try {
      await _c.from("location_points").insert({
        "child_profile_id": childId,
        "lat": lat,
        "lng": lng,
        "accuracy_m": accuracyM,
      });
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<List<LocationPoint>> listRecentLocations(String childId, {int limit = 50}) async {
    final res = await _c
        .from("location_points")
        .select()
        .eq("child_profile_id", childId)
        .order("recorded_at", ascending: false)
        .limit(limit);
    return (res as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return LocationPoint(
        id: m["id"] as int,
        childProfileId: m["child_profile_id"] as String,
        position: LatLng((m["lat"] as num).toDouble(), (m["lng"] as num).toDouble()),
        accuracyM: (m["accuracy_m"] as num?)?.toDouble(),
        recordedAt: DateTime.parse(m["recorded_at"] as String),
      );
    }).toList();
  }

  // ——— Chat ———
  Future<List<ChatMessage>> fetchMessages(String childId) async {
    final res = await _c
        .from("chat_messages")
        .select()
        .eq("child_profile_id", childId)
        .order("created_at", ascending: true);
    return (res as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ChatMessage(
        id: m["id"] as String,
        parentUserId: m["parent_user_id"] as String,
        childProfileId: m["child_profile_id"] as String,
        senderUserId: m["sender_user_id"] as String,
        messageType: m["message_type"] as String? ?? "text",
        body: m["body"] as String?,
        storagePath: m["storage_path"] as String?,
        createdAt: DateTime.parse(m["created_at"] as String),
      );
    }).toList();
  }

  Stream<List<ChatMessage>> messageStream(String childId) {
    return _c
        .from("chat_messages")
        .stream(primaryKey: const ["id"])
        .eq("child_profile_id", childId)
        .map((rows) {
      final out = (rows as List)
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return ChatMessage(
              id: m["id"] as String,
              parentUserId: m["parent_user_id"] as String,
              childProfileId: m["child_profile_id"] as String,
              senderUserId: m["sender_user_id"] as String,
              messageType: m["message_type"] as String? ?? "text",
              body: m["body"] as String?,
              storagePath: m["storage_path"] as String?,
              createdAt: DateTime.parse(m["created_at"] as String),
            );
          })
          .toList();
      out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return out;
    });
  }

  Future<String?> sendTextMessage(String childId, String text) async {
    return _insertMessage(
      childId: childId,
      messageType: "text",
      body: _sanitizeChat(text),
    );
  }

  String _pgTime(String hhMmOrHh) {
    final t = hhMmOrHh.trim();
    if (t.length == 5 && t.contains(":")) {
      return "$t:00";
    }
    if (t.length == 8 && t.split(":").length == 3) {
      return t;
    }
    return "09:00:00";
  }

  String _sanitizeChat(String s) {
    if (s.length > 8000) {
      return "${s.substring(0, 8000)}…";
    }
    return s;
  }

  Future<String?> _insertMessage({required String childId, required String messageType, String? body, String? path}) async {
    try {
      await _c.from("chat_messages").insert({
        "id": _uuid.v4(),
        "parent_user_id": _userId,
        "child_profile_id": childId,
        "sender_user_id": _userId,
        "message_type": messageType,
        "body": body,
        "storage_path": path,
      });
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendImageOrVideo(
    String childId,
    Uint8List bytes,
    String filename,
  ) async {
    final isVid = filename.toLowerCase().endsWith(".mp4") || filename.toLowerCase().endsWith(".mov");
    final msgId = _uuid.v4();
    final path = "$_userId/$childId/$msgId/${filename.isEmpty ? "file" : filename}";
    final ct = _guessMime(filename, bytes) ?? (isVid ? "video/mp4" : "image/jpeg");
    try {
      await _c.storage.from("chat-media").uploadBinary(path, bytes, fileOptions: FileOptions(contentType: ct));
    } on StorageException catch (e) {
      return e.message;
    }
    final t = isVid ? "video" : "image";
    return _insertMessage(childId: childId, messageType: t, body: null, path: path);
  }

  String? _guessMime(String name, Uint8List bytes) {
    final a = lookupMimeType(name, headerBytes: bytes);
    return a;
  }

  Future<String?> signedMediaUrl(String path) async {
    try {
      final u = await _c.storage.from("chat-media").createSignedUrl(path, 3600);
      return u;
    } on StorageException {
      return null;
    }
  }

  // ——— Keywords & apps & logs ———
  Future<List<BlockedKeyword>> listKeywords() async {
    final res = await _c.from("blocked_keywords").select().eq("parent_id", _userId).order("created_at", ascending: false);
    return (res as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return BlockedKeyword(
        id: m["id"] as String,
        parentId: m["parent_id"] as String,
        childProfileId: m["child_profile_id"] as String?,
        keyword: m["keyword"] as String,
        isActive: m["is_active"] as bool? ?? true,
      );
    }).toList();
  }

  Future<String?> addKeyword(String word, {String? childId}) async {
    try {
      await _c.from("blocked_keywords").insert({
        "parent_id": _userId,
        "child_profile_id": childId,
        "keyword": word.trim().toLowerCase(),
        "is_active": true,
      });
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteKeyword(String id) async {
    try {
      await _c.from("blocked_keywords").delete().eq("id", id).eq("parent_id", _userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  /// Blocked words visible to a **linked child** (RLS) for send-time filtering in child UI.
  Future<List<BlockedKeyword>> listKeywordsForChild(ChildProfile child) async {
    final res = await _c.from("blocked_keywords").select().eq("parent_id", child.parentId);
    return (res as List)
        .map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return BlockedKeyword(
            id: m["id"] as String,
            parentId: m["parent_id"] as String,
            childProfileId: m["child_profile_id"] as String?,
            keyword: m["keyword"] as String,
            isActive: m["is_active"] as bool? ?? true,
          );
        })
        .where((k) => k.isActive && (k.childProfileId == null || k.childProfileId == child.id))
        .toList();
  }

  Future<String?> logFilterEvent(String childId, String? keyword, {String? appContext}) async {
    try {
      await _c.from("filter_block_logs").insert({
        "parent_id": _userId,
        "child_profile_id": childId,
        "keyword": keyword,
        "app_context": appContext,
      });
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<List<BlockedApp>> listBlockedApps(String childId) async {
    final res = await _c.from("blocked_apps").select().eq("child_profile_id", childId);
    return (res as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return BlockedApp(
        id: m["id"] as String,
        parentId: m["parent_id"] as String,
        childProfileId: m["child_profile_id"] as String,
        packageName: m["package_name"] as String,
        appLabel: m["app_label"] as String?,
        manualBlock: m["manual_block"] as bool? ?? true,
        blurScreen: m["blur_screen"] as bool? ?? true,
        strictPin: m["strict_pin"] as bool? ?? true,
      );
    }).toList();
  }

  Future<String?> setBlockedAppStrict(String id, bool strictPin) async {
    try {
      await _c.from("blocked_apps").update({"strict_pin": strictPin}).eq("id", id).eq("parent_id", _userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<String?> addBlockedApp(
    String childId, {
    required String packageName,
    String? appLabel,
    bool blur = true,
    bool strictPin = true,
  }) async {
    try {
      await _c.from("blocked_apps").insert({
        "id": _uuid.v4(),
        "parent_id": _userId,
        "child_profile_id": childId,
        "package_name": packageName.trim(),
        "app_label": appLabel,
        "manual_block": true,
        "blur_screen": blur,
        "strict_pin": strictPin,
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.message.contains("duplicate") || (e.message.contains("unique"))) {
        return "That app is already blocked for this child.";
      }
      return e.message;
    }
  }

  Future<String?> removeBlockedApp(String id) async {
    try {
      await _c.from("blocked_apps").delete().eq("id", id).eq("parent_id", _userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  // ——— Routines ———
  Routine _routineFromMap(Map<String, dynamic> m) {
    final t = m["time_of_day"] as String?;
    return Routine(
      id: m["id"] as String,
      parentId: m["parent_id"] as String,
      childProfileId: m["child_profile_id"] as String,
      kind: m["kind"] as String,
      title: m["title"] as String,
      timeOfDay: t,
      daysMask: m["days_mask"] as int? ?? 127,
      isEnabled: m["is_enabled"] as bool? ?? true,
      notes: m["notes"] as String?,
      repeatsDaily: m["repeats_daily"] as bool? ?? true,
    );
  }

  Future<List<Routine>> listRoutines(String childId) async {
    final res = await _c.from("routines").select().eq("child_profile_id", childId).order("created_at", ascending: true);
    return (res as List).map((e) => _routineFromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Realtime: routine rows for [childId] (parent or linked child).
  Stream<List<Routine>> watchRoutines(String childId) {
    return _c
        .from("routines")
        .stream(primaryKey: const ["id"])
        .eq("child_profile_id", childId)
        .map((rows) {
      final out = (rows as List).map((e) => _routineFromMap(Map<String, dynamic>.from(e as Map))).toList();
      out.sort((a, b) => a.id.compareTo(b.id));
      return out;
    });
  }

  Future<String?> upsertRoutine(
    String childId, {
    String? id,
    required String kind,
    required String title,
    String? timeHhMm,
    int daysMask = 127,
    bool enabled = true,
    bool repeatsDaily = true,
    String? notes,
  }) async {
    try {
      final row = {
        "parent_id": _userId,
        "child_profile_id": childId,
        "kind": kind,
        "title": title,
        "time_of_day": (timeHhMm == null || timeHhMm.isEmpty) ? null : _pgTime(timeHhMm),
        "days_mask": daysMask,
        "is_enabled": enabled,
        "repeats_daily": repeatsDaily,
        "notes": notes,
      };
      if (id != null) {
        await _c.from("routines").update(row).eq("id", id);
      } else {
        await _c.from("routines").insert({...row, "id": _uuid.v4()});
      }
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteRoutine(String id) async {
    try {
      await _c.from("routines").delete().eq("id", id).eq("parent_id", _userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  /// Log completion / notification open (see `routine_logs` migration).
  Future<String?> insertRoutineLog({required String routineId, required String status}) async {
    try {
      final one = await _c.from("routines").select("child_profile_id").eq("id", routineId).single();
      final childPid = one["child_profile_id"] as String;
      final n = DateTime.now();
      final localDate = "${n.year.toString().padLeft(4, "0")}-${n.month.toString().padLeft(2, "0")}-${n.day.toString().padLeft(2, "0")}";
      await _c.from("routine_logs").insert({
        "routine_id": routineId,
        "child_profile_id": childPid,
        "log_date": localDate,
        "status": status,
      });
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  /// Called from local notification plugin when user interacts with a routine alert.
  Future<void> tryLogRoutineFromNotificationPayload(String? payload) async {
    try {
      if (payload == null || !payload.contains(":")) {
        return;
      }
      final i = payload.indexOf(":");
      if (i < 0 || i >= payload.length - 1) {
        return;
      }
      final routineId = payload.substring(i + 1);
      if (routineId.isEmpty) {
        return;
      }
      final err = await insertRoutineLog(routineId: routineId, status: "notified");
      if (err != null) {
        debugPrint("routine_logs: $err");
      }
    } catch (e) {
      debugPrint("routine_logs: $e");
    }
  }

  // ——— Geofence & parent alerts ———
  Future<String?> updateChildGeofence(
    String childId, {
    bool clear = false,
    double? centerLat,
    double? centerLng,
    double? radiusM,
    bool? enabled,
  }) async {
    try {
      if (clear) {
        await _c.from("child_profiles").update({
          "geofence_lat": null,
          "geofence_lng": null,
          "geofence_radius_m": null,
          "geofence_enabled": false,
        }).eq("id", childId).eq("parent_id", _userId);
        return null;
      }
      await _c
          .from("child_profiles")
          .update({
            "geofence_lat": centerLat,
            "geofence_lng": centerLng,
            "geofence_radius_m": radiusM,
            "geofence_enabled": enabled ?? true,
          })
          .eq("id", childId)
          .eq("parent_id", _userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<String?> insertParentAlert(
    String childId, {
    required String kind,
    required String body,
  }) async {
    try {
      await _c.from("parent_alerts").insert({
        "id": _uuid.v4(),
        "parent_id": _userId,
        "child_profile_id": childId,
        "kind": kind,
        "body": body,
        "read": false,
      });
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<List<ParentAlert>> listParentAlerts({int limit = 30}) async {
    final res = await _c
        .from("parent_alerts")
        .select()
        .eq("parent_id", _userId)
        .order("created_at", ascending: false)
        .limit(limit);
    return (res as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ParentAlert(
        id: m["id"] as String,
        parentId: m["parent_id"] as String,
        childProfileId: m["child_profile_id"] as String,
        kind: m["kind"] as String,
        body: m["body"] as String?,
        read: m["read"] as bool? ?? false,
        createdAt: DateTime.parse(m["created_at"] as String),
      );
    }).toList();
  }

  Future<int> parentUnreadAlertCount() async {
    final res = await _c
        .from("parent_alerts")
        .select("id")
        .eq("parent_id", _userId)
        .eq("read", false);
    return (res as List).length;
  }

  Future<String?> markAlertsRead(Iterable<String> ids) async {
    try {
      for (final id in ids) {
        await _c.from("parent_alerts").update({"read": true}).eq("id", id).eq("parent_id", _userId);
      }
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  /// The child row linked to the signed-in child account, or `null` if this user is a parent or not linked.
  Future<ChildProfile?> getLinkedChildProfile() async {
    final u = _c.auth.currentUser;
    if (u == null) {
      return null;
    }
    final res = await _c.from("child_profiles").select().eq("child_user_id", u.id).limit(1).maybeSingle();
    if (res == null) {
      return null;
    }
    return ChildProfile.fromMap(Map<String, dynamic>.from(res as Map));
  }

  /// Insert a parent-facing alert as the **linked child** (geofence exit from child device).
  Future<String?> insertParentAlertAsLinkedChild(
    ChildProfile child, {
    required String kind,
    required String body,
  }) async {
    try {
      await _c.from("parent_alerts").insert({
        "id": _uuid.v4(),
        "parent_id": child.parentId,
        "child_profile_id": child.id,
        "kind": kind,
        "body": body,
        "read": false,
      });
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Realtime: history for the map (newest first). Pairs with [subscribeLocationForChild] for double refresh.
  Stream<List<LocationPoint>> watchLocationPointsForChild(String childId) {
    return _c
        .from("location_points")
        .stream(primaryKey: const ["id"])
        .eq("child_profile_id", childId)
        .map((rows) {
      final out = (rows as List)
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return LocationPoint(
              id: m["id"] as int,
              childProfileId: m["child_profile_id"] as String,
              position: LatLng((m["lat"] as num).toDouble(), (m["lng"] as num).toDouble()),
              accuracyM: (m["accuracy_m"] as num?)?.toDouble(),
              recordedAt: DateTime.parse(m["recorded_at"] as String),
            );
          })
          .toList();
      out.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return out;
    });
  }

  /// Latest fix for the selected child — drives map marker updates over Realtime.
  Stream<LocationPoint?> watchLastKnownLocationForChild(String childId) {
    return watchLocationPointsForChild(childId).map((list) => list.isEmpty ? null : list.first);
  }

  /// Realtime: parent’s alert list (e.g. overview + FCM-prep pipeline).
  Stream<List<ParentAlert>> watchParentAlerts({int maxItems = 50}) {
    return _c
        .from("parent_alerts")
        .stream(primaryKey: const ["id"])
        .eq("parent_id", _userId)
        .map((rows) {
      final out = (rows as List)
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return ParentAlert(
              id: m["id"] as String,
              parentId: m["parent_id"] as String,
              childProfileId: m["child_profile_id"] as String,
              kind: m["kind"] as String,
              body: m["body"] as String?,
              read: m["read"] as bool? ?? false,
              createdAt: DateTime.parse(m["created_at"] as String),
            );
          })
          .toList();
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (out.length > maxItems) {
        return out.sublist(0, maxItems);
      }
      return out;
    });
  }

  /// Realtime: new [location_points] for [childId]. Unsubscribe: `returnedChannel.unsubscribe()`.
  RealtimeChannel subscribeLocationForChild(
    String childId,
    void Function(double lat, double lng) onPoint,
  ) {
    final ch = _c.channel("loc_${_userId.hashCode}_$childId");
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: "public",
      table: "location_points",
      callback: (ev) {
        final row = ev.newRecord;
        if (row["child_profile_id"] != childId) {
          return;
        }
        final la = row["lat"];
        final ln = row["lng"];
        if (la is num && ln is num) {
          onPoint(la.toDouble(), ln.toDouble());
        }
      },
    );
    ch.subscribe();
    return ch;
  }
}
