import "package:flutter/foundation.dart" show kIsWeb;
import "package:supabase_flutter/supabase_flutter.dart";

/// Supabase and OAuth. Keys: `--dart-define=SUPABASE_ANON_KEY=...` or
/// `flutter run --dart-define-from-file=env.json` (see env.json.example).
class Env {
  /// Override with `--dart-define=SUPABASE_URL=...` or add `SUPABASE_URL` in `env.json` for your project.
  static const String supabaseUrl = String.fromEnvironment(
    "SUPABASE_URL",
    defaultValue: "https://czwhvpdmegjdfdejpfmz.supabase.co",
  );

  static const String supabaseAnonKey = String.fromEnvironment("SUPABASE_ANON_KEY", defaultValue: "");

  /// Google / OAuth redirect.
  /// **Web (localhost):** current origin (e.g. `http://localhost:8080`). Add the same URL in
  /// Supabase → Authentication → URL Configuration → Redirect URLs.
  /// **Android:** custom scheme (see [AndroidManifest] intent-filter).
  static String get oauthRedirect {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return "com.moonguard.app://login-callback/";
  }

  /// Email password-reset link redirect (web only; optional on mobile).
  static String? get emailRedirectForPasswordReset {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return null;
  }

  static Future<void> initSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static bool get hasAnonKey => supabaseAnonKey.isNotEmpty;
}
