import "package:flutter/material.dart";
import "package:moon_guard_flutter/theme/app_colors.dart";

class MoonGuardWordmark extends StatelessWidget {
  const MoonGuardWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: const [
            Text(
              "MOON",
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.2,
              ),
            ),
            SizedBox(width: 6),
            Text(
              "GUARD",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.primary, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}
