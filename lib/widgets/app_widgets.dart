import "package:flutter/material.dart";
import "package:moon_guard_flutter/theme/app_colors.dart";

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width crimson bar with spinner (matches Expo `loadingBtn` on auth screens).
class LoadingPrimaryBar extends StatelessWidget {
  const LoadingPrimaryBar({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleGoogleG extends StatelessWidget {
  const SimpleGoogleG({super.key, this.size = 18});
  final double size;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        child: Text(
          "G",
          style: TextStyle(
            fontSize: size * 0.85,
            color: const Color(0xFF4285F4),
            fontWeight: FontWeight.w700,
            fontFamily: "Roboto",
          ),
        ),
      ),
    );
  }
}

class AmbientBlobs extends StatelessWidget {
  const AmbientBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -60,
          right: -80,
          child: _Blob(300, Color(0x73FAD3CF)),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: _Blob(260, Color(0x4DE8C7A8)),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color);
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
