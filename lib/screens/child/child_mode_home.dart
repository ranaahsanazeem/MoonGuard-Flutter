import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../data/mg_models.dart";
import "../../data/moon_guard_repository.dart";
import "../../data/profile_repo.dart";
import "../../services/android/moonguard_android_bridge.dart";
import "../../services/auth_controller.dart";
import "../../services/location/child_location_session.dart";
import "../../services/location/default_location_tracking.dart";
import "../../services/push/fcm_readiness.dart";
import "../../theme/app_colors.dart";
import "../../widgets/blocked_app_overlay.dart";
import "child_family_chat.dart";
import "child_routines_host.dart";
import "child_today_schedule_section.dart";

/// Child home: real-time family chat, optional periodic location, blocked-app **preview**,
/// and routine visibility. System enforcement uses native Android; see in-code comments.
class ChildModeHomePage extends StatefulWidget {
  const ChildModeHomePage({super.key, required this.displayName});
  final String displayName;

  @override
  State<ChildModeHomePage> createState() => _ChildModeHomePageState();
}

class _ChildModeHomePageState extends State<ChildModeHomePage> {
  ChildLocationSession? _location;
  bool _tracking = true;
  bool _sessionStarted = false;
  /// Kotlin [LocationForegroundService] (continuous fused GPS) vs Dart periodic upload.
  bool _nativeForegroundLocation = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmReadiness.registerAndSaveToken(ProfileRepo(Supabase.instance.client));
      });
    }
  }

  @override
  void dispose() {
    _location?.dispose();
    super.dispose();
  }

  void _startLocation(MoonGuardRepository r) {
    _location?.dispose();
    if (!kIsWeb && _tracking) {
      _location = ChildLocationSession(
        r,
        DefaultLocationTracking(),
        interval: const Duration(seconds: 30),
      );
      _location!.start();
    }
  }

  void _onTrackingToggled(MoonGuardRepository r, bool v) {
    setState(() {
      _tracking = v;
      if (v) {
        _startLocation(r);
      } else {
        _location?.dispose();
        _location = null;
      }
    });
  }

  void _onNativeLocToggled(bool v) {
    setState(() => _nativeForegroundLocation = v);
    MoonguardAndroidBridge.setForegroundLocationEnabled(v);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        title: const Text("Moon Guard"),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) {
                context.go("/login");
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.primary),
          ),
        ],
      ),
      body: FutureBuilder<ChildProfile?>(
        future: r.getLinkedChildProfile(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
          }
          final profile = snap.data;
          if (profile == null) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                Text("Child account not linked to a child profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text(
                  "Ask your parent to link this account from the parent app (parent key or invite).",
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            );
          }

          if (_tracking && !kIsWeb && !_sessionStarted) {
            _sessionStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _startLocation(r);
                setState(() {});
              }
            });
          }

          return ChildRoutinesHost(
            childProfileId: profile.id,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
              const Text("Child mode", style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              Text("Hi, ${widget.displayName}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text("Linked: ${profile.name}", style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 20),
              _Section(
                title: "Location (Supabase + Realtime)",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Periodic GPS uploads every 30s when enabled. A production build should use an Android **foreground service** for reliable background tracking; WorkManager is for slower periodic sync.",
                      style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _tracking,
                      onChanged: kIsWeb
                          ? null
                          : (v) => _onTrackingToggled(r, v),
                      title: const Text("Send location to parent (demo interval)"),
                    ),
                    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _nativeForegroundLocation,
                        onChanged: (v) => _onNativeLocToggled(v),
                        title: const Text("Android: foreground location service (native)"),
                        subtitle: const Text("Uses fused GPS + visible notification. Turn off the Dart switch above to avoid double tracking."),
                      ),
                    if (kIsWeb) const Text("Location demo: use Android or iOS build.", style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: "App blocking (UI preview only)",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Native Android Accessibility Service (or DPC) is required to block other installed apps. "
                      "This screen only simulates a block overlay for packages your parent has restricted in Supabase.",
                      style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder(
                      future: r.listBlockedApps(profile.id),
                      builder: (context, a) {
                        if (a.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)));
                        }
                        final apps = a.data ?? <BlockedApp>[];
                        if (apps.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            MoonguardAndroidBridge.syncBlockedPackages(
                              apps.map((b) => b.packageName).toList(),
                            );
                          });
                        }
                        if (apps.isEmpty) {
                          return const Text("No blocked apps in Supabase for you.", style: TextStyle(color: AppColors.muted, fontSize: 12));
                        }
                        return Column(
                          children: [
                            for (final b in apps)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(b.appLabel ?? b.packageName),
                                subtitle: Text(b.packageName, style: const TextStyle(fontSize: 11, fontFamily: "monospace")),
                                trailing: FilledButton.tonal(
                                  onPressed: () => showBlockedAppOverlay(
                                    context,
                                    packageName: b.packageName,
                                    label: b.appLabel,
                                  ),
                                  child: const Text("Simulate open"),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: "Today schedule & alarms",
                child: ChildTodayScheduleSection(childName: profile.name),
              ),
              const SizedBox(height: 16),
              _Section(
                title: "Family chat (Realtime + keyword filter)",
                child: ChildFamilyChat(child: profile),
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
