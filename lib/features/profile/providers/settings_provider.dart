import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua_sort/core/services/audio_service.dart';

class UserSettings {
  final bool musicEnabled;
  final bool sfxEnabled;
  final bool hapticsEnabled;
  final double musicVolume;
  final bool isMuted;

  UserSettings({
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.hapticsEnabled = true,
    this.musicVolume = 1.0,
    this.isMuted = false,
  });

  UserSettings copyWith({
    bool? musicEnabled,
    bool? sfxEnabled,
    bool? hapticsEnabled,
    double? musicVolume,
    bool? isMuted,
  }) {
    return UserSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(UserSettings()) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = UserSettings(
      musicEnabled: prefs.getBool('music_enabled') ?? true,
      sfxEnabled: prefs.getBool('sfx_enabled') ?? true,
      hapticsEnabled: prefs.getBool('haptics_enabled') ?? true,
      musicVolume: prefs.getDouble('music_volume') ?? 1.0,
      isMuted: prefs.getBool('master_mute') ?? false,
    );
    _apply();
  }

  void _apply() {
    AudioService.instance.playBgm(null);
  }

  Future<void> toggleMusic() async {
    state = state.copyWith(musicEnabled: !state.musicEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', state.musicEnabled);
    _apply();
    AudioService.instance.playClick();
  }

  Future<void> toggleSfx() async {
    final oldSfx = state.sfxEnabled;
    state = state.copyWith(sfxEnabled: !state.sfxEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', state.sfxEnabled);
    if (state.sfxEnabled || oldSfx) {
      AudioService.instance.playClick();
    }
  }

  Future<void> toggleHaptics() async {
    state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', state.hapticsEnabled);
    AudioService.instance.playClick();
  }

  Future<void> setMusicVolume(double vol) async {
    state = state.copyWith(musicVolume: vol);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', vol);
    await AudioService.instance.updateBgmVolume();
  }

  Future<void> toggleMasterMute() async {
    state = state.copyWith(isMuted: !state.isMuted);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('master_mute', state.isMuted);
    await AudioService.instance.updateBgmVolume();
    
    // Play click sound if unmuted
    if (!state.isMuted) {
      await AudioService.instance.playClick();
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) => SettingsNotifier());
