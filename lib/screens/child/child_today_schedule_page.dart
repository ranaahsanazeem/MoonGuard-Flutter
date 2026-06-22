import "package:flutter/material.dart";
import "package:get/get.dart";

import "../../theme/app_colors.dart";
import "child_routines_controller.dart";
import "child_today_schedule_section.dart";

/// Full-screen view of today's schedule (requires [ChildRoutinesController] from home).
class ChildTodaySchedulePage extends StatelessWidget {
  const ChildTodaySchedulePage({super.key, required this.childName});
  final String childName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        title: const Text("Today schedule"),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            "Upcoming routines sync from your parent. Alarms use this device’s local time.",
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          Get.isRegistered<ChildRoutinesController>(tag: kChildRoutinesControllerTag)
              ? ChildTodayScheduleSection(childName: childName)
              : const Text("Open this from the child home after your profile loads.", style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
