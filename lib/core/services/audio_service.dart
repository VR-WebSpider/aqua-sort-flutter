import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal() {
    _player.setSource(UrlSource(_pourUrl));
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();

  // Local asset paths for instant loading and offline support
  static const String _pourFile = 'audio/pouring.mp3';
  static const String _winFile  = 'audio/celebration.mp3';

  Future<void> playPour() async {
    try {
      await _player.setVolume(1.0);
      await _player.play(AssetSource(_pourFile));
      _triggerHaptic(HapticFeedback.lightImpact);
    } catch (e) {
      // Silence audio errors in production for better stability
    }
  }

  Future<void> stopPour() async {
    // Add a small delay for the 'tail' of the sound
    Future.delayed(const Duration(milliseconds: 150), () async {
      await _player.stop();
    });
  }

  Future<void> playWin() async {
    await _player.play(AssetSource(_winFile));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  Future<void> playClick() async {
    _triggerHaptic(HapticFeedback.selectionClick);
  }

  void _triggerHaptic(Future<void> Function() feedback) {
    feedback();
  }
}
