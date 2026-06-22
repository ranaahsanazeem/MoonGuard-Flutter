import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../data/mg_models.dart";
import "../../../data/moon_guard_repository.dart";
import "../../../theme/app_colors.dart";
import "../../../widgets/parental_gate.dart";
import "../widgets/parent_empty_state.dart";
import "add_child_dialog.dart";
import "child_profile_card.dart";

class ParentChildrenTab extends StatelessWidget {
  const ParentChildrenTab({super.key, required this.children, required this.onRefresh});
  final List<ChildProfile> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
          children: [
            if (children.isEmpty)
              const ParentEmptyState("Add a child to enable map, chat, and routines.", icon: Icons.child_care),
            for (final c in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChildProfileCard(
                  child: c,
                  onDelete: () async {
                    if (!context.mounted) {
                      return;
                    }
                    final ok = await confirmParentalPassword(
                      context,
                      title: "Remove child",
                      body: "Deletes this child’s data (chat, locations, rules) in the cloud.",
                    );
                    if (!ok) {
                      return;
                    }
                    final err = await r.deleteChild(c.id);
                    if (context.mounted) {
                      if (err == null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text("Child profile removed.")));
                        await onRefresh();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      }
                    }
                  },
                ),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () => showAddChildDialog(context, onDataChanged: onRefresh),
            icon: const Icon(Icons.add),
            label: const Text("Add child"),
          ),
        ),
      ],
    );
  }
}
