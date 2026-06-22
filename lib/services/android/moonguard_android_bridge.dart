import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

const String _kChannel = "com.example.moonguard/natives";

/// Bridges to Kotlin: blocked-app list, foreground location. No-ops on non-Android.
class MoonguardAndroidBridge {
  MoonguardAndroidBridge._();
  static const _channel = MethodChannel(_kChannel);

  /// Pushes the Supabase [blocked_apps] package names to [AppBlockerService] (Accessibility).
  static Future<void> syncBlockedPackages(List<String> packageNames) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<void>("setBlockedPackages", packageNames);
    } catch (e) {
      debugPrint("Native blocked list: $e");
    }
  }

  /// Start/stop [LocationForegroundService] (continuous fused GPS + notification).
  static Future<void> setForegroundLocationEnabled(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(
        "setForegroundLocation",
        <String, dynamic>{"enabled": enabled},
      );
    } catch (e) {
      debugPrint("Native foreground location: $e");
    }
  }
}
