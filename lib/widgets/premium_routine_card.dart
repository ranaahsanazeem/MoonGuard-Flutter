import "package:flutter/material.dart";

import "../data/mg_models.dart";
import "../utils/routine_time_utils.dart";

/// Shared gradient card for parent & child routine lists.
class PremiumRoutineCard extends StatelessWidget {
  const PremiumRoutineCard({
    super.key,
    required this.routine,
    this.trailing,
  });

  final Routine routine;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final time = _fmtTime(routine.timeOfDay);
    final missed = RoutineTimeUtils.isMissed(routine);
    final isPrayer = routine.kind == "prayer";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isPrayer ? Icons.mosque : Icons.alarm,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (missed) ...[
                  const SizedBox(height: 4),
                  const Text("Missed", style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 4),
                Text(
                  _cap(routine.kind),
                  style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                ),
                if (!routine.repeatsDaily) ...[
                  const SizedBox(height: 2),
                  const Text("Once only", style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
          Text(
            time,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  String _cap(String k) {
    if (k.isEmpty) {
      return k;
    }
    return "${k[0].toUpperCase()}${k.substring(1)}";
  }

  String _fmtTime(String? t) {
    if (t == null || t.isEmpty) {
      return "—";
    }
    return t.length >= 5 ? t.substring(0, 5) : t;
  }
}
