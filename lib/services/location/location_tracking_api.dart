/// Abstraction for GPS sampling (see [DefaultLocationTracking]).
/// A **Foreground Service** on Android is required for reliable 24/7 tracking;
/// this interface keeps UI/test code decoupled from that native implementation.
abstract class LocationTrackingApi {
  /// May throw if permission denied or on web.
  Future<({double lat, double lng, double? accuracyM})> getCurrentPoint();

  void dispose() {}
}
