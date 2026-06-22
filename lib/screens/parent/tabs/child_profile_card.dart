import "package:flutter/material.dart";

import "../../../data/mg_models.dart";
import "../../../theme/app_colors.dart";

class ChildProfileCard extends StatelessWidget {
  const ChildProfileCard({super.key, required this.child, required this.onDelete});
  final ChildProfile child;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF0E0DE),
          child: Text(
            child.name.isNotEmpty ? child.name[0].toUpperCase() : "?",
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [if (child.age != null) "Age ${child.age}", child.deviceLabel ?? "—"]
              .where((e) => e != "—" || child.deviceLabel == null)
              .join(" · "),
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.primary),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
