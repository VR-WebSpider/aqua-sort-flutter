import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua_sort/core/services/audio_service.dart';

enum TouchSensitivity {
  standard,
  high,
  ultra;

  String get label {
    switch (this) {
      case TouchSensitivity.standard:
        return 'Standard (1.0x)';
      case TouchSensitivity.high:
        return 'High (1.5x)';
      case TouchSensitivity.ultra:
        return 'Ultra (2.0x)';
    }
  }

  String get description {
    switch (this) {
      case TouchSensitivity.standard:
        return 'Balanced touch zone for regular screen sizes.';
      case TouchSensitivity.high:
        return 'Expanded touch zone for fast tapping & smaller screens.';
      case TouchSensitivity.ultra:
        return 'Maximum hitbox for tablets, screen protectors & quick fingers.';
    }
  }

  double get horizontalPadding {
    switch (this) {
      case TouchSensitivity.standard:
        return 8.0;
      case TouchSensitivity.high:
        return 16.0;
      case TouchSensitivity.ultra:
        return 24.0;
    }
  }

  double get verticalPadding {
    switch (this) {
      case TouchSensitivity.standard:
        return 8.0;
      case TouchSensitivity.high:
        return 14.0;
      case TouchSensitivity.ultra:
        return 20.0;
    }
  }
}

class UserSettings {
  final bool musicEnabled;
  final bool sfxEnabled;
  final bool hapticsEnabled;
  final double musicVolume;
  final bool isMuted;
  final TouchSensitivity touchSensitivity;

  UserSettings({
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.hapticsEnabled = true,
    this.musicVolume = 1.0,
    this.isMuted = false,
    this.touchSensitivity = TouchSensitivity.high, // Defaulting to High for superior responsiveness out-of-the-box
  });

  UserSettings copyWith({
    bool? musicEnabled,
    bool? sfxEnabled,
    bool? hapticsEnabled,
    double? musicVolume,
    bool? isMuted,
    TouchSensitivity? touchSensitivity,
  }) {
    return UserSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      isMuted: isMuted ?? this.isMuted,
      touchSensitivity: touchSensitivity ?? this.touchSensitivity,
    );
  }
}

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(UserSettings()) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    final sensitivityStr = prefs.getString('touch_sensitivity');
    TouchSensitivity sensitivity = TouchSensitivity.high;
    if (sensitivityStr != null) {
      sensitivity = TouchSensitivity.values.firstWhere(
        (e) => e.name == sensitivityStr,
        orElse: () => TouchSensitivity.high,
      );
    }

    state = UserSettings(
      musicEnabled: prefs.getBool('music_enabled') ?? true,
      sfxEnabled: prefs.getBool('sfx_enabled') ?? true,
      hapticsEnabled: prefs.getBool('haptics_enabled') ?? true,
      musicVolume: prefs.getDouble('music_volume') ?? 1.0,
      isMuted: prefs.getBool('master_mute') ?? false,
      touchSensitivity: sensitivity,
    );
    _apply();
  }

  void _apply() {
    AudioService.instance.playBgm(null);
  }

  Future<void> setTouchSensitivity(TouchSensitivity sensitivity) async {
    state = state.copyWith(touchSensitivity: sensitivity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('touch_sensitivity', sensitivity.name);
    AudioService.instance.playClick();
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
