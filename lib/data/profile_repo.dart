import "package:supabase_flutter/supabase_flutter.dart";

import "profile_model.dart";

class ProfileRepo {
  final SupabaseClient _c;

  ProfileRepo(this._c);

  Future<Profile?> getProfile(String userId) async {
    final res = await _c.from("profiles").select().eq("id", userId).maybeSingle();
    if (res == null) return null;
    return Profile.fromRow(res);
  }

  /// Persists the FCM device token (Edge Function / backend will read it for push).
  Future<String?> setFcmToken(String userId, String? fcmToken) async {
    return upsertProfile(userId, {"fcm_token": fcmToken});
  }

  Future<String?> upsertProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _c.from("profiles").upsert({"id": userId, ...updates}, onConflict: "id");
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Resolves parent user id from link code. Uses secure RPC (see `supabase/migrations`).
  Future<Map<String, String>?> findProfileIdByParentKey(String key) async {
    final id = await _c.rpc<dynamic>("get_parent_id_by_key", params: {"pkey": key.trim()});
    if (id == null) return null;
    return {"id": id.toString()};
  }
}
