import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../../services/auth_controller.dart";
import "../../theme/app_colors.dart";
import "../../widgets/app_widgets.dart";
import "../../widgets/family_illustration.dart";
import "../../widgets/moon_wordmark.dart";

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.animation,
    this.dy = 18,
    required this.child,
  });

  final Animation<double> animation;
  final double dy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPw = false;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  bool _providerMismatch = false;

  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      if (auth.recoveryMode) {
        context.go("/update-password");
      } else if (auth.session != null) {
        context.go("/home");
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = "Please enter your email and password.");
      return;
    }
    setState(() {
      _error = null;
      _providerMismatch = false;
      _loading = true;
    });
    final auth = context.read<AuthController>();
    final r = await auth.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.error != null) {
      setState(() {
        _error = r.error;
        _providerMismatch = r.isProviderMismatch == true;
      });
    } else {
      context.go("/home");
    }
  }

  Future<void> _google() async {
    setState(() {
      _error = null;
      _googleLoading = true;
    });
    final err = await context.read<AuthController>().signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (err != null) setState(() => _error = err);
  }

  Animation<double> _seg(double begin, double end) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AmbientBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, 8, 22, 12 + viewPadding.bottom),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _IntroSlide(
                    animation: _seg(0, 0.24),
                    dy: 24,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x0FA41E22),
                          ),
                        ),
                        const Center(child: FamilyIllustration(scale: 0.7)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _IntroSlide(
                    animation: _seg(0.08, 0.32),
                    child: const MoonGuardWordmark(),
                  ),
                  const SizedBox(height: 20),
                  _IntroSlide(
                    animation: _seg(0.14, 0.5),
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Welcome Back",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const Text(
                            "Sign in to your account",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                          const SizedBox(height: 18),
                          if (_error != null) _errorBox(),
                          if (_error != null) const SizedBox(height: 2),
                          _field(
                            "Email address",
                            "your@email.com",
                            _email,
                            keyboardType: TextInputType.emailAddress,
                            autocapitalize: false,
                            icon: Icons.mail_outline,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            "Password",
                            "Password",
                            _password,
                            obscure: !_showPw,
                            icon: Icons.lock_outline,
                            trailing: IconButton(
                              onPressed: () => setState(() => _showPw = !_showPw),
                              icon: Icon(
                                _showPw ? Icons.visibility : Icons.visibility_off,
                                size: 20,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push("/forgot"),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(top: 2, bottom: 8),
                              ),
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (_loading)
                            const LoadingPrimaryBar(label: "Signing in…")
                          else
                            PrimaryButton(label: "Login", onPressed: _login),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _IntroSlide(
                    animation: _seg(0.4, 0.64),
                    child: TextButton(
                      onPressed: () => context.go("/signup"),
                      child: const Text.rich(
                        TextSpan(
                          text: "Don't have an account?  ",
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _IntroSlide(
                    animation: _seg(0.5, 0.74),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Divider(height: 1, color: Color(0xFFE0D6D0)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "OR",
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(height: 1, color: Color(0xFFE0D6D0)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _IntroSlide(
                    animation: _seg(0.55, 0.9),
                    child: _googleBlock(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleBlock() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: (_googleLoading || _loading) ? null : _google,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _providerMismatch
                  ? const Color(0xFF4285F4)
                  : const Color(0x12000000),
              width: _providerMismatch ? 2 : 1,
            ),
            boxShadow: _providerMismatch
                ? const [
                    BoxShadow(
                      color: Color(0x2E4285F4),
                      offset: Offset(0, 4),
                      blurRadius: 16,
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_googleLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const SimpleGoogleG(),
              const SizedBox(width: 10),
              Text(
                _googleLoading ? "Connecting…" : "Continue with Google",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox() {
    final hint = _providerMismatch;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, hint ? 10 : 10),
      decoration: BoxDecoration(
        color: hint ? const Color(0xFFFFF5F0) : const Color(0xFFFFF0F0),
        border: Border.all(
          color: hint ? const Color(0xFFF5C4A0) : AppColors.accent,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
                if (hint) ...[
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _googleLoading ? null : _google,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x14000000)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SimpleGoogleG(size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              "Sign in with Google →",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14A41E22),
            offset: Offset(0, 8),
            blurRadius: 28,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController c, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    bool autocapitalize = true,
    IconData icon = Icons.edit,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: autocapitalize ? TextCapitalization.sentences : TextCapitalization.none,
          autocorrect: false,
          onChanged: (_) {
            if (_error != null) {
              setState(() {
                _error = null;
                _providerMismatch = false;
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
            suffixIcon: trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
