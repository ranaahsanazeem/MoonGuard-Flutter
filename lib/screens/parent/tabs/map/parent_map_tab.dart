import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_map/flutter_map.dart";
import "package:geolocator/geolocator.dart";
import "package:intl/intl.dart";
import "package:latlong2/latlong.dart" show LatLng;
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";
import "../../../../services/geofence/geofence_alert_service.dart";
import "../../../../theme/app_colors.dart";
import "../../widgets/parent_empty_state.dart";
import "map_geofence_status.dart";

class ParentMapTab extends StatefulWidget {
  const ParentMapTab({super.key, required this.children, required this.onRefresh});
  final List<ChildProfile> children;
  final Future<void> Function() onRefresh;

  @override
  State<ParentMapTab> createState() => _ParentMapTabState();
}

class _ParentMapTabState extends State<ParentMapTab> {
  String? _cid;
  final _map = MapController();
  RealtimeChannel? _rt;
  StreamSubscription<LocationPoint?>? _lastLocSub;
  double _draftRadiusM = 300;
  DateTime? _lastOutsideAlert;
  int _rtGen = 0;

  ChildProfile? get _activeChild {
    if (_cid == null) {
      return null;
    }
    for (final c in widget.children) {
      if (c.id == _cid) {
        return c;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _cid = widget.children.first.id;
      final c0 = widget.children.first;
      if ((c0.geofenceRadiusM ?? 0) > 0) {
        _draftRadiusM = c0.geofenceRadiusM!.clamp(50, 20000);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _resubscribe());
  }

  @override
  void didUpdateWidget(covariant ParentMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.isNotEmpty && (_cid == null || !widget.children.any((c) => c.id == _cid))) {
      _cid = widget.children.first.id;
    }
    if (oldWidget.children != widget.children) {
      final ch = _activeChild;
      if (ch != null && (ch.geofenceRadiusM ?? 0) > 0) {
        _draftRadiusM = ch.geofenceRadiusM!.clamp(50, 20000);
      }
    }
  }

  @override
  void dispose() {
    _rt?.unsubscribe();
    _lastLocSub?.cancel();
    super.dispose();
  }

  void _resubscribe() {
    _rt?.unsubscribe();
    _rt = null;
    _lastLocSub?.cancel();
    _lastLocSub = null;
    if (_cid == null) {
      return;
    }
    final r = context.read<MoonGuardRepository>();
    _lastLocSub = r.watchLastKnownLocationForChild(_cid!).listen((pt) {
      if (!mounted || pt == null) {
        return;
      }
      setState(() => _rtGen++);
    });
    _rt = r.subscribeLocationForChild(
      _cid!,
      (la, ln) {
        if (!mounted) {
          return;
        }
        setState(() => _rtGen++);
        _onIncomingLocation(r, la, ln);
      },
    );
  }

  Future<void> _onIncomingLocation(MoonGuardRepository r, double lat, double lng) async {
    final ch = _activeChild;
    if (ch == null) {
      return;
    }
    final p = LatLng(lat, lng);
    final out = GeofenceAlertService.isOutsideSafeZone(ch, p);
    if (out) {
      if (!GeofenceAlertService.shouldEmitOutsideAlert(now: DateTime.now(), lastEmittedAt: _lastOutsideAlert)) {
        if (mounted) {
          setState(() {});
        }
        await widget.onRefresh();
        return;
      }
      _lastOutsideAlert = DateTime.now();
      final err = await r.insertParentAlert(
        ch.id,
        kind: "left_geofence",
        body: "${ch.name} left the safe zone (~${ch.geofenceRadiusM?.round() ?? 0} m).",
      );
      if (mounted) {
        if (err == null) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${ch.name} is outside the safe zone."),
              backgroundColor: const Color(0xFFB00020),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {});
        await widget.onRefresh();
      }
    } else {
      if (mounted) {
        setState(() {});
      }
      await widget.onRefresh();
    }
  }

  Future<void> _ping(MoonGuardRepository r) async {
    if (_cid == null) {
      return;
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Location demo: use Android / iOS build.")));
      return;
    }
    final s = await Geolocator.checkPermission();
    if (s == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    if (!context.mounted) {
      return;
    }
    final p = await Geolocator.getCurrentPosition();
    if (!context.mounted) {
      return;
    }
    final err = await r.addLocationPoint(_cid!, p.latitude, p.longitude, accuracyM: p.accuracy);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      _map.move(LatLng(p.latitude, p.longitude), 15);
      await widget.onRefresh();
      await _onIncomingLocation(r, p.latitude, p.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location sent (live to parent).")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    if (widget.children.isEmpty) {
      return const ParentEmptyState("Add a child to track location.", icon: Icons.map_outlined);
    }
    final ch = _activeChild;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButtonFormField<String>(
            initialValue: _cid,
            decoration: const InputDecoration(labelText: "Child", filled: true, fillColor: AppColors.card),
            items: [
              for (final c in widget.children)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                ),
            ],
            onChanged: (v) {
              setState(() {
                _cid = v;
                _lastOutsideAlert = null;
                for (final c in widget.children) {
                  if (c.id == v && (c.geofenceRadiusM ?? 0) > 0) {
                    _draftRadiusM = c.geofenceRadiusM!.clamp(50, 20000);
                    break;
                  }
                }
              });
              _resubscribe();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: MapGeofenceStatus(
            ch: ch,
            rtGen: _rtGen,
            repo: r,
            childId: _cid!,
            draftRadius: _draftRadiusM,
            onRadius: (d) => setState(() => _draftRadiusM = d),
            onSaveFromLast: (pts) async {
              if (pts.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Send a location first to set the center.")));
                return;
              }
              final p0 = pts.first.position;
              final e = await r.updateChildGeofence(
                _cid!,
                centerLat: p0.latitude,
                centerLng: p0.longitude,
                radiusM: _draftRadiusM,
                enabled: true,
              );
              if (e != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                }
                return;
              }
              if (mounted) {
                await widget.onRefresh();
                _map.move(p0, 14);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Safe zone saved. You’ll be alerted if they leave it.")),
                );
              }
            },
            onClear: () async {
              final e = await r.updateChildGeofence(_cid!, clear: true);
              if (e == null) {
                await widget.onRefresh();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
              }
            },
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _cid == null ? null : () => _ping(r),
            icon: const Icon(Icons.my_location, size: 20),
            label: const Text("Send this device’s location (child device demo)"),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: FutureBuilder<List<LocationPoint>>(
            key: ValueKey("$_cid-$_rtGen"),
            future: _cid == null ? Future.value(const []) : r.listRecentLocations(_cid!),
            builder: (context, snap) {
              if (_cid == null) {
                return const Center(child: Text("—"));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
              }
              final pts = snap.data!;
              final center = pts.isNotEmpty
                  ? pts.first.position
                  : const LatLng(20, 0);
              final c = ch;
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _map,
                      options: MapOptions(initialCenter: center, initialZoom: 13, minZoom: 2, maxZoom: 18),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: "com.example.moonguard",
                        ),
                        if (c != null && c.geofenceEnabled && c.geofenceLat != null && c.geofenceLng != null && (c.geofenceRadiusM ?? 0) > 0)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(c.geofenceLat!, c.geofenceLng!),
                                useRadiusInMeter: true,
                                radius: c.geofenceRadiusM!,
                                color: const Color(0x33228B22),
                                borderColor: const Color(0xFF228B22),
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        if (pts.isNotEmpty)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: pts.first.position,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_pin, size: 40, color: AppColors.primary),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: AppColors.card,
                        child: ListTile(
                          title: const Text("Recent (latest first) · real-time on new fixes", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          subtitle: Text(
                            pts.isEmpty
                                ? "No points yet — tap the button to send a fix."
                                : DateFormat("MMM d, HH:mm").format(pts.first.recordedAt),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
