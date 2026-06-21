import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal() {
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // Local asset paths for instant loading and offline support
  static const String _pourFile = 'audio/pouring.mp3';
  static const String _winFile  = 'audio/celebration.mp3';
  static const String _bgmFile  = 'audio/Tides_in_the_Glass.mp3';

  int _activeSfxCount = 0;

  Future<bool> _isMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('music_enabled') ?? true;
  }

  Future<bool> _isSfxEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final sfx = prefs.getBool('sfx_enabled') ?? true;
    final muted = prefs.getBool('master_mute') ?? false;
    return sfx && !muted;
  }

  Future<bool> _isHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('haptics_enabled') ?? true;
  }

  Future<double> _getMusicVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('music_volume') ?? 1.0;
  }

  Future<bool> _isMuted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('master_mute') ?? false;
  }

  Future<void> updateBgmVolume() async {
    try {
      final double volumePref = await _getMusicVolume();
      final bool musicEnabled = await _isMusicEnabled();
      final bool muted = await _isMuted();

      double baseVolume = _activeSfxCount > 0 ? 0.12 : 0.40;
      double targetVolume = (musicEnabled && !muted) ? (baseVolume * volumePref) : 0.0;
      
      await _bgmPlayer.setVolume(targetVolume);
    } catch (_) {}
  }

  Future<void> _duckBgm() async {
    _activeSfxCount++;
    if (_activeSfxCount == 1) {
      await updateBgmVolume();
    }
  }

  Future<void> _unduckBgm() async {
    _activeSfxCount = (_activeSfxCount - 1).clamp(0, 99);
    if (_activeSfxCount == 0) {
      await updateBgmVolume();
    }
  }

  Future<void> playBgm(String? file) async {
    try {
      await updateBgmVolume();
      if (_bgmPlayer.state != PlayerState.playing) {
        await _bgmPlayer.play(AssetSource(file ?? _bgmFile));
      }
    } catch (e) {
      // Silence errors
    }
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.setVolume(0.0);
  }

  Future<void> playTubeClick() async {
    if (await _isHapticsEnabled()) {
      HapticFeedback.lightImpact();
    }
  }

  Future<AudioPlayer?> playPour() async {
    if (!(await _isSfxEnabled())) return null;
    try {
      final player = AudioPlayer();
      await player.setVolume(1.0);
      await player.play(AssetSource(_pourFile));
      if (await _isHapticsEnabled()) {
        HapticFeedback.lightImpact();
      }
      return player;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> stopPour(AudioPlayer? player) async {
    if (player == null) return;
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      await player.stop();
      await player.dispose();
    } catch (e) {}
  }

  Future<void> playMiniCelebration() async {
    if (!(await _isSfxEnabled())) return;
    await _duckBgm();
    try {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.95);
      await player.play(AssetSource('audio/mini_celebration.wav'));
      
      Future.delayed(const Duration(milliseconds: 1000), () async {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
          await _unduckBgm();
      });
    } catch (e) {
      await _unduckBgm();
    }
  }

  Future<void> playLidClosing() async {
    if (!(await _isSfxEnabled())) return;
    await _duckBgm();
    try {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.85);
      await player.play(AssetSource('audio/Lid Closing SFX.mp3'));
      
      Future.delayed(const Duration(milliseconds: 1000), () async {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
        await _unduckBgm();
      });
    } catch (e) {
      await _unduckBgm();
    }
  }

  Future<void> stopAll() async {
    await _sfxPlayer.stop();
    // Do NOT stop BGM player here, as ambient music must run continuously.
    // However, reset active SFX count and restore BGM volume if it was ducked.
    _activeSfxCount = 0;
    await updateBgmVolume();
  }
  
  Future<void> playTick() async {
    if (await _isSfxEnabled() && await _isHapticsEnabled()) {
      try {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0.35);
        await player.play(AssetSource('audio/Water Drip Click SFX.mp3'));
        Future.delayed(const Duration(milliseconds: 400), () async {
          try {
            await player.stop();
            await player.dispose();
          } catch (_) {}
        });
      } catch (_) {}
    }
    if (await _isHapticsEnabled()) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> playWin() async {
    if (!(await _isSfxEnabled())) return;
    await _duckBgm();
    try {
      await _sfxPlayer.play(AssetSource(_winFile));
      if (await _isHapticsEnabled()) {
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.mediumImpact());
      }
      
      Future.delayed(const Duration(milliseconds: 5000), () async {
        await _unduckBgm();
      });
    } catch (e) {
      await _unduckBgm();
    }
  }

  Future<void> playClick() async {
    if (await _isSfxEnabled() && await _isHapticsEnabled()) {
      try {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0.35);
        await player.play(AssetSource('audio/Water Drip Click SFX.mp3'));
        Future.delayed(const Duration(milliseconds: 400), () async {
          try {
            await player.stop();
            await player.dispose();
          } catch (_) {}
        });
      } catch (_) {}
    }
    if (await _isHapticsEnabled()) {
      HapticFeedback.lightImpact();
    }
  }
}
