import "dart:async";

import "package:flutter/foundation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../config/env.dart";
import "../data/profile_model.dart";
import "../data/profile_repo.dart";

class _PendingSignup {
  final String password;
  final String name;
  final String role;
  _PendingSignup({required this.password, required this.name, required this.role});
}

class AuthController extends ChangeNotifier {
  AuthController() {
    _sub = _client.auth.onAuthStateChange.listen((data) {
      _onAuthEvent(data.event, data.session);
    });
  }

  final _client = Supabase.instance.client;
  late final StreamSubscription<AuthState> _sub;
  final _repo = ProfileRepo(Supabase.instance.client);

  _PendingSignup? _pendingSignup;
  bool _authLoading = true;
  bool _recoveryMode = false;
  Profile? _profile;
  bool _profileLoading = false;
  String? _loadToken;
  bool _splashTimerDone = false;
  bool _splashTimerScheduled = false;

  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;
  bool get authLoading => _authLoading;
  bool get recoveryMode => _recoveryMode;
  Profile? get profile => _profile;
  bool get profileLoading => _profileLoading;
  bool get splashTimerDone => _splashTimerDone;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _onAuthEvent(AuthChangeEvent event, Session? s) {
    if (event == AuthChangeEvent.passwordRecovery) {
      _recoveryMode = true;
    } else if (event == AuthChangeEvent.signedOut) {
      _recoveryMode = false;
      _profile = null;
      _loadToken = null;
      _splashTimerDone = false;
      _splashTimerScheduled = false;
    } else if (event == AuthChangeEvent.signedIn) {
      _recoveryMode = false;
    }

    if (event == AuthChangeEvent.signedIn && _pendingSignup != null) {
      final p = _pendingSignup!;
      _pendingSignup = null;
      unawaited(
        _client.auth.updateUser(
          UserAttributes(
            password: p.password,
            data: {"full_name": p.name, "role": p.role},
          ),
        ),
      );
    }

    if (s?.user != null) {
      _splashTimerDone = true;
      _splashTimerScheduled = true;
      unawaited(_loadProfile(s!.user.id));
    } else {
      _profile = null;
    }

    if (_authLoading) {
      _authLoading = false;
    }
    if (s?.user == null) {
      _startSplashOnce();
    }
    notifyListeners();
  }

  void _startSplashOnce() {
    if (_splashTimerScheduled) return;
    _splashTimerScheduled = true;
    Future.delayed(const Duration(milliseconds: 1800), () {
      _splashTimerDone = true;
      notifyListeners();
    });
  }

  Future<void> _loadProfile(String userId) async {
    final token = Object().hashCode.toString();
    _loadToken = token;
    _profileLoading = true;
    notifyListeners();
    final p = await _repo.getProfile(userId);
    if (_loadToken != token) return;
    _profile = p;
    _profileLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final id = user?.id;
    if (id == null) return;
    await _loadProfile(id);
  }

  Future<({String? error, bool? isProviderMismatch})> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      if (res.session != null) {
        return (error: null, isProviderMismatch: null);
      }
      return (error: "Sign in failed", isProviderMismatch: false);
    } on AuthException catch (e) {
      final msg = e.message;
      if (msg.toLowerCase().contains("email not confirmed")) {
        return (
          error: "Please verify your email first. Check your inbox for the confirmation link.",
          isProviderMismatch: null,
        );
      }
      if (msg.toLowerCase().contains("invalid") ||
          msg.toLowerCase().contains("credentials") ||
          (e.statusCode == "400" || e.statusCode == "401")) {
        return (
          error:
              'Incorrect email or password. If you signed up with Google, use "Continue with Google" below instead.',
          isProviderMismatch: true,
        );
      }
      return (error: msg, isProviderMismatch: null);
    }
  }

  Future<({String? error, bool needsConfirmation})> signUp(
    String email,
    String password,
    String fullName,
    String role,
  ) async {
    _pendingSignup = _PendingSignup(password: password, name: fullName, role: role);
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      return (error: null, needsConfirmation: true);
    } on AuthException catch (e) {
      _pendingSignup = null;
      return (error: e.message, needsConfirmation: false);
    }
  }

  Future<String?> resendOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email, shouldCreateUser: true);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> verifyOtp(String email, String token) async {
    try {
      final res = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      if (res.session == null) return "Verification failed";
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Re-check account password (parental actions: delete child, remove block, etc.).
  Future<bool> verifyCurrentPassword(String password) async {
    final email = user?.email;
    if (email == null || password.isEmpty) {
      return false;
    }
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      return res.session != null;
    } on AuthException {
      return false;
    }
  }

  Future<String?> signInWithGoogle() async {
    if (!Env.hasAnonKey) {
      return "Set SUPABASE_ANON_KEY (dart-define) to use sign-in.";
    }
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Env.oauthRedirect,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
