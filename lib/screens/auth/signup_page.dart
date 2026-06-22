import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../../services/auth_controller.dart";
import "../../theme/app_colors.dart";
import "../../widgets/app_widgets.dart";
import "../../widgets/family_illustration.dart";
import "../../widgets/moon_wordmark.dart";

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({required this.animation, this.dy = 14, required this.child});

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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = "parent";
  bool _showPw = false;
  bool _showC = false;
  bool _agree = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthController>().session != null) {
        context.go("/home");
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Animation<double> _seg(double begin, double end) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = "Please enter your full name.");
      return;
    }
    if (_email.text.trim().isEmpty) {
      setState(() => _error = "Please enter your email.");
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = "Password must be at least 6 characters.");
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = "Passwords do not match.");
      return;
    }
    if (!_agree) {
      setState(() => _error = "Please agree to the Terms & Privacy Policy.");
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final a = context.read<AuthController>();
    final r = await a.signUp(
      _email.text.trim(),
      _password.text,
      _name.text.trim(),
      _role,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.error != null) {
      setState(() => _error = r.error);
    } else if (r.needsConfirmation) {
      context.push("/otp?email=${Uri.encodeComponent(_email.text.trim())}");
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

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const AmbientBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, 8, 22, 24 + viewPadding.bottom),
              child: Column(
                children: [
                  _IntroSlide(
                    animation: _seg(0, 0.2),
                    dy: 20,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x0FA41E22),
                          ),
                        ),
                        const Center(child: FamilyIllustration(scale: 0.62)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _IntroSlide(
                    animation: _seg(0.06, 0.28),
                    child: const MoonGuardWordmark(),
                  ),
                  const SizedBox(height: 16),
                  _IntroSlide(
                    animation: _seg(0.12, 0.5),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14A41E22),
                            offset: Offset(0, 8),
                            blurRadius: 28,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Create Account",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const Text(
                            "Join Moon Guard and protect your family",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          if (_error != null) _errorRow(),
                          if (_error != null) const SizedBox(height: 4),
                          const Text(
                            "I AM A",
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontSize: 10.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _roleCard("parent", "Parent", "Manage & protect", Icons.badge_outlined),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _roleCard("child", "Child", "Stay safe online", Icons.mood_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _t("Full name", "Full name", _name, false, Icons.person_outline),
                          _t("Email address", "Email address", _email, false, Icons.mail_outline, type: TextInputType.emailAddress),
                          _t("Password", "Password", _password, true, Icons.lock_outline, show: _showPw, onToggle: () => setState(() => _showPw = !_showPw)),
                          _t("Confirm password", "Confirm password", _confirm, true, Icons.lock_outline, show: _showC, onToggle: () => setState(() => _showC = !_showC)),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agree,
                                activeColor: AppColors.primary,
                                onChanged: (v) => setState(() {
                                  _agree = v ?? true;
                                  _error = null;
                                }),
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                      height: 1.45,
                                    ),
                                    children: const [
                                      TextSpan(text: "I agree to the "),
                                      TextSpan(
                                        text: "Terms",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      TextSpan(text: " & "),
                                      TextSpan(
                                        text: "Privacy Policy",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_loading)
                            const LoadingPrimaryBar(label: "Creating account…")
                          else
                            PrimaryButton(label: "Sign Up", onPressed: _submit, enabled: _agree),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _IntroSlide(
                    animation: _seg(0.5, 0.72),
                    child: TextButton(
                      onPressed: () => context.go("/login"),
                      child: const Text.rich(
                        TextSpan(
                          text: "Already have an account?  ",
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                          children: [
                            TextSpan(
                              text: "Sign In",
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
                    animation: _seg(0.55, 0.78),
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
                    animation: _seg(0.6, 0.92),
                    child: _googleButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        border: Border.all(color: AppColors.accent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard(String id, String t, String s, IconData icon) {
    final on = _role == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _role = id;
          _error = null;
        }),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFF5F5) : Colors.white,
            border: Border.all(
              color: on ? AppColors.primary : const Color(0x14000000),
              width: on ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x33A41E22),
                      offset: Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                if (on)
                  const Positioned(
                    top: 9,
                    right: 9,
                    child: _RoleDot(),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: on ? AppColors.primary : const Color(0xFFF7EDEA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: on ? Colors.white : AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: on ? AppColors.primary : AppColors.text,
                        ),
                      ),
                      Text(
                        s,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _t(
    String label,
    String hint,
    TextEditingController c,
    bool obscure,
    IconData i, {
    bool show = false,
    VoidCallback? onToggle,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: c,
            obscureText: obscure && !show,
            keyboardType: type,
            textCapitalization: type == TextInputType.emailAddress ? TextCapitalization.none : TextCapitalization.words,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(i, size: 20, color: AppColors.muted),
              suffixIcon: onToggle == null
                  ? null
                  : IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        show ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: (_googleLoading || _loading) ? null : _google,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x12000000)),
            boxShadow: const [
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
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleDot extends StatelessWidget {
  const _RoleDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
