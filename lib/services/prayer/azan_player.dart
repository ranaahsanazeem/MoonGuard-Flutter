import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";

/// Plays bundled [assets/audio/azan.mp3] (replace with your preferred adhan for production).
class AzanPlayer {
  AzanPlayer._();
  static final AzanPlayer instance = AzanPlayer._();

  final AudioPlayer _player = AudioPlayer();

  /// Fire-and-forget; safe if asset missing.
  Future<void> playAzan() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource("audio/azan.mp3"));
    } catch (e) {
      debugPrint("Azan play: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
