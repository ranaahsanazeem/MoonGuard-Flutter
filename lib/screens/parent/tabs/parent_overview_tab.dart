import "package:flutter/material.dart";

import "../../../data/mg_models.dart";
import "../../../data/moon_guard_repository.dart" show kMaxChildProfiles;
import "../../../theme/app_colors.dart";
import "../widgets/parent_info_banner.dart";
import "../widgets/parent_kpi_card.dart";
import "parent_overview_alerts.dart";

class ParentOverviewTab extends StatelessWidget {
  const ParentOverviewTab({
    super.key,
    required this.children,
    required this.onGoto,
    required this.onRefresh,
  });
  final List<ChildProfile> children;
  final ValueChanged<int> onGoto;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const ParentInfoBanner(),
          const SizedBox(height: 8),
          const ParentOverviewAlerts(),
          const SizedBox(height: 8),
          ParentKpiCard("Children", "${children.length} / $kMaxChildProfiles", icon: Icons.people, onTap: () => onGoto(1)),
          const SizedBox(height: 8),
          ParentKpiCard("Map", "Location & history", icon: Icons.map, onTap: () => onGoto(2)),
          const SizedBox(height: 8),
          ParentKpiCard("Chat", "Text & media", icon: Icons.forum, onTap: () => onGoto(3)),
          const SizedBox(height: 8),
          ParentKpiCard("Safety", "Keywords & apps", icon: Icons.shield_outlined, onTap: () => onGoto(4)),
          const SizedBox(height: 8),
          ParentKpiCard("Routines", "Prayer, sleep, reminders", icon: Icons.schedule, onTap: () => onGoto(5)),
        ],
      ),
    );
  }
}
