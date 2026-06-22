import "dart:math" as math;

import "package:flutter/material.dart";
import "package:moon_guard_flutter/theme/app_colors.dart";
import "package:moon_guard_flutter/widgets/family_illustration.dart";
import "package:moon_guard_flutter/widgets/moon_wordmark.dart";

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _dotPulse;

  @override
  void initState() {
    super.initState();
    _dotPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _dotPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            left: -96,
            top: 160,
            child: Container(
              width: 288,
              height: 288,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x64FAD3CF),
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: 460,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x4DE8C7A8),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: -40,
            child: _MoonBackdrop(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FamilyIllustration(),
                const SizedBox(height: 28),
                const MoonGuardWordmark(),
                const SizedBox(height: 12),
                Text(
                  "Protecting what matters most.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _dotPulse,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final phase = 2 * math.pi * _dotPulse.value + (i * 2 * math.pi / 3);
                    final op = 0.25 + 0.75 * ((math.sin(phase) + 1) / 2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: op,
                        child: const _Dot(),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MoonBackdrop extends StatefulWidget {
  @override
  State<_MoonBackdrop> createState() => _MoonBackdropState();
}

class _MoonBackdropState extends State<_MoonBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: c,
      child: SizedBox(
        width: 192,
        height: 192,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -48,
              left: -48,
              child: Container(
                width: 288,
                height: 288,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x2EE8B98A),
                ),
              ),
            ),
            Container(
              width: 192,
              height: 192,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8B98A),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x667A1417),
                    offset: Offset(-20, -10),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
