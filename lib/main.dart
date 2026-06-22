import "package:app_links/app_links.dart";
import "package:device_preview/device_preview.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:provider/provider.dart";
import "package:provider/single_child_widget.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "config/env.dart";
import "core/di/getx_injection.dart";
import "data/moon_guard_repository.dart";
import "firebase_options.dart";
import "router/app_router.dart";
import "screens/auth/setup_required_page.dart";
import "services/auth_controller.dart";
import "services/push/fcm_background.dart";
import "services/routines/routine_notification_service.dart";
import "theme/app_colors.dart";

/// Device frame (debug, desktop / simulator only). **Off on web** so localhost is a full-width PWA.
List<SingleChildWidget> _appProviders(AuthController auth) {
  return [
    ChangeNotifierProvider<AuthController>.value(value: auth),
    Provider<MoonGuardRepository>(
      create: (_) {
        final r = MoonGuardRepository(Supabase.instance.client);
        registerMoonGuardRepository(r);
        return r;
      },
    ),
  ];
}

bool get _kDevicePreview {
  if (kReleaseMode || kIsWeb) {
    return false;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => false,
    TargetPlatform.iOS => false,
    _ => true,
  };
}

ThemeData _appTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.bg,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0x12000000)),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.hasAnonKey) {
    if (_kDevicePreview) {
      runApp(
        DevicePreview(
          enabled: true,
          builder: (context) => MaterialApp(
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            theme: _appTheme(),
            home: const SetupRequiredPage(),
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
    } else {
      runApp(
        MaterialApp(
          theme: _appTheme(),
          home: const SetupRequiredPage(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }
    return;
  }

  await Env.initSupabase();

  if (!kIsWeb) {
    await RoutineNotificationService.instance.init();
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("Firebase init: $e");
    }
  }

  if (kIsWeb) {
    await _bootstrapWebAuthSession();
  } else {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) async {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint("Auth deep link: $e");
      }
    });
    final initial = await appLinks.getInitialLink();
    if (initial != null) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(initial);
      } catch (e) {
        debugPrint("Auth initial link: $e");
      }
    }
  }

  final auth = AuthController();
  final router = buildAppRouter(auth);

  if (_kDevicePreview) {
    runApp(
      DevicePreview(
        enabled: true,
        builder: (context) => MultiProvider(
          providers: _appProviders(auth),
          child: MaterialApp.router(
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            title: "Moon Guard",
            debugShowCheckedModeBanner: false,
            theme: _appTheme(),
            routerConfig: router,
          ),
        ),
      ),
    );
  } else {
    runApp(
      MultiProvider(
        providers: _appProviders(auth),
        child: MaterialApp.router(
          title: "Moon Guard",
          debugShowCheckedModeBanner: false,
          theme: _appTheme(),
          routerConfig: router,
        ),
      ),
    );
  }
}

/// After Google OAuth, Supabase returns to this tab with `?code=` (PKCE) or hash tokens.
Future<void> _bootstrapWebAuthSession() async {
  final u = Uri.base;
  if (!_isLikelySupabaseAuthCallback(u)) {
    return;
  }
  try {
    await Supabase.instance.client.auth.getSessionFromUrl(u);
  } catch (e) {
    debugPrint("Web OAuth callback: $e");
  }
}

bool _isLikelySupabaseAuthCallback(Uri u) {
  if (u.queryParameters.containsKey("code")) {
    return true;
  }
  final f = u.fragment;
  if (f.isEmpty) {
    return false;
  }
  return f.contains("access_token") || f.contains("code") || f.contains("error");
}
