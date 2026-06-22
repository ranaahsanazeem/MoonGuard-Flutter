import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:provider/provider.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";
import "../../../../theme/app_colors.dart";
import "../../../../widgets/parental_gate.dart";
import "../../widgets/parent_empty_state.dart";
import "safety_tab_controller.dart";

class ParentSafetyTab extends StatefulWidget {
  const ParentSafetyTab({super.key, required this.children});
  final List<ChildProfile> children;

  @override
  State<ParentSafetyTab> createState() => _ParentSafetyTabState();
}

class _ParentSafetyTabState extends State<ParentSafetyTab> {
  @override
  void initState() {
    super.initState();
    Get.put(
      SafetyTabController(children: List.from(widget.children)),
      tag: kParentSafetyControllerTag,
    );
  }

  @override
  void didUpdateWidget(covariant ParentSafetyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    Get.find<SafetyTabController>(tag: kParentSafetyControllerTag).syncChildren(widget.children);
  }

  @override
  void dispose() {
    Get.delete<SafetyTabController>(tag: kParentSafetyControllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    if (widget.children.isEmpty) {
      return const ParentEmptyState("Add a child, then set keywords and app rules per device.", icon: Icons.shield_outlined);
    }
    return GetBuilder<SafetyTabController>(
      tag: kParentSafetyControllerTag,
      builder: (c) {
        if (c.loadPending && c.childId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            c.reload();
          });
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            DropdownButtonFormField<String>(
              initialValue: c.childId,
              decoration: const InputDecoration(labelText: "For child", filled: true, fillColor: AppColors.card),
              items: [for (final ch in c.children) DropdownMenuItem(value: ch.id, child: Text(ch.name))],
              onChanged: (v) {
                c.setChild(v);
              },
            ),
            const SizedBox(height: 12),
            const Text("Blocked words", style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c.keywordField,
                    decoration: const InputDecoration(
                      hintText: "e.g. se",
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                    textCapitalization: TextCapitalization.none,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    if (c.keywordField.text.trim().isEmpty) {
                      return;
                    }
                    final e = await r.addKeyword(c.keywordField.text, childId: c.childId);
                    if (e != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                      }
                    } else {
                      c.keywordField.clear();
                      await c.reload();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
            for (final w in c.listKeywords) ...[
              ListTile(
                dense: true,
                title: Text(w.keyword),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                  onPressed: () async {
                    if (!await confirmParentalPassword(context, title: "Remove keyword")) {
                      return;
                    }
                    final e = await r.deleteKeyword(w.id);
                    if (e == null) {
                      await c.reload();
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text("Blocked app packages (manual lock / blur in agent)", style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            TextField(
              controller: c.packageField,
              decoration: const InputDecoration(
                labelText: "package name e.g. com.example.app",
                filled: true,
                fillColor: AppColors.card,
              ),
            ),
            TextField(
              controller: c.labelField,
              decoration: const InputDecoration(
                labelText: "label (optional)",
                filled: true,
                fillColor: AppColors.card,
              ),
            ),
            FilledButton(
              onPressed: c.childId == null
                  ? null
                  : () async {
                      if (!await confirmParentalPassword(context, title: "Add blocked app")) {
                        return;
                      }
                      if (c.packageField.text.trim().isEmpty) {
                        return;
                      }
                      final e = await r.addBlockedApp(
                        c.childId!,
                        packageName: c.packageField.text.trim(),
                        appLabel: c.labelField.text.isEmpty ? null : c.labelField.text,
                      );
                      if (e != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                        }
                      } else {
                        c.packageField.clear();
                        c.labelField.clear();
                        await c.reload();
                      }
                    },
              child: const Text("Block app"),
            ),
            for (final a in c.listApps) ...[
              ListTile(
                title: Text(a.packageName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.appLabel ?? a.packageName, style: const TextStyle(fontSize: 12)),
                    Text(
                      a.strictPin
                          ? "Strict lock: your PIN required on device to open (enforced by Android helper)."
                          : "Soft: warn only in Moon Guard; other apps need agent for hard lock.",
                      style: const TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Pin lock", style: TextStyle(fontSize: 9, color: AppColors.muted)),
                        Switch(
                          value: a.strictPin,
                          onChanged: (v) async {
                            final e = await r.setBlockedAppStrict(a.id, v);
                            if (e == null) {
                              await c.reload();
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                            }
                          },
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                      onPressed: () async {
                        if (!await confirmParentalPassword(context, title: "Unblock app")) {
                          return;
                        }
                        final e = await r.removeBlockedApp(a.id);
                        if (e == null) {
                          await c.reload();
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
