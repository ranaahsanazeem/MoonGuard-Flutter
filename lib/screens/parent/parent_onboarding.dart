// Parent onboarding (steps 1–5) — matches Expo (onboarding)/parent/step*.tsx
import "dart:io" show File;

import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:flutter/services.dart" show Clipboard, ClipboardData;
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../data/dial_codes.dart";
import "../../data/profile_model.dart" show generateParentKey;
import "../../data/profile_repo.dart";
import "../../services/auth_controller.dart";
import "../../theme/app_colors.dart";
import "../../widgets/onboarding_header.dart";

class ParentOnboardingPage extends StatelessWidget {
  const ParentOnboardingPage({super.key, required this.step});
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
              1 => const _P1(),
              2 => const _P2(2),
              3 => const _P3(3),
              4 => const _P4(4),
              5 => const _P5(5),
              _ => const _P1(),
            },
          ),
        ],
      ),
    );
  }
}

class _P1 extends StatefulWidget {
  const _P1();
  @override
  State<_P1> createState() => _P1State();
}

class _P1State extends State<_P1> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _cc = "+1";
  bool _open = false;
  String? _img;
  bool _saving = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    final u = Supabase.instance.client.auth.currentUser;
    final n = u?.userMetadata?["full_name"] as String? ?? u?.userMetadata?["name"] as String?;
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

  ImageProvider? _avatarProvider() {
    if (_img == null) return null;
    if (_img!.startsWith("http")) {
      return NetworkImage(_img!);
    }
    if (!kIsWeb) {
      return FileImage(File(_img!));
    }
    return null;
  }

  Widget? _avatarChild() {
    if (_img == null) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("📷", style: TextStyle(fontSize: 28)),
          Text("Add Photo", style: TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      );
    }
    if (!kIsWeb) return null;
    if (_img!.startsWith("http")) return null;
    return const Icon(Icons.image, size: 32, color: AppColors.muted);
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _img = x.path);
  }

  Future<void> _next() async {
    if (_name.text.trim().isEmpty) return;
    final id = context.read<AuthController>().user?.id;
    if (id == null) return;
    setState(() => _saving = true);
    final err = await _repo.upsertProfile(id, {
      "role": "parent",
      "name": _name.text.trim(),
      "phone": _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      "country_code": _cc,
      "image_url": _img,
      "onboarding_step": 2,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      context.read<AuthController>().refreshProfile();
      context.go("/onboarding/parent/2");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text("Basic Information", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const Text("Let's start with your profile details", style: TextStyle(color: AppColors.muted, fontSize: 15)),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _pick,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFF7F2EF),
                  backgroundImage: _avatarProvider(),
                  child: _avatarChild(),
                ),
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
        const Text("Full Name *", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: "Enter your full name")),
        const Text("Phone Number"),
        const SizedBox(height: 4),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _open = !_open),
              child: Text("$_cc ▾"),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: "Phone number"),
              ),
            ),
          ],
        ),
        if (_open)
          Card(
            child: Column(
              children: kDialOptions
                  .map(
                    (c) => ListTile(
                      title: Text(c.label),
                      onTap: () => setState(() {
                        _cc = c.dial;
                        _open = false;
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 20),
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _next,
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _P2 extends StatefulWidget {
  const _P2(this.step);
  final int step;
  @override
  State<_P2> createState() => _P2State();
}

class _P2State extends State<_P2> {
  final _sal = TextEditingController();
  final _loc = TextEditingController();
  final _addr = TextEditingController();
  bool _priv = false;
  bool _saving = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p == null || !mounted) return;
        if (p.salary == "private") {
          _priv = true;
        } else if (p.salary != null) {
          _sal.text = p.salary!;
        }
        if (p.location != null) _loc.text = p.location!;
        if (p.address != null) _addr.text = p.address!;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _sal.dispose();
    _loc.dispose();
    _addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: () => context.go("/onboarding/parent/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("Professional Info", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const Text("This information is kept private and secure", style: TextStyle(color: AppColors.muted, fontSize: 15)),
        const SizedBox(height: 20),
        const Text("Monthly Income", style: TextStyle(fontWeight: FontWeight.w600)),
        TextField(
          controller: _sal,
          enabled: !_priv,
          keyboardType: TextInputType.number,
        ),
        CheckboxListTile(
          value: _priv,
          onChanged: (v) => setState(() => _priv = v ?? false),
          title: const Text("Keep income private"),
        ),
        const Text("City / Location"),
        TextField(controller: _loc, textCapitalization: TextCapitalization.words),
        const Text("Home Address"),
        TextField(controller: _addr, maxLines: 3),
        const SizedBox(height: 20),
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: () async {
              final id = context.read<AuthController>().user?.id;
              if (id == null) return;
              setState(() => _saving = true);
              final err = await _repo.upsertProfile(id, {
                "salary": _priv ? "private" : (_sal.text.trim().isEmpty ? null : _sal.text.trim()),
                "location": _loc.text.trim().isEmpty ? null : _loc.text.trim(),
                "address": _addr.text.trim().isEmpty ? null : _addr.text.trim(),
                "onboarding_step": 3,
              });
              if (!mounted) return;
              setState(() => _saving = false);
              if (err == null) {
                context.read<AuthController>().refreshProfile();
                context.go("/onboarding/parent/3");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _P3 extends StatefulWidget {
  const _P3(this.step);
  final int step;
  @override
  State<_P3> createState() => _P3State();
}

class _P3State extends State<_P3> {
  final _f = TextEditingController();
  final _m = TextEditingController();
  final _en = TextEditingController();
  final _ep = TextEditingController();
  bool _saving = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p == null || !mounted) return;
        if (p.fatherName != null) _f.text = p.fatherName!;
        if (p.motherName != null) _m.text = p.motherName!;
        if (p.emergencyContact != null) {
          final part = p.emergencyContact!.split("|");
          if (part.isNotEmpty) _en.text = part[0];
          if (part.length > 1) _ep.text = part[1];
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _f.dispose();
    _m.dispose();
    _en.dispose();
    _ep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: () => context.go("/onboarding/parent/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("Guardian Details", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const Text("Family information for child safety and emergency contacts", style: TextStyle(color: AppColors.muted, fontSize: 15)),
        const Text("Father's Name"),
        TextField(controller: _f),
        const Text("Mother's Name"),
        TextField(controller: _m),
        const Text("Emergency name"),
        TextField(controller: _en),
        const Text("Emergency phone"),
        TextField(controller: _ep, keyboardType: TextInputType.phone),
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: () async {
              final id = context.read<AuthController>().user?.id;
              if (id == null) return;
              setState(() => _saving = true);
              String? em;
              if (_en.text.trim().isNotEmpty || _ep.text.trim().isNotEmpty) {
                em = "${_en.text.trim()}|${_ep.text.trim()}";
              }
              final err = await _repo.upsertProfile(id, {
                "father_name": _f.text.trim().isEmpty ? null : _f.text.trim(),
                "mother_name": _m.text.trim().isEmpty ? null : _m.text.trim(),
                "emergency_contact": em,
                "onboarding_step": 4,
              });
              if (!mounted) return;
              setState(() => _saving = false);
              if (err == null) {
                context.read<AuthController>().refreshProfile();
                context.go("/onboarding/parent/4");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _P4 extends StatefulWidget {
  const _P4(this.step);
  final int step;
  @override
  State<_P4> createState() => _P4State();
}

class _P4State extends State<_P4> {
  bool _lt = true, _aa = true, _sa = true, _sl = true;
  bool _saving = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p == null || !mounted) return;
        setState(() {
          _lt = p.locationTracking;
          _aa = p.activityAlerts;
          _sa = p.studyAlerts;
          _sl = p.sleepAlerts;
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
          onPressed: () => context.go("/onboarding/parent/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("Alerts & Permissions", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const Text("Choose what to monitor. You can change these anytime in settings.", style: TextStyle(color: AppColors.muted, fontSize: 15)),
        SwitchListTile(value: _lt, onChanged: (v) => setState(() => _lt = v), title: const Text("Location Tracking")),
        SwitchListTile(value: _aa, onChanged: (v) => setState(() => _aa = v), title: const Text("Activity Alerts")),
        SwitchListTile(value: _sa, onChanged: (v) => setState(() => _sa = v), title: const Text("Study Alerts")),
        SwitchListTile(value: _sl, onChanged: (v) => setState(() => _sl = v), title: const Text("Sleep Alerts")),
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: () async {
              final id = context.read<AuthController>().user?.id;
              if (id == null) return;
              setState(() => _saving = true);
              final err = await _repo.upsertProfile(id, {
                "location_tracking": _lt,
                "activity_alerts": _aa,
                "study_alerts": _sa,
                "sleep_alerts": _sl,
                "onboarding_step": 5,
              });
              if (!mounted) return;
              setState(() => _saving = false);
              if (err == null) {
                context.read<AuthController>().refreshProfile();
                context.go("/onboarding/parent/5");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text("Continue →"),
          ),
      ],
    );
  }
}

class _P5 extends StatefulWidget {
  const _P5(this.step);
  final int step;
  @override
  State<_P5> createState() => _P5State();
}

class _P5State extends State<_P5> {
  String _key = generateParentKey();
  bool _saving = false;
  final _repo = ProfileRepo(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _repo.getProfile(u.id).then((p) {
        if (p?.parentKey != null && p!.parentKey!.isNotEmpty) {
          if (mounted) setState(() => _key = p.parentKey!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final disp = _key.length == 8 ? "${_key.substring(0, 4)}-${_key.substring(4)}" : _key;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: () => context.go("/onboarding/parent/${widget.step - 1}"),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        const Text("Your Parent Key", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const Text("Share this key with your child to link their account to yours.", style: TextStyle(color: AppColors.muted, fontSize: 15)),
        const SizedBox(height: 16),
        Card(
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text("YOUR PARENT KEY", style: TextStyle(letterSpacing: 2, color: Colors.white70, fontSize: 11)),
                Text(
                  disp,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 6),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _key));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                      },
                      child: const Text("Copy", style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _key = generateParentKey()),
                      child: const Text("New Key", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: () async {
              final id = context.read<AuthController>().user?.id;
              if (id == null) return;
              setState(() => _saving = true);
              final err = await _repo.upsertProfile(id, {
                "parent_key": _key,
                "profile_completed": true,
                "onboarding_step": 5,
              });
              if (!mounted) return;
              setState(() => _saving = false);
              if (err == null) {
                context.read<AuthController>().refreshProfile();
                context.go("/home");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text("Complete Setup →"),
          ),
      ],
    );
  }
}
