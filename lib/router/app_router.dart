import "package:go_router/go_router.dart";
import "../config/env.dart";
import "../screens/auth/forgot_password_page.dart";
import "../screens/auth/login_page.dart";
import "../screens/auth/otp_verify_page.dart";
import "../screens/auth/setup_required_page.dart";
import "../screens/auth/signup_page.dart";
import "../screens/auth/update_password_page.dart";
import "../screens/child/child_onboarding.dart";
import "../screens/home_page.dart";
import "../screens/parent/parent_onboarding.dart";
import "../screens/not_found_page.dart";
import "../screens/splash_page.dart";
import "../services/auth_controller.dart";

GoRouter buildAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: "/",
    refreshListenable: auth,
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      if (!Env.hasAnonKey) {
        if (state.matchedLocation != "/setup") return "/setup";
        return null;
      }

      final loc = state.matchedLocation;
      if (auth.authLoading || (auth.session != null && auth.profileLoading)) {
        if (loc == "/") return null;
        return "/";
      }

      if (auth.recoveryMode) {
        if (loc != "/update-password") return "/update-password";
        return null;
      }

      if (auth.session == null) {
        if (loc == "/") {
          if (auth.splashTimerDone) return "/login";
          return null;
        }
        if (["/login", "/signup", "/forgot", "/setup", "/not-found"].contains(loc) || loc.startsWith("/otp")) {
          return null;
        }
        return "/login";
      }

      final p = auth.profile;
      if (p == null) {
        if (auth.session == null) return null;
        final metaRole = auth.user?.userMetadata?["role"] as String? ?? "parent";
        if (loc == "/") return null;
        final need = "/onboarding/$metaRole/1";
        if (loc != need) return need;
        return null;
      }

      if (!p.profileCompleted) {
        final role = p.role;
        var step = p.onboardingStep;
        if (step < 1) step = 1;
        if (step > 5) step = 5;
        final want = "/onboarding/$role/$step";
        if (loc != want) {
          return want;
        }
        return null;
      }

      if (loc == "/" ||
          loc == "/login" ||
          loc == "/signup" ||
          loc.startsWith("/otp") ||
          loc == "/forgot" ||
          loc == "/not-found" ||
          loc.startsWith("/onboarding/") ||
          loc == "/update-password") {
        if (loc == "/not-found") {
          return null;
        }
        return "/home";
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "/setup",
        builder: (context, state) => const SetupRequiredPage(),
      ),
      GoRoute(path: "/", builder: (context, state) => const SplashPage()),
      GoRoute(path: "/login", builder: (context, state) => const LoginPage()),
      GoRoute(path: "/signup", builder: (context, state) => const SignupPage()),
      GoRoute(
        path: "/otp",
        builder: (context, state) {
          final email = state.uri.queryParameters["email"] ?? "";
          return OtpVerifyPage(email: email);
        },
      ),
      GoRoute(
        path: "/forgot",
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: "/update-password",
        builder: (context, state) => const UpdatePasswordPage(),
      ),
      GoRoute(
        path: "/onboarding/parent/:step",
        builder: (context, state) {
          final s = int.tryParse(state.pathParameters["step"] ?? "") ?? 1;
          return ParentOnboardingPage(step: s);
        },
      ),
      GoRoute(
        path: "/onboarding/child/:step",
        builder: (context, state) {
          final s = int.tryParse(state.pathParameters["step"] ?? "") ?? 1;
          return ChildOnboardingPage(step: s);
        },
      ),
      GoRoute(
        path: "/home",
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: "/not-found",
        builder: (context, state) => const NotFoundPage(),
      ),
    ],
  );
}
