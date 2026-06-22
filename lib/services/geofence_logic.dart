import "package:latlong2/latlong.dart" show LatLng, Distance, LengthUnit;

/// Returns true if [p] is outside the circle, or if fence is misconfigured, false.
bool isOutsideGeofence({
  required LatLng p,
  double? centerLat,
  double? centerLng,
  double? radiusM,
  bool enabled = false,
}) {
  if (!enabled) {
    return false;
  }
  if (centerLat == null || centerLng == null) {
    return false;
  }
  final r = radiusM;
  if (r == null || r <= 0) {
    return false;
  }
  const d = Distance();
  final m = d.as(LengthUnit.Meter, p, LatLng(centerLat, centerLng));
  return m > r;
}
