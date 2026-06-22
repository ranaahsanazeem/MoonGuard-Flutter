import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../data/mg_models.dart";
import "../../../data/moon_guard_repository.dart";
import "../../../theme/app_colors.dart";

class ParentOverviewAlerts extends StatelessWidget {
  const ParentOverviewAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    return StreamBuilder<List<ParentAlert>>(
      stream: r.watchParentAlerts(maxItems: 5),
      builder: (context, snap) {
        if (snap.hasError) {
          return const SizedBox.shrink();
        }
        final all = snap.data;
        if (all == null || all.isEmpty) {
          return const SizedBox.shrink();
        }
        final list = all.take(5).toList();
        final unread = list.where((a) => !a.read).length;
        return Material(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () async {
              final readIds = list.where((e) => !e.read).map((e) => e.id).toList();
              if (readIds.isNotEmpty) {
                await r.markAlertsRead(readIds);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    unread == 0 ? Icons.notifications_outlined : Icons.warning_amber_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unread == 0 ? "Recent alerts" : "$unread new alert(s) — tap to mark read",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                        Text(
                          list.first.body ?? list.first.kind,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
