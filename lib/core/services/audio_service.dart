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
  static const String _pourFile = 'audio/tube_pour_liquid.wav';
  static const String _winFile  = 'audio/victory_fanfare_orchestral.wav';
  static const String _bgmFile  = 'audio/Tides_in_the_Glass.mp3';
  static const String _tapFile  = 'audio/water_drop_tap.wav';
  static const String _corkFile = 'audio/cork_snap_lock.wav';
  static const String _chimeFile= 'audio/solved_chime_sparkle.wav';
  static const String _coinFile = 'audio/coin_pickup.wav';
  static const String _undoFile = 'audio/undo_rewind_whoosh.wav';

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
    if (await _isSfxEnabled()) {
      try {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0.50);
        await player.play(AssetSource(_tapFile));
        Future.delayed(const Duration(milliseconds: 300), () async {
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

  Future<AudioPlayer?> playPour() async {
    if (!(await _isSfxEnabled())) return null;
    try {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.85);
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
      await player.play(AssetSource(_chimeFile));
      
      Future.delayed(const Duration(milliseconds: 1300), () async {
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
      await player.setVolume(0.90);
      await player.play(AssetSource(_corkFile));
      
      Future.delayed(const Duration(milliseconds: 600), () async {
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

  Future<void> playCoinReward() async {
    if (!(await _isSfxEnabled())) return;
    try {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.80);
      await player.play(AssetSource(_coinFile));
      if (await _isHapticsEnabled()) {
        HapticFeedback.mediumImpact();
      }
      Future.delayed(const Duration(milliseconds: 600), () async {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> playUndoWhoosh() async {
    if (!(await _isSfxEnabled())) return;
    try {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.75);
      await player.play(AssetSource(_undoFile));
      if (await _isHapticsEnabled()) {
        HapticFeedback.selectionClick();
      }
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> stopAll() async {
    await _sfxPlayer.stop();
    _activeSfxCount = 0;
    await updateBgmVolume();
  }
  
  Future<void> playTick() async {
    if (await _isSfxEnabled()) {
      try {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0.40);
        await player.play(AssetSource(_tapFile));
        Future.delayed(const Duration(milliseconds: 300), () async {
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
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 250), () => HapticFeedback.mediumImpact());
        Future.delayed(const Duration(milliseconds: 500), () => HapticFeedback.lightImpact());
      }
      
      Future.delayed(const Duration(milliseconds: 3000), () async {
        await _unduckBgm();
      });
    } catch (e) {
      await _unduckBgm();
    }
  }

  Future<void> playClick() async {
    if (await _isSfxEnabled()) {
      try {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0.45);
        await player.play(AssetSource(_tapFile));
        Future.delayed(const Duration(milliseconds: 300), () async {
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
