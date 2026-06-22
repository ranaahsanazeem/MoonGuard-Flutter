import "dart:async";

import "package:flutter/foundation.dart";
import "package:get/get.dart";

import "../../data/mg_models.dart";
import "../../data/moon_guard_repository.dart";
import "../../services/routines/routine_notification_service.dart";
import "../../utils/routine_time_utils.dart";

const String kChildRoutinesControllerTag = "childRoutines";

class ChildRoutinesController extends GetxController {
  ChildRoutinesController({required this.childId});

  final String childId;

  final routines = <Routine>[].obs;
  final loading = true.obs;
  final nextAlarmLabel = "Loading…".obs;
  final nextRoutineTitle = "".obs;
  final nextRoutineTimeHhMm = "".obs;

  MoonGuardRepository get _repo => Get.find<MoonGuardRepository>();
  StreamSubscription<List<Routine>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watchRoutines(childId).listen(
      (list) {
        routines.assignAll(list);
        loading.value = false;
        RoutineNotificationService.instance.rescheduleForChild(childId, list);
        _computeNextLabel(list);
      },
      onError: (Object e) {
        loading.value = false;
        nextAlarmLabel.value = "Could not load routines";
        debugPrint("watchRoutines: $e");
      },
    );
  }

  void _computeNextLabel(List<Routine> list) {
    final nextPrayer = RoutineTimeUtils.getNextPrayer(list);
    final nextAny = nextPrayer ?? RoutineTimeUtils.getNextScheduledRoutine(list);
    if (nextAny == null) {
      nextAlarmLabel.value = "No upcoming alarms";
      nextRoutineTitle.value = "";
      nextRoutineTimeHhMm.value = "";
      return;
    }
    final t = RoutineTimeUtils.parseTime(nextAny);
    if (t == null) {
      nextAlarmLabel.value = "No upcoming alarms";
      nextRoutineTitle.value = "";
      nextRoutineTimeHhMm.value = "";
      return;
    }
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (!at.isAfter(now)) {
      at = at.add(const Duration(days: 1));
    }
    final hh = at.hour.toString().padLeft(2, "0");
    final mm = at.minute.toString().padLeft(2, "0");
    final kind = _shortKind(nextAny.kind);
    final prefix = nextPrayer != null ? "Next prayer" : "Next";
    nextRoutineTitle.value = nextAny.title;
    nextRoutineTimeHhMm.value = "$hh:$mm";
    nextAlarmLabel.value = "$prefix · $kind · ${nextAny.title} · $hh:$mm";
  }

  String _shortKind(String k) {
    switch (k) {
      case "prayer":
        return "Prayer";
      case "sleep":
        return "Sleep";
      case "study":
        return "Study";
      case "reminder":
        return "Reminder";
      case "custom":
        return "Custom";
      default:
        return k;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
