import "package:flutter/material.dart";

import "../../../theme/app_colors.dart";

class ParentEmptyState extends StatelessWidget {
  const ParentEmptyState(this.text, {super.key, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
