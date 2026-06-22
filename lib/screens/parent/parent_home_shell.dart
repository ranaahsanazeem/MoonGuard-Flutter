import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../data/mg_models.dart";
import "../../data/moon_guard_repository.dart";
import "../../data/profile_repo.dart";
import "../../services/push/fcm_readiness.dart";
import "../../theme/app_colors.dart";
import "parent_tabs.dart";

/// Parent home: all SRS features (children, map, chat, safety, routines).
class ParentHomeShell extends StatefulWidget {
  const ParentHomeShell({super.key, required this.displayName, required this.email});
  final String displayName;
  final String? email;

  @override
  State<ParentHomeShell> createState() => _ParentHomeShellState();
}

class _ParentHomeShellState extends State<ParentHomeShell> {
  int _ix = 0;
  List<ChildProfile> _children = const [];
  String? _loadErr;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmReadiness.registerAndSaveToken(ProfileRepo(Supabase.instance.client));
      });
    }
  }

  Future<void> _load() async {
    final r = context.read<MoonGuardRepository>();
    setState(() {
      _loading = true;
      _loadErr = null;
    });
    try {
      final list = await r.listChildren();
      if (mounted) {
        setState(() {
          _children = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadErr = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          : _loadErr != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 40, color: AppColors.muted),
                    const SizedBox(height: 8),
                    Text("Could not load data.\n$_loadErr", textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text("Retry")),
                  ],
                ),
              ),
            )
          : ParentTabs(
              index: _ix,
              onIndex: (i) => setState(() => _ix = i),
              displayName: widget.displayName,
              email: widget.email,
              children: _children,
              onDataChanged: _load,
            ),
      bottomNavigationBar: _loadErr == null && !_loading
          ? _MoonNav(
              current: _ix,
              onTap: (i) => setState(() => _ix = i),
            )
          : null,
    );
  }
}

class _MoonNav extends StatelessWidget {
  const _MoonNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  static const _items = <({IconData i, String l})>[
    (i: Icons.grid_view_rounded, l: "Home"),
    (i: Icons.family_restroom, l: "Children"),
    (i: Icons.map, l: "Map"),
    (i: Icons.forum, l: "Chat"),
    (i: Icons.shield_outlined, l: "Safety"),
    (i: Icons.schedule, l: "Routines"),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: AppColors.card,
        elevation: 8,
        shadowColor: const Color(0x22000000),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (i) {
              final on = i == current;
              final c = on ? AppColors.primary : AppColors.muted;
              return InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: on ? const Color(0x14A41E22) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_items[i].i, size: 22, color: c),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _items[i].l,
                        style: TextStyle(fontSize: 9, color: c, fontWeight: on ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
