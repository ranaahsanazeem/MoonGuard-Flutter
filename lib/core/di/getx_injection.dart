import "package:get/get.dart";

import "../../data/moon_guard_repository.dart";

/// Registers [MoonGuardRepository] for [Get.find] (same instance as [Provider]).
void registerMoonGuardRepository(MoonGuardRepository repository) {
  if (!Get.isRegistered<MoonGuardRepository>()) {
    Get.put<MoonGuardRepository>(repository, permanent: true);
  }
}
