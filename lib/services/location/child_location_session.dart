import "dart:async";

import "package:flutter/foundation.dart";
import "package:latlong2/latlong.dart" show LatLng;

import "../../data/moon_guard_repository.dart";
import "../geofence/geofence_alert_service.dart";
import "location_tracking_api.dart";

/// Periodically uploads the device location to [location_points] and evaluates
/// the app-level geofence (native OS geofence is a separate integration).
class ChildLocationSession {
  ChildLocationSession(
    this._repo,
    this._api, {
    this.interval = const Duration(seconds: 30),
  });

  final MoonGuardRepository _repo;
  final LocationTrackingApi _api;
  final Duration interval;

  Timer? _t;
  DateTime? _lastOutsideAlert;

  /// Start periodic uploads (requires a linked [child_profiles] row for the current user).
  void start() {
    stop();
    if (kIsWeb) {
      return;
    }
    _t = Timer.periodic(interval, (_) => unawaited(_tick()));
    unawaited(_tick());
  }

  void stop() {
    _t?.cancel();
    _t = null;
  }

  void dispose() {
    stop();
    _api.dispose();
  }

  Future<void> _tick() async {
    if (kIsWeb) {
      return;
    }
    try {
      final child = await _repo.getLinkedChildProfile();
      if (child == null) {
        return;
      }
      final o = await _api.getCurrentPoint();
      final p = LatLng(o.lat, o.lng);
      final err = await _repo.addLocationPoint(child.id, p.latitude, p.longitude, accuracyM: o.accuracyM);
      if (err != null) {
        return;
      }
      if (!GeofenceAlertService.isOutsideSafeZone(child, p)) {
        return;
      }
      if (!GeofenceAlertService.shouldEmitOutsideAlert(now: DateTime.now(), lastEmittedAt: _lastOutsideAlert)) {
        return;
      }
      _lastOutsideAlert = DateTime.now();
      await _repo.insertParentAlertAsLinkedChild(
        child,
        kind: "left_geofence",
        body: "${child.name} left the safe zone (~${child.geofenceRadiusM?.round() ?? 0} m).",
      );
    } catch (_) {
      // Permission / hardware; no crash in child UI.
    }
  }
}
