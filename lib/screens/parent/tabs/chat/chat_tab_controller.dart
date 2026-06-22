import "package:flutter/material.dart";
import "package:get/get.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";
import "../../../../widgets/chat_keyword_scrubber.dart";

const String kParentChatControllerTag = "parentChatTab";

class ChatTabController extends GetxController {
  ChatTabController({required this.children});
  List<ChildProfile> children;
  String? _cid;
  final messageController = TextEditingController();
  var keywords = <String>[].obs;

  String? get selectedChildId => _cid;
  bool get hasChildren => children.isNotEmpty;

  MoonGuardRepository get _repo => Get.find<MoonGuardRepository>();

  @override
  void onInit() {
    super.onInit();
    if (children.isNotEmpty) {
      _cid = children.first.id;
    }
    messageController.addListener(_scrubListen);
    Future.microtask(() async {
      await _loadKeywords();
      update();
    });
  }

  @override
  void onClose() {
    messageController.removeListener(_scrubListen);
    messageController.dispose();
    super.onClose();
  }

  void syncChildren(List<ChildProfile> list) {
    children = list;
    if (list.isNotEmpty && (_cid == null || !list.any((c) => c.id == _cid))) {
      _cid = list.first.id;
    }
    Future.microtask(() async {
      await _loadKeywords();
      update();
    });
  }

  Future<void> setChild(String? v) async {
    _cid = v;
    await _loadKeywords();
    update();
  }

  void _scrubListen() {
    if (keywords.isEmpty) {
      return;
    }
    final s = scrubChatText(messageController.text, keywords);
    if (s != messageController.text) {
      messageController.value = messageController.value.copyWith(
        text: s,
        selection: TextSelection.collapsed(offset: s.length),
      );
    }
  }

  Future<void> _loadKeywords() async {
    if (_cid == null) {
      return;
    }
    final a = await _repo.listKeywords();
    keywords.assignAll(
      a
          .where(
            (w) => w.isActive && (w.childProfileId == null || w.childProfileId == _cid),
          )
          .map((e) => e.keyword)
          .toList(),
    );
  }

  Future<void> sendMessage(BuildContext context) async {
    if (_cid == null) {
      return;
    }
    var text = messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    text = scrubChatText(text, keywords);
    if (text.isEmpty || RegExp(r"^\*+$").hasMatch(text)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Message has nothing safe to send after filtering.")),
        );
      }
      return;
    }
    final err = await _repo.sendTextMessage(_cid!, text);
    if (err == null) {
      messageController.clear();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
