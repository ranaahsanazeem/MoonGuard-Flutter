import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../../services/auth_controller.dart";
import "../../theme/app_colors.dart";
import "../../widgets/app_widgets.dart";

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key, required this.email});
  final String email;

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _c = TextEditingController();
  bool _loading = false;
  String? _error;
  int _resendCd = 60;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendCd > 0) {
        setState(() => _resendCd--);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _c.text.replaceAll(RegExp(r"\D"), "");
    if (code.length != 6) {
      setState(() => _error = "Please enter the 6-digit code.");
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final err = await context.read<AuthController>().verifyOtp(widget.email, code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.go("/home");
    }
  }

  Future<void> _onResend() async {
    if (_resendCd > 0) return;
    final err = await context.read<AuthController>().resendOtp(widget.email);
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() {
        _resendCd = 60;
        _error = null;
      });
      _tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text("Missing email. Go back to sign up.")),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const AmbientBlobs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.chevron_left, size: 20), Text("Back")],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Icon(Icons.verified_user, size: 44, color: AppColors.primary),
                  ),
                  const Text("Verify Your Email", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text("We sent a 6-digit code to\n${widget.email}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _c,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.w700),
                    onChanged: (_) => setState(() {
                      _error = null;
                    }),
                    onSubmitted: (_) => _verify(),
                    decoration: const InputDecoration(
                      counterText: "",
                      hintText: "000000",
                    ),
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
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
                  const SizedBox(height: 20),
                  if (_loading)
                    const LoadingPrimaryBar(label: "Verifying…")
                  else
                    PrimaryButton(
                      label: "Verify Code",
                      onPressed: _verify,
                      enabled: _c.text.replaceAll(RegExp(r"\D"), "").length == 6,
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Didn't receive it?", style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      TextButton(
                        onPressed: _resendCd > 0 ? null : _onResend,
                        child: Text(
                          _resendCd > 0 ? "Resend in ${_resendCd}s" : "Resend OTP",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
