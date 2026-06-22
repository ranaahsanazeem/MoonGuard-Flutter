import "package:flutter/foundation.dart";

/// Replaces any blocked [keywords] in [text] with the same number of * characters.
String scrubChatText(String text, List<String> keywords) {
  if (text.isEmpty || keywords.isEmpty) {
    return text;
  }
  var out = text;
  for (final raw in keywords) {
    final k = raw.trim();
    if (k.isEmpty) {
      continue;
    }
    final re = RegExp(RegExp.escape(k), caseSensitive: false);
    out = out.replaceAllMapped(
      re,
      (m) {
        final s = m[0]!;
        return String.fromCharCodes(List.filled(s.length, 0x2A));
      },
    );
  }
  return out;
}

/// True if the message still contains a blocked word (after normalization for length-1 issues).
@visibleForTesting
bool hasBlockedSubstrings(String text, List<String> keywords) {
  final lower = text.toLowerCase();
  for (final raw in keywords) {
    final k = raw.trim().toLowerCase();
    if (k.isEmpty) {
      continue;
    }
    if (lower.contains(k)) {
      return true;
    }
  }
  return false;
}
