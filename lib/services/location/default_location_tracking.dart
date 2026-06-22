import "package:flutter/foundation.dart";
import "package:geolocator/geolocator.dart";
import "location_tracking_api.dart";

/// Default: Geolocator. For production, pair with a **foreground service** (native)
/// to keep the process eligible for background location on Android 10+.
class DefaultLocationTracking implements LocationTrackingApi {
  @override
  Future<({double lat, double lng, double? accuracyM})> getCurrentPoint() async {
    if (kIsWeb) {
      throw StateError("Location demo: use Android / iOS build.");
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever || p == LocationPermission.denied) {
      throw StateError("Location permission denied.");
    }
    final x = await Geolocator.getCurrentPosition();
    return (lat: x.latitude, lng: x.longitude, accuracyM: x.accuracy);
  }

  @override
  void dispose() {}
}

/// Placeholder for a future [MethodChannel] to Android `ForegroundService` + Fused location.
// ignore: avoid_classes_with_only_static_members
class ForegroundServiceLocationHint {
  /// Call native code to start/stop once Android `LocationForegroundService` exists.
  static Future<void> requestNativeForegroundHint() async {
    // android: not implemented; document in FCM / architecture notes.
  }
}
