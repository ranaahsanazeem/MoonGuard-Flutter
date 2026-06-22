import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../../services/auth_controller.dart";
import "../../theme/app_colors.dart";
import "../../widgets/app_widgets.dart";
import "../../widgets/moon_wordmark.dart";

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _p = TextEditingController();
  final _c = TextEditingController();
  bool _show1 = false;
  bool _show2 = false;
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _p.dispose();
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_p.text.length < 6) {
      setState(() => _error = "Password must be at least 6 characters.");
      return;
    }
    if (_p.text != _c.text) {
      setState(() => _error = "Passwords do not match.");
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final err = await context.read<AuthController>().updatePassword(_p.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() => _done = true);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) context.go("/login");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 40, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text("Password Updated!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text("Taking you to login…", textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const AmbientBlobs(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              children: [
                const Center(child: Icon(Icons.shield, size: 32, color: AppColors.primary)),
            const MoonGuardWordmark(),
            const SizedBox(height: 20),
            const Text("Set New Password", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Text("Choose a strong password for your account.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  border: Border.all(color: AppColors.accent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.primary, fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _p,
              obscureText: !_show1,
              decoration: InputDecoration(
                labelText: "New password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _show1 = !_show1),
                  icon: Icon(_show1 ? Icons.visibility : Icons.visibility_off, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _c,
              obscureText: !_show2,
              decoration: InputDecoration(
                labelText: "Confirm password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _show2 = !_show2),
                  icon: Icon(_show2 ? Icons.visibility : Icons.visibility_off, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const LoadingPrimaryBar(label: "Saving…")
            else
              PrimaryButton(label: "Update Password", onPressed: _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
