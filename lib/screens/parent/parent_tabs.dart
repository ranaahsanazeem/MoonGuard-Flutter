import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../../data/mg_models.dart";
import "../../services/auth_controller.dart";
import "tabs/chat/parent_chat_tab.dart";
import "tabs/map/parent_map_tab.dart";
import "tabs/parent_children_tab.dart";
import "tabs/parent_overview_tab.dart";
import "tabs/routines/parent_routines_tab.dart";
import "tabs/safety/parent_safety_tab.dart";
import "widgets/parent_header.dart";

class ParentTabs extends StatelessWidget {
  const ParentTabs({
    super.key,
    required this.index,
    required this.onIndex,
    required this.displayName,
    this.email,
    required this.children,
    required this.onDataChanged,
  });

  final int index;
  final ValueChanged<int> onIndex;
  final String displayName;
  final String? email;
  final List<ChildProfile> children;
  final Future<void> Function() onDataChanged;

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthController>();
    await auth.signOut();
    if (context.mounted) {
      context.go("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ParentHeader(
          name: displayName,
          onSignOut: () => _signOut(context),
        ),
        Expanded(
          child: _ParentTabContent(
            index: index,
            onGoto: onIndex,
            children: children,
            onRefresh: onDataChanged,
          ),
        ),
      ],
    );
  }
}

class _ParentTabContent extends StatelessWidget {
  const _ParentTabContent({
    required this.index,
    required this.onGoto,
    required this.children,
    required this.onRefresh,
  });
  final int index;
  final ValueChanged<int> onGoto;
  final List<ChildProfile> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return ParentOverviewTab(children: children, onGoto: onGoto, onRefresh: onRefresh);
      case 1:
        return ParentChildrenTab(children: children, onRefresh: onRefresh);
      case 2:
        return ParentMapTab(children: children, onRefresh: onRefresh);
      case 3:
        return ParentChatTab(children: children);
      case 4:
        return ParentSafetyTab(children: children);
      case 5:
        return ParentRoutinesTab(children: children);
      default:
        return const SizedBox.shrink();
    }
  }
}
