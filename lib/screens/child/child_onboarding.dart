// Child onboarding steps 1–5 — matches Expo (onboarding)/child/step*.tsx
import "dart:io" show File;

import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../data/dial_codes.dart";
import "../../data/profile_model.dart";
import "../../data/profile_repo.dart";
import "../../services/auth_controller.dart";
import "../../theme/app_colors.dart";
import "../../widgets/onboarding_header.dart";

const _interests = [
  "🎮 Gaming",
  "🎵 Music",
  "📖 Reading",
  "⚽ Sports",
  "🎨 Art",
  "🔬 Science",
  "🍳 Cooking",
  "💃 Dancing",
  "🎬 Movies",
  "✈️ Travel",
  "🐾 Animals",
  "🌿 Nature",
];
const _langs = ["English", "Urdu", "Hindi", "Arabic", "Spanish", "French", "German", "Chinese"];
const _genders = ["Male", "Female", "Other", "Prefer not to say"];

String _fmtTime(String raw) {
  final d = raw.replaceAll(RegExp(r"[^0-9]"), "");
  if (d.length <= 2) {
    return d;
  }
  if (d.length >= 4) {
    return "${d.substring(0, 2)}:${d.substring(2, 4)}";
  }
  return "${d.substring(0, 2)}:${d.substring(2)}";
}

class ChildOnboardingPage extends StatelessWidget {
  const ChildOnboardingPage({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final s = step.clamp(1, 5);
    return Scaffold(
      body: Column(
        children: [
          OnboardingHeader(currentStep: s, total: 5),
          Expanded(
            child: switch (s) {
              1 => const _C1(1),
              2 => const _C2(2),
              3 => const _C3(3),
              4 => const _C4(4),
              5 => const _C5(5),
              _ => const _C1(1),
            },
          ),
        ],
      ),
    );
  }
}

class _C1 extends StatefulWidget {
  const _C1(this.step);
  final int step;
  @override
  State<_C1> createState() => _C1State();
}

class _C1State extends State<_C1> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _cc = "+1";
  bool _open = false;
  String? _img;
  bool _sav = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    final u = Supabase.instance.client.auth.currentUser;
    final n = u?.userMetadata?["full_name"] as String?;
    if (n != null) _name.text = n;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p == null || !mounted) return;
        if (p.name != null) _name.text = p.name!;
        if (p.phone != null) _phone.text = p.phone!;
        if (p.countryCode != null) _cc = p.countryCode!;
        if (p.imageUrl != null) _img = p.imageUrl;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  ImageProvider? _avP() {
    if (_img == null) return null;
    if (_img!.startsWith("http")) {
      return NetworkImage(_img!);
    }
    if (!kIsWeb) {
      return FileImage(File(_img!));
    }
    return null;
  }

  Widget? _avC() {
    if (_img == null) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text("📷", style: TextStyle(fontSize: 28)), Text("Add Photo", style: TextStyle(fontSize: 10, color: AppColors.muted))],
      );
    }
    if (!kIsWeb) return null;
    if (_img!.startsWith("http")) return null;
    return const Icon(Icons.image, size: 32, color: AppColors.muted);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text("Create Your Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const Text("Let's set up your MoonGuard profile 🌙", style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (x != null) {
                setState(() => _img = x.path);
              }
            },
            child: Stack(
              children: [
                CircleAvatar(radius: 50, backgroundColor: const Color(0xFFF7F2EF), backgroundImage: _avP(), child: _avC()),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Text("📷", style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text("Your Name *"),
        TextField(controller: _name, textCapitalization: TextCapitalization.words),
        const Text("Phone Number (Optional)"),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _open = !_open),
              child: Text("$_cc ▾"),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _phone, keyboardType: TextInputType.phone)),
          ],
        ),
        if (_open)
          Card(
            child: Column(
              children: kDialOptions
                  .map((c) => ListTile(
                        title: Text(c.label),
                        onTap: () => setState(() {
                          _cc = c.dial;
                          _open = false;
                        }),
                      ))
                  .toList(),
            ),
          ),
        if (_sav)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: _name.text.trim().isEmpty
                ? null
                : () async {
                    final id = context.read<AuthController>().user?.id;
                    if (id == null) return;
                    setState(() => _sav = true);
                    final e = await _repo.upsertProfile(id, {
                      "role": "child",
                      "name": _name.text.trim(),
                      "phone": _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                      "country_code": _cc,
                      "image_url": _img,
                      "onboarding_step": 2,
                    });
                    if (!mounted) return;
                    setState(() => _sav = false);
                    if (e == null) {
                      context.read<AuthController>().refreshProfile();
                      context.go("/onboarding/child/2");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                    }
                  },
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _C2 extends StatefulWidget {
  const _C2(this.step);
  final int step;
  @override
  State<_C2> createState() => _C2State();
}

class _C2State extends State<_C2> {
  final _age = TextEditingController();
  String _g = "";
  final _school = TextEditingController();
  final _grade = TextEditingController();
  var _i = <String>[];
  var _l = <String>[];
  bool _s = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p == null || !mounted) return;
        if (p.age != null) _age.text = "${p.age}";
        if (p.gender != null) _g = p.gender!;
        if (p.interests != null) _i = List.from(p.interests!);
        if (p.languages != null) _l = List.from(p.languages!);
        if (p.education?.school != null) _school.text = p.education!.school ?? "";
        if (p.education?.grade != null) _grade.text = p.education!.grade ?? "";
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _age.dispose();
    _school.dispose();
    _grade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: () => context.go("/onboarding/child/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("About You", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const Text("Tell us a bit more about yourself", style: TextStyle(color: AppColors.muted)),
        const Text("Age"),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
        ),
        const Text("Gender"),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _genders
              .map(
                (g) => FilterChip(
                  label: Text(g),
                  selected: _g == g,
                  onSelected: (_) => setState(() => _g = g),
                ),
              )
              .toList(),
        ),
        const Text("School"),
        TextField(controller: _school),
        const Text("Grade"),
        TextField(controller: _grade),
        const Text("Interests"),
        Wrap(
          spacing: 4,
          children: _interests
              .map(
                (x) => FilterChip(
                  label: Text(x, style: const TextStyle(fontSize: 12)),
                  selected: _i.contains(x),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _i = [..._i, x];
                    } else {
                      _i = _i.where((e) => e != x).toList();
                    }
                  }),
                ),
              )
              .toList(),
        ),
        const Text("Languages"),
        Wrap(
          spacing: 4,
          children: _langs
              .map(
                (g) => FilterChip(
                  label: Text(g, style: const TextStyle(fontSize: 12)),
                  selected: _l.contains(g),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _l = [..._l, g];
                    } else {
                      _l = _l.where((e) => e != g).toList();
                    }
                  }),
                ),
              )
              .toList(),
        ),
        if (_s)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: () async {
              final id = context.read<AuthController>().user?.id;
              if (id == null) return;
              setState(() => _s = true);
              final a = int.tryParse(_age.text);
              final e = await _repo.upsertProfile(id, {
                if (a != null) "age": a,
                "gender": _g.isEmpty ? null : _g,
                "interests": _i,
                "languages": _l,
                "education": {"school": _school.text.trim(), "grade": _grade.text.trim()},
                "onboarding_step": 3,
              });
              if (!mounted) return;
              setState(() => _s = false);
              if (e == null) {
                context.read<AuthController>().refreshProfile();
                context.go("/onboarding/child/3");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
              }
            },
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _C3 extends StatefulWidget {
  const _C3(this.step);
  final int step;
  @override
  State<_C3> createState() => _C3State();
}

class _C3State extends State<_C3> {
  final Map<String, TextEditingController> _t = {
    "breakfast": TextEditingController(),
    "study": TextEditingController(),
    "lunch": TextEditingController(),
    "play": TextEditingController(),
    "dinner": TextEditingController(),
    "sleep": TextEditingController(),
  };
  bool _s = false;
  final _repo = ProfileRepo(Supabase.instance.client);
  @override
  void dispose() {
    for (final c in _t.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p?.schedule == null || !mounted) return;
        final sc = p!.schedule!;
        if (sc.breakfast != null) _t["breakfast"]!.text = sc.breakfast!;
        if (sc.study != null) _t["study"]!.text = sc.study!;
        if (sc.lunch != null) _t["lunch"]!.text = sc.lunch!;
        if (sc.play != null) _t["play"]!.text = sc.play!;
        if (sc.dinner != null) _t["dinner"]!.text = sc.dinner!;
        if (sc.sleep != null) _t["sleep"]!.text = sc.sleep!;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = <Map<String, String>>[
      {"e": "🌅", "t": "Breakfast", "k": "breakfast", "h": "07:30"},
      {"e": "📚", "t": "Study", "k": "study", "h": "09:00"},
      {"e": "🍱", "t": "Lunch", "k": "lunch", "h": "13:00"},
      {"e": "⚽", "t": "Play", "k": "play", "h": "15:00"},
      {"e": "🍽️", "t": "Dinner", "k": "dinner", "h": "19:00"},
      {"e": "😴", "t": "Sleep", "k": "sleep", "h": "21:00"},
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: () => context.go("/onboarding/child/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("Daily Routine", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        for (final L in labels)
          ListTile(
            leading: Text(L["e"]!, style: const TextStyle(fontSize: 18)),
            title: Text(L["t"]!),
            trailing: SizedBox(
              width: 72,
              child: TextField(
                controller: _t[L["k"]!],
                onChanged: (v) {
                  final k0 = L["k"]!;
                  final f = _fmtTime(v);
                  if (_t[k0]!.text == f) return;
                  _t[k0]!.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
                  setState(() {});
                },
                maxLength: 5,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: L["h"],
                ),
              ),
            ),
          ),
        if (_s)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: () async {
              final id = context.read<AuthController>().user?.id;
              if (id == null) return;
              setState(() => _s = true);
              final sch = Schedule(
                breakfast: _t["breakfast"]!.text,
                study: _t["study"]!.text,
                lunch: _t["lunch"]!.text,
                play: _t["play"]!.text,
                dinner: _t["dinner"]!.text,
                sleep: _t["sleep"]!.text,
              );
              final e = await _repo.upsertProfile(id, {
                "schedule": sch.toJson(),
                "onboarding_step": 4,
              });
              if (!mounted) return;
              setState(() => _s = false);
              if (e == null) {
                context.read<AuthController>().refreshProfile();
                context.go("/onboarding/child/4");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
              }
            },
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _C4 extends StatefulWidget {
  const _C4(this.step);
  final int step;
  @override
  State<_C4> createState() => _C4State();
}

class _C4State extends State<_C4> {
  bool _a = true, _b = true, _c = true, _d = true;
  bool _s = false;
  final _repo = ProfileRepo(Supabase.instance.client);
  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p == null || !mounted) return;
        setState(() {
          _a = p.locationSharing;
          _b = p.learningReminders;
          _c = p.activityAlerts;
          _d = p.parentMonitoringAlerts;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: () => context.go("/onboarding/child/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("Permissions", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        SwitchListTile(value: _a, onChanged: (v) => setState(() => _a = v), title: const Text("Location Sharing")),
        SwitchListTile(value: _b, onChanged: (v) => setState(() => _b = v), title: const Text("Learning Reminders")),
        SwitchListTile(value: _c, onChanged: (v) => setState(() => _c = v), title: const Text("Activity Alerts")),
        SwitchListTile(value: _d, onChanged: (v) => setState(() => _d = v), title: const Text("Parent Monitoring")),
        if (_s)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: () async {
              final id = context.read<AuthController>().user?.id;
              if (id == null) return;
              setState(() => _s = true);
              final e = await _repo.upsertProfile(id, {
                "location_sharing": _a,
                "learning_reminders": _b,
                "activity_alerts": _c,
                "parent_monitoring_alerts": _d,
                "onboarding_step": 5,
              });
              if (!mounted) return;
              setState(() => _s = false);
              if (e == null) {
                context.read<AuthController>().refreshProfile();
                context.go("/onboarding/child/5");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
              }
            },
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _C5 extends StatefulWidget {
  const _C5(this.step);
  final int step;
  @override
  State<_C5> createState() => _C5State();
}

class _C5State extends State<_C5> {
  final _k = TextEditingController();
  String? _err;
  String? _parentId;
  var _st = 0; // 0 idle 1 find 2 ok
  bool _sav = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  String _format(String raw) {
    var u = raw.replaceAll(RegExp(r"[^A-Za-z0-9]"), "").toUpperCase();
    if (u.length > 8) u = u.substring(0, 8);
    return u;
  }

  @override
  void dispose() {
    _k.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: () => context.go("/onboarding/child/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("Link to Parent", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        TextField(
          controller: _k,
          onChanged: (v) {
            final f = _format(v);
            if (f == _k.text) return;
            _k.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
            setState(() {
              _st = 0;
              _err = null;
            });
          },
          decoration: const InputDecoration(labelText: "PARENT KEY", hintText: "AAAA-BBBB"),
        ),
        if (_err != null) Text(_err!, style: const TextStyle(color: AppColors.primary)),
        if (_st == 2) const Text("Key found — complete to link", style: TextStyle(color: Colors.green)),
        Row(
          children: [
            if (_st != 2)
              Expanded(
                child: FilledButton(
                  onPressed: _k.text.length < 8
                      ? null
                      : () async {
                          setState(() {
                            _st = 1;
                            _err = null;
                          });
                          final r = await _repo.findProfileIdByParentKey(_k.text);
                          if (!mounted) return;
                          if (r != null) {
                            setState(() {
                              _st = 2;
                              _parentId = r["id"];
                            });
                          } else {
                            setState(() {
                              _st = 0;
                              _err = "Key not found.";
                            });
                          }
                        },
                  child: const Text("Verify Key"),
                ),
              ),
            if (_st == 2)
              Expanded(
                child: FilledButton(
                  onPressed: _sav
                      ? null
                      : () async {
                          final u = context.read<AuthController>().user?.id;
                          if (u == null) return;
                          setState(() => _sav = true);
                          final e = await _repo.upsertProfile(u, {
                            "parent_id": _parentId,
                            "profile_completed": true,
                            "onboarding_step": 5,
                          });
                          if (!mounted) return;
                          setState(() => _sav = false);
                          if (e == null) {
                            context.read<AuthController>().refreshProfile();
                            context.go("/home");
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                          }
                        },
                  child: const Text("Complete →"),
                ),
              ),
          ],
        ),
        TextButton(
          onPressed: _sav
              ? null
              : () async {
                  final u = context.read<AuthController>().user?.id;
                  if (u == null) return;
                  setState(() => _sav = true);
                  final e = await _repo.upsertProfile(u, {
                    "profile_completed": true,
                    "onboarding_step": 5,
                  });
                  if (!mounted) return;
                  setState(() => _sav = false);
                  if (e == null) {
                    context.read<AuthController>().refreshProfile();
                    context.go("/home");
                  }
                },
          child: const Text("Skip for now →"),
        ),
      ],
    );
  }
}
