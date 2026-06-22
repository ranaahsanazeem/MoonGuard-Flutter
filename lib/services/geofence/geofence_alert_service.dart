import "package:latlong2/latlong.dart" show LatLng;

import "../../data/mg_models.dart";
import "../geofence_logic.dart";

/// App-level geofence evaluation (server-side or native [GeofencingClient] is required
/// for OS-triggered events when the app is not running; see Android native module).
class GeofenceAlertService {
  const GeofenceAlertService._();

  /// `true` if the point is outside the active safe zone.
  static bool isOutsideSafeZone(ChildProfile child, LatLng p) {
    return isOutsideGeofence(
      p: p,
      centerLat: child.geofenceLat,
      centerLng: child.geofenceLng,
      radiusM: child.geofenceRadiusM,
      enabled: child.geofenceEnabled,
    );
  }

  /// Avoids duplicate [parent_alerts] spam (native layer should apply similar throttling).
  static bool shouldEmitOutsideAlert({
    required DateTime now,
    DateTime? lastEmittedAt,
    Duration minInterval = const Duration(minutes: 2),
  }) {
    if (lastEmittedAt == null) {
      return true;
    }
    return now.difference(lastEmittedAt) >= minInterval;
  }
}
