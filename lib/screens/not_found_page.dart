import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../theme/app_colors.dart";

/// Parity with Expo `app/+not-found.tsx`.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Oops!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 8),
              const Text("This screen doesn't exist.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 16)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go("/"),
                child: const Text("Go to home", style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
