import "package:flutter/material.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";
import "../../../../services/geofence_logic.dart";
import "../../../../theme/app_colors.dart";

class MapGeofenceStatus extends StatelessWidget {
  const MapGeofenceStatus({
    super.key,
    required this.ch,
    required this.rtGen,
    required this.repo,
    required this.childId,
    required this.draftRadius,
    required this.onRadius,
    required this.onSaveFromLast,
    required this.onClear,
  });
  final ChildProfile? ch;
  final int rtGen;
  final MoonGuardRepository repo;
  final String childId;
  final double draftRadius;
  final ValueChanged<double> onRadius;
  final void Function(List<LocationPoint> pts) onSaveFromLast;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      key: ValueKey("gf-$rtGen"),
      future: repo.listRecentLocations(childId, limit: 1),
      builder: (context, snap) {
        final pts = snap.data ?? <LocationPoint>[];
        if (ch == null) {
          return const SizedBox.shrink();
        }
        var inside = true;
        if (pts.isNotEmpty && (ch!.geofenceEnabled)) {
          inside = !isOutsideGeofence(
            p: pts.first.position,
            centerLat: ch!.geofenceLat,
            centerLng: ch!.geofenceLng,
            radiusM: ch!.geofenceRadiusM,
            enabled: ch!.geofenceEnabled,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: !ch!.geofenceEnabled
                    ? const Color(0xFFEEEEEE)
                    : (inside ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.ring),
              ),
              child: Text(
                !ch!.geofenceEnabled
                    ? "Safe zone: off — set radius and save using last position."
                    : (inside
                          ? "Inside safe zone (${ch!.geofenceRadiusM?.round() ?? 0} m)"
                          : "OUTSIDE safe zone — alert sent to you"),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: !ch!.geofenceEnabled
                      ? AppColors.muted
                      : (inside ? const Color(0xFF1B5E20) : const Color(0xFFB00020)),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text("Radius: ${draftRadius.round()} m", style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
                TextButton(
                  onPressed: () => onSaveFromLast(pts),
                  child: const Text("Save safe zone (center = last fix)"),
                ),
              ],
            ),
            Slider(
              value: draftRadius.clamp(50, 20000),
              min: 50,
              max: 20000,
              divisions: 40,
              label: "${draftRadius.round()} m",
              onChanged: onRadius,
            ),
            TextButton(
              onPressed: onClear,
              child: const Text("Clear safe zone", style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }
}
