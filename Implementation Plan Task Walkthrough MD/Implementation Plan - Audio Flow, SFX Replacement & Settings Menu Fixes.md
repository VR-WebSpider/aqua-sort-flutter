# Implementation Plan - Audio Flow, SFX Replacement & Settings Menu Fixes

This plan outlines the changes to keep the ambient BGM running continuously, replace the synthesized lid closing sound with the new `Lid Closing SFX.mp3`, implement a haptic feedback sound using `Water Drip Click SFX.mp3`, and correct settings menu behaviors.

## User Review Required

> [!IMPORTANT]
> - **Continuous BGM**: Background music (BGM) will no longer stop upon level completion or navigation. It will run continuously at its correct volume levels (normal 0.40, ducked 0.12 during win/solve chimes).
> - **SFX Files**: We are switching:
>   - Lid Closing: `audio/lid_closing.wav` -> `audio/Lid Closing SFX.mp3`.
>   - Haptic Feedback / Click: Plays `audio/Water Drip Click SFX.mp3` along with physical haptic triggers.
> - **Settings Integration**: `AudioService` will honor the haptics preference (`haptics_enabled`), so toggling haptics in the settings menu will now actually enable/disable physical haptic feedback. Settings switches will play a clean response click.

## Proposed Changes

---

### 1. Core Services

#### [MODIFY] [audio_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/audio_service.dart)
- Define a private helper `_isHapticsEnabled()` to read preference from `SharedPreferences`.
- Guard all `HapticFeedback` triggers with `_isHapticsEnabled()` check.
- Update `playLidClosing()` to load `audio/Lid Closing SFX.mp3` and adjust the player cleanup delay to 1000ms.
- Update `playClick()` and `playTick()` to play `audio/Water Drip Click SFX.mp3` when sound effects are enabled, and respect the haptics enabled toggle.
- Modify `stopAll()` to stop `_sfxPlayer` but **NOT** `_bgmPlayer`, restoring the background music to full volume (0.40) if music is enabled.

---

### 2. Profile Providers

#### [MODIFY] [settings_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/providers/settings_provider.dart)
- Update setting toggle actions (`toggleMusic()`, `toggleSfx()`, `toggleHaptics()`) to trigger `AudioService.instance.playClick()` after updating SharedPreferences. This provides audial feedback on switch toggles.

---

## Verification Plan

### Automated Tests
- Run the Flutter application:
  ```powershell
  f:\.gemini\antigravity\scratch\flutter\bin\flutter.bat run -d windows
  ```

### Manual Verification
1. Play a level and complete it: verify that the ambient BGM does **NOT** stop, but ducks smoothly during the victory celebration and resumes.
2. Verify that the lid closing sound uses the wine bottle pressurized pop sound (`Lid Closing SFX.mp3`).
3. Verify that selecting tubes plays the new water drip click sound (`Water Drip Click SFX.mp3`).
4. Go to **Settings**:
   - Verify that toggling Background Music off/on stops and starts BGM.
   - Verify that toggling Sound Effects off silences the drip click sound and lid closing sound.
   - Verify that toggling settings switches plays a drip click sound (if SFX are enabled).
