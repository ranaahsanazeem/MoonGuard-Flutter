import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";

import "../../data/mg_models.dart";
import "../../theme/app_colors.dart";
import "../../widgets/premium_routine_card.dart";
import "child_routines_controller.dart";
import "child_today_schedule_page.dart";

/// "Today" schedule: upcoming cards + next alarm (child device; [ChildRoutinesController] must be registered).
class ChildTodayScheduleSection extends StatelessWidget {
  const ChildTodayScheduleSection({super.key, required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          "Local alarms require Android or iOS (not web). Routines list still syncs from Supabase.",
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }
    final c = Get.find<ChildRoutinesController>(tag: kChildRoutinesControllerTag);
    return Obx(() {
      if (c.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.nextRoutineTitle.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Next: ${c.nextRoutineTitle.value} at ${c.nextRoutineTimeHhMm.value}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
            ),
          Material(
            color: const Color(0x0F000000),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.nextAlarmLabel.value,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final r in _upcomingToday(c.routines)) PremiumRoutineCard(routine: r),
          if (c.routines.isEmpty) const Text("No routines — your parent can add them in the parent app.", style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ChildTodaySchedulePage(childName: childName)),
                );
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text("Full today schedule"),
            ),
          ),
        ],
      );
    });
  }
}

List<Routine> _upcomingToday(List<Routine> all) {
  final now = DateTime.now();
  final withTime = <({Routine r, DateTime at})>[];
  for (final r in all) {
    if (!r.isEnabled) {
      continue;
    }
    final t = r.timeOfDay;
    if (t == null || t.isEmpty) {
      continue;
    }
    final p = t.split(":");
    if (p.length < 2) {
      continue;
    }
    final h = int.tryParse(p[0].trim()) ?? 0;
    final m = int.tryParse(p[1].trim()) ?? 0;
    var d = DateTime(now.year, now.month, now.day, h, m);
    if (d.isBefore(now)) {
      d = d.add(const Duration(days: 1));
    }
    withTime.add((r: r, at: d));
  }
  withTime.sort((a, b) => a.at.compareTo(b.at));
  return withTime.map((e) => e.r).toList();
}
