import "package:flutter/material.dart";
import "package:moon_guard_flutter/theme/app_colors.dart";

/// Matches Expo `app/(onboarding)/_layout.tsx` (gradient bar + "n / 5" label).
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.currentStep, this.total = 5});

  final int currentStep;
  final int total;

  @override
  Widget build(BuildContext context) {
    final s = currentStep.clamp(1, total);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * s / total,
                            height: 6,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFD63031), AppColors.primary, AppColors.primaryDark],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "$s",
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
            ),
            Text(" / $total", style: TextStyle(color: AppColors.primary.withValues(alpha: 0.45), fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
