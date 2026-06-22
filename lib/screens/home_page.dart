import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../services/auth_controller.dart";
import "child/child_mode_home.dart";
import "parent/parent_home_shell.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final u = auth.user;
    final meta = u?.userMetadata;
    final fullName = (meta?["full_name"] as String?) ?? u?.email ?? "User";
    final fromProfile = auth.profile?.role;
    final fromMeta = meta?["role"] as String?;
    final role = (fromProfile ?? fromMeta ?? "parent").toLowerCase();

    if (role == "child") {
      return ChildModeHomePage(displayName: fullName);
    }
    return ParentHomeShell(
      displayName: fullName,
      email: u?.email,
    );
  }
}
