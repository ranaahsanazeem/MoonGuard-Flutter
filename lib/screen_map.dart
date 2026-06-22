/// Screen parity: `artifacts/moon-guard` (Expo) → `moon_guard_flutter/lib/...`
/// Reference Flutter UIs: `attached_assets/*.dart` (profile_setup, child_profile, etc. map to onboarding).
///
/// | Expo route | Flutter |
/// |------------|---------|
/// | app/index.tsx (splash) | [screens/splash_page.dart] SplashPage, `/` |
/// | app/login.tsx | [screens/auth/login_page.dart] LoginPage, `/login` |
/// | app/signup.tsx | [screens/auth/signup_page.dart] SignupPage, `/signup` |
/// | app/otp-verify.tsx | [screens/auth/otp_verify_page.dart] OtpVerifyPage, `/otp` |
/// | app/forgot-password.tsx | [screens/auth/forgot_password_page.dart] ForgotPasswordPage, `/forgot` |
/// | app/update-password.tsx | [screens/auth/update_password_page.dart] UpdatePasswordPage, `/update-password` |
/// | app/(onboarding)/parent/step1..5 | [screens/parent/parent_onboarding.dart] ParentOnboardingPage, `/onboarding/parent/:step` |
/// |   step1 = Basic info / photo (↔ profile_setup / parent step1) | _P1 |
/// |   step2 = Professional (↔ parent_details) | _P2 |
/// |   step3 = Guardian / emergency (↔ parent_details) | _P3 |
/// |   step4 = Alerts (↔ notification_preferences for parent) | _P4 |
/// |   step5 = Parent key (↔ family linking, parent) | _P5 |
/// | app/(onboarding)/child/step1..5 | [screens/child/child_onboarding.dart] ChildOnboardingPage, `/onboarding/child/:step` |
/// |   step1 = Child profile (↔ child_profile_setup) | _C1 |
/// |   step2 = Interests (↔ child_interests) | _C2 |
/// |   step3 = Daily routine (↔ daily_routine) | _C3 |
/// |   step4 = Permissions (↔ security_setup / notification) | _C4 |
/// |   step5 = Link parent key (↔ family_linking) | _C5 |
/// | app/(home)/index.tsx | [screens/home_page.dart] HomePage, `/home` |
/// | app/(onboarding)/_layout.tsx (gradient progress) | [widgets/onboarding_header.dart] OnboardingHeader |
/// | app/+not-found.tsx | [screens/not_found_page.dart] NotFoundPage, `/not-found` + errorBuilder |
/// | (missing key) | [screens/auth/setup_required_page.dart] SetupRequiredPage, `/setup` |
library;

// Intentionally no exports — documentation for developers.
