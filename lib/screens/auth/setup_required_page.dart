import "package:flutter/material.dart";
import "package:moon_guard_flutter/theme/app_colors.dart";

class SetupRequiredPage extends StatelessWidget {
  const SetupRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key_off, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    "Supabase key required",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "The app is running without SUPABASE_ANON_KEY. Add your key the same way as EXPO_PUBLIC_SUPABASE_ANON_KEY in the Expo app.",
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Easiest: env.json in the moon_guard_flutter folder", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  const _Mono(
                    "1) Copy env.json.example → env.json\n"
                    "2) Put your anon key in the JSON (keep the file secret)\n"
                    "3) Run: flutter run -d chrome --dart-define-from-file=env.json\n"
                    "   Or:  .\\run_with_env.ps1 -d chrome  (or .\\run_with_env.bat -d chrome)",
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Android Studio", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  const _Mono(
                    "Run → Edit Configurations → your Flutter app →\n"
                    "Additional run args:\n"
                    "--dart-define-from-file=env.json",
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Working directory must be the moon_guard_flutter project folder (where env.json lives).",
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Supabase (for Google / web on localhost)", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  const _Mono(
                    "Add your exact app URL to:\n"
                    "Authentication → URL Configuration → Redirect URLs\n"
                    "Example: http://localhost:8080  (if you use run_web_local.ps1)\n"
                    "Use the same project anon key as EXPO_PUBLIC_SUPABASE_ANON_KEY.",
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("One line (any device)", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  const _Mono(
                    "flutter run --dart-define=SUPABASE_ANON_KEY=eyJ...",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mono extends StatelessWidget {
  const _Mono(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: const TextStyle(
        fontFamily: "monospace",
        fontSize: 12,
        height: 1.5,
        color: AppColors.text,
      ),
    );
  }
}
