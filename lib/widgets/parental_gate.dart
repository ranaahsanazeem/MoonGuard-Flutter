import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../services/auth_controller.dart";
import "../theme/app_colors.dart";

/// Confirms the signed-in user’s account password (parental gate per SRS).
Future<bool> confirmParentalPassword(
  BuildContext context, {
  String title = "Parental confirmation",
  String body = "Enter your account password to continue.",
}) async {
  final c = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(body, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: "Password", filled: true),
            onSubmitted: (_) => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text("Confirm"),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) {
    c.dispose();
    return false;
  }
  final auth = context.read<AuthController>();
  final p = c.text;
  c.dispose();
  if (p.isEmpty) {
    return false;
  }
  final v = await auth.verifyCurrentPassword(p);
  if (!v && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password did not match. Try again.")),
    );
  }
  return v;
}
