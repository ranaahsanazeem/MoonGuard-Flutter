import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:provider/provider.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";
import "../../../../theme/app_colors.dart";
import "../../../../widgets/parental_gate.dart";
import "../../../../widgets/premium_routine_card.dart";
import "../../widgets/parent_empty_state.dart";
import "routines_tab_controller.dart";

class ParentRoutinesTab extends StatefulWidget {
  const ParentRoutinesTab({super.key, required this.children});
  final List<ChildProfile> children;

  @override
  State<ParentRoutinesTab> createState() => _ParentRoutinesTabState();
}

class _ParentRoutinesTabState extends State<ParentRoutinesTab> {
  @override
  void initState() {
    super.initState();
    Get.put(
      RoutinesTabController(children: List.from(widget.children)),
      tag: kParentRoutinesControllerTag,
    );
  }

  @override
  void didUpdateWidget(covariant ParentRoutinesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    Get.find<RoutinesTabController>(tag: kParentRoutinesControllerTag).syncChildren(widget.children);
  }

  @override
  void dispose() {
    Get.delete<RoutinesTabController>(tag: kParentRoutinesControllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    if (widget.children.isEmpty) {
      return const ParentEmptyState("Add a child to set routines (prayer, sleep, reminders).", icon: Icons.schedule);
    }
    return GetBuilder<RoutinesTabController>(
      tag: kParentRoutinesControllerTag,
      builder: (c) {
        if (c.loadPending && c.childId != null) {
          // Realtime [watchRoutines] will populate; keep spinner until first event.
        }
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
              children: [
                if (c.loadPending) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                DropdownButtonFormField<String>(
                  value: c.childId,
                  decoration: const InputDecoration(labelText: "Child", filled: true, fillColor: AppColors.card),
                  items: [for (final ch in c.children) DropdownMenuItem(value: ch.id, child: Text(ch.name))],
                  onChanged: (v) {
                    c.setChild(v);
                  },
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text("Load Fajr–Isha from GPS (Aladhan)"),
                  onPressed: c.childId == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showSnackBar(const SnackBar(content: Text("Fetching location & prayer times…")));
                          final err = await c.syncPrayerTimesFromGps();
                          if (!context.mounted) {
                            return;
                          }
                          if (err != null) {
                            messenger.showSnackBar(SnackBar(content: Text(err)));
                          } else {
                            messenger.showSnackBar(const SnackBar(content: Text("Prayer routines updated for today’s location.")));
                          }
                        },
                ),
                const SizedBox(height: 8),
                for (final x in c.routines)
                  PremiumRoutineCard(
                    routine: x,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white70),
                      onPressed: () async {
                        if (!await confirmParentalPassword(context, title: "Delete routine")) {
                          return;
                        }
                        final e = await r.deleteRoutine(x.id);
                        if (e == null) {
                          await c.reload();
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                        }
                      },
                    ),
                  ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: c.childId == null ? null : () => c.addRoutine(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}
