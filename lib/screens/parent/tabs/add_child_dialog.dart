import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../data/moon_guard_repository.dart";
import "../../../theme/app_colors.dart";

Future<void> showAddChildDialog(
  BuildContext context, {
  required Future<void> Function() onDataChanged,
}) async {
  final r = context.read<MoonGuardRepository>();
  final n = TextEditingController();
  final a = TextEditingController();
  final d = TextEditingController();
  final y = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("New child profile"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: "Name *", filled: true)),
            const SizedBox(height: 8),
            TextField(
              controller: a,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Age (optional)", filled: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: d,
              decoration: const InputDecoration(labelText: "Device label (optional)", filled: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            if (n.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(ctx, true);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
  final name = n.text;
  final ageText = a.text;
  final deviceText = d.text;
  n.dispose();
  a.dispose();
  d.dispose();
  if (y != true || !context.mounted) {
    return;
  }
  int? ag;
  if (ageText.trim().isNotEmpty) {
    ag = int.tryParse(ageText.trim());
  }
  final res = await r.addChild(
    name: name,
    age: ag,
    deviceLabel: deviceText.isEmpty ? null : deviceText,
  );
  if (context.mounted) {
    if (res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error!)));
    } else {
      await onDataChanged();
    }
  }
}
