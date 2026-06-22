import "package:flutter/material.dart";
import "package:get/get.dart";

import "child_routines_controller.dart";

/// Registers [ChildRoutinesController] for the linked child profile for the session.
class ChildRoutinesHost extends StatefulWidget {
  const ChildRoutinesHost({super.key, required this.childProfileId, required this.child});
  final String childProfileId;
  final Widget child;

  @override
  State<ChildRoutinesHost> createState() => _ChildRoutinesHostState();
}

class _ChildRoutinesHostState extends State<ChildRoutinesHost> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ChildRoutinesController>(tag: kChildRoutinesControllerTag)) {
      Get.put(
        ChildRoutinesController(childId: widget.childProfileId),
        tag: kChildRoutinesControllerTag,
        permanent: false,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ChildRoutinesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childProfileId != widget.childProfileId) {
      Get.delete<ChildRoutinesController>(tag: kChildRoutinesControllerTag);
      Get.put(
        ChildRoutinesController(childId: widget.childProfileId),
        tag: kChildRoutinesControllerTag,
        permanent: false,
      );
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<ChildRoutinesController>(tag: kChildRoutinesControllerTag)) {
      Get.delete<ChildRoutinesController>(tag: kChildRoutinesControllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
