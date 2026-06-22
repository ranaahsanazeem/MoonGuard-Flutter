import "package:flutter/material.dart";
import "package:get/get.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";

const String kParentSafetyControllerTag = "parentSafetyTab";

class SafetyTabController extends GetxController {
  SafetyTabController({required this.children});
  List<ChildProfile> children;
  String? _cid;
  final keywordField = TextEditingController();
  final packageField = TextEditingController();
  final labelField = TextEditingController();
  var loadPending = true;
  List<BlockedKeyword> listKeywords = [];
  List<BlockedApp> listApps = [];

  String? get childId => _cid;

  MoonGuardRepository get _repo => Get.find<MoonGuardRepository>();

  @override
  void onInit() {
    super.onInit();
    if (children.isNotEmpty) {
      _cid = children.first.id;
    }
  }

  @override
  void onClose() {
    keywordField.dispose();
    packageField.dispose();
    labelField.dispose();
    super.onClose();
  }

  void syncChildren(List<ChildProfile> list) {
    children = list;
    if (list.isNotEmpty) {
      _cid ??= list.first.id;
    }
    loadPending = true;
    update();
  }

  void setChild(String? v) {
    _cid = v;
    loadPending = true;
    update();
  }

  Future<void> reload() async {
    if (_cid == null) {
      return;
    }
    final a = await _repo.listKeywords();
    final b = await _repo.listBlockedApps(_cid!);
    listKeywords = a.where((w) => w.childProfileId == null || w.childProfileId == _cid).toList();
    listApps = b;
    loadPending = false;
    update();
  }
}
