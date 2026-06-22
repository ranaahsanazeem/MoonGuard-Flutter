import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../config/env.dart";
import "../../theme/app_colors.dart";
import "../../widgets/app_widgets.dart";

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = "Please enter your email address.");
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _email.text.trim(),
        redirectTo: kIsWeb ? Env.emailRedirectForPasswordReset : null,
      );
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const AmbientBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, size: 22, color: AppColors.text),
                        Text("Back", style: TextStyle(fontSize: 14, color: AppColors.text, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_open, size: 36, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Forgot Password?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const Text(
                    "Enter your email and we'll send you a reset link.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  if (_sent) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mail_outline, size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            const Text("Email Sent!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            const Text(
                              "Check your inbox for the password reset link.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              label: "Back to Login",
                              onPressed: () => context.go("/login"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 14),
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
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _error = null),
                      decoration: const InputDecoration(
                        labelText: "Email address",
                        hintText: "your@email.com",
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const LoadingPrimaryBar(label: "Sending…")
                    else
                      PrimaryButton(label: "Send Reset Link", onPressed: _send),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
