import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../data/profile_repo.dart";

class FcmReadiness {
  FcmReadiness._();

  /// Request notification permission, save token to `profiles.fcm_token`.
  /// Background handler is registered once in [main.dart] after [Firebase.initializeApp].
  static Future<void> registerAndSaveToken(ProfileRepo profiles) async {
    if (kIsWeb) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        debugPrint("FCM: Firebase not initialized, skip");
      }
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint("FCM permission: ${settings.authorizationStatus}");
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    String? token = await messaging.getToken();
    if (kDebugMode) {
      debugPrint("FCM token: $token");
    }

    if (token == null) {
      return;
    }
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) {
      return;
    }
    final err = await profiles.setFcmToken(u.id, token);
    if (err != null && kDebugMode) {
      debugPrint("FCM save to Supabase: $err");
    }

    messaging.onTokenRefresh.listen((t) async {
      final u2 = Supabase.instance.client.auth.currentUser;
      if (u2 != null) {
        await profiles.setFcmToken(u2.id, t);
      }
    });
  }
}
