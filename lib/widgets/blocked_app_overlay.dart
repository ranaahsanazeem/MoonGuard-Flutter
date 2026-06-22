import "package:flutter/material.dart";

import "../theme/app_colors.dart";

/// Flutter-level **simulation** of a blocked app screen. Real full-device blocking
/// needs an **Android Accessibility Service** (or Device Owner) in native code; rules
/// still come from `blocked_apps` in Supabase.
void showBlockedAppOverlay(
  BuildContext context, {
  required String packageName,
  String? label,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF1A0A18),
    pageBuilder: (ctx, _, __) {
      return _BlockedScaffold(packageName: packageName, label: label);
    },
  );
}

class _BlockedScaffold extends StatelessWidget {
  const _BlockedScaffold({required this.packageName, this.label});
  final String packageName;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF0211817),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text("App blocked", style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                label ?? packageName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                packageName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12, fontFamily: "monospace"),
              ),
              const SizedBox(height: 20),
              const Text(
                "This is an in-app preview. A production build uses native Android to block other apps.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Return"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
