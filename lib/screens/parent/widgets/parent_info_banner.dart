import "package:flutter/material.dart";

import "../../../theme/app_colors.dart";

class ParentInfoBanner extends StatelessWidget {
  const ParentInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ring),
      ),
      child: const Text(
        "Blocking other apps on the child’s phone requires a small Android helper (Device Policy / Accessibility). "
        "This app syncs rules to Supabase; chat here uses instant word masking; family chat & map alerts work in real time.",
        style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
      ),
    );
  }
}
