import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "package:get/get.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";
import "../../../../services/prayer/prayer_service.dart";

const String kParentRoutinesControllerTag = "parentRoutinesTab";

class RoutinesTabController extends GetxController {
  RoutinesTabController({required this.children});
  List<ChildProfile> children;

  String? _cid;
  String kind = "study";
  final titleField = TextEditingController();
  TimeOfDay time = const TimeOfDay(hour: 7, minute: 0);
  var loadPending = true;
  List<Routine> routines = [];

  String? get childId => _cid;

  MoonGuardRepository get _repo => Get.find<MoonGuardRepository>();
  StreamSubscription<List<Routine>>? _routinesSub;
  Timer? _dailyPrayerTimer;

  @override
  void onInit() {
    super.onInit();
    if (children.isNotEmpty) {
      _cid = children.first.id;
    }
    _bindStream();
    scheduleDailyPrayerSync();
  }

  /// Refreshes Aladhan times every local midnight (while this controller is alive).
  void scheduleDailyPrayerSync() {
    _dailyPrayerTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final duration = nextMidnight.difference(now);
    _dailyPrayerTimer = Timer(duration, () async {
      if (_cid != null) {
        try {
          final err = await syncPrayerTimesFromGps();
          if (err != null) {
            debugPrint("Midnight prayer sync: $err");
          }
        } catch (e) {
          debugPrint("Midnight prayer sync: $e");
        }
      }
      scheduleDailyPrayerSync();
    });
  }

  void _bindStream() {
    _routinesSub?.cancel();
    if (_cid == null) {
      routines = [];
      loadPending = false;
      update();
      return;
    }
    loadPending = true;
    update();
    _routinesSub = _repo.watchRoutines(_cid!).listen(
      (list) {
        routines = list;
        loadPending = false;
        update();
      },
      onError: (_) {
        loadPending = false;
        update();
      },
    );
  }

  @override
  void onClose() {
    _dailyPrayerTimer?.cancel();
    _routinesSub?.cancel();
    titleField.dispose();
    super.onClose();
  }

  void syncChildren(List<ChildProfile> list) {
    children = list;
    if (list.isNotEmpty) {
      _cid ??= list.first.id;
    }
    _bindStream();
    scheduleDailyPrayerSync();
  }

  void setChild(String? v) {
    _cid = v;
    _bindStream();
    scheduleDailyPrayerSync();
  }

  Future<void> reload() async {
    if (_cid == null) {
      return;
    }
    final l = await _repo.listRoutines(_cid!);
    routines = l;
    loadPending = false;
    update();
  }

  Future<void> addRoutine(BuildContext context) async {
    if (_cid == null) {
      return;
    }
    titleField.clear();
    var kindLocal = kind;
    var timeLocal = time;
    var repeatsDaily = true;
    if (!context.mounted) {
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return AlertDialog(
            title: const Text("Add routine"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Prayer presets (optional)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final name in const ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"])
                        ActionChip(
                          label: Text(name),
                          onPressed: () {
                            setS(() {
                              kindLocal = "prayer";
                              titleField.text = name;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleField,
                    decoration: const InputDecoration(
                      labelText: "Title *",
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: kindLocal,
                    decoration: const InputDecoration(labelText: "Type"),
                    items: const [
                      DropdownMenuItem(value: "prayer", child: Text("Prayer")),
                      DropdownMenuItem(value: "sleep", child: Text("Sleep")),
                      DropdownMenuItem(value: "study", child: Text("Study")),
                      DropdownMenuItem(value: "reminder", child: Text("Reminder")),
                      DropdownMenuItem(value: "custom", child: Text("Custom")),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setS(() => kindLocal = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Time", style: TextStyle(fontSize: 13)),
                    trailing: Text(
                      "${timeLocal.hour.toString().padLeft(2, "0")}:${timeLocal.minute.toString().padLeft(2, "0")}",
                    ),
                    onTap: () async {
                      final p = await showTimePicker(
                        context: ctx,
                        initialTime: timeLocal,
                      );
                      if (p != null) {
                        setS(() => timeLocal = p);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: repeatsDaily,
                    onChanged: (v) => setS(() => repeatsDaily = v),
                    title: const Text("Repeat daily", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Off = notify once at next time only", style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              FilledButton(
                onPressed: () {
                  if (titleField.text.trim().isEmpty) {
                    return;
                  }
                  kind = kindLocal;
                  time = timeLocal;
                  Navigator.pop(ctx, true);
                },
                child: const Text("Save to Supabase"),
              ),
            ],
          );
        },
      ),
    );
    if (go != true || !context.mounted) {
      return;
    }
    final hh = "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
    final e = await _repo.upsertRoutine(
      _cid!,
      kind: kind,
      title: titleField.text.trim(),
      timeHhMm: hh,
      repeatsDaily: repeatsDaily,
    );
    if (e == null) {
      await reload();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
    }
  }

  /// Fetches Aladhan timings for the parent device location and upserts 5 [prayer] rows for the selected child.
  Future<String?> syncPrayerTimesFromGps() async {
    final cid = _cid;
    if (cid == null) {
      return "No child selected";
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return "Location permission is required for automatic prayer times.";
    }
    final pos = await Geolocator.getCurrentPosition();
    final times = await PrayerService.getPrayerTimes(pos.latitude, pos.longitude);
    final existing = await _repo.listRoutines(cid);
    for (final e in times.entries) {
      String? id;
      for (final o in existing) {
        if (o.kind == "prayer" && o.title == e.key) {
          id = o.id;
          break;
        }
      }
      final err = await _repo.upsertRoutine(
        cid,
        id: id,
        kind: "prayer",
        title: e.key,
        timeHhMm: e.value,
        repeatsDaily: true,
      );
      if (err != null) {
        return err;
      }
    }
    await reload();
    return null;
  }
}