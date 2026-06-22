import "package:flutter/material.dart";

import "../../../theme/app_colors.dart";

class ParentHeader extends StatelessWidget {
  const ParentHeader({super.key, required this.name, required this.onSignOut});
  final String name;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Moon Guard",
                    style: TextStyle(color: AppColors.muted, fontSize: 12, letterSpacing: 0.2),
                  ),
                  Text(
                    name,
                    style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, color: AppColors.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
