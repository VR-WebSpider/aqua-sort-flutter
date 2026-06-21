# Walkthrough - Expanding Volume Slider & Sound Controls

We have successfully implemented the expanding volume slider on the header speaker icon, added music volume storage, restricted tube clicks to physical haptics (no audio), and implemented master mute logic that silences all BGM and SFX.

## Changes Made

### 1. Expanding Volume Slider & Master Mute UI
- **VolumeControlWidget**: Replaced the static speaker button in `AquaHeader` in [aqua_widgets.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/auth/widgets/aqua_widgets.dart) with a premium custom `ConsumerStatefulWidget`.
  - **Slide Animation**: Uses a smooth 300ms transition to expand a volume slider (0 to 110px width) when clicked.
  - **Auto-Collapse**: Initiates a 3-second collapse timer of inactivity. Interacting with the slider (drag start, drag, drag release) resets the timer so it stays open during volume adjustment.
  - **Master Mute**: Tapping the speaker icon *while the slider is expanded* toggles master mute (muting/unmuting both BGM and SFX).
  - **Volume State**: Adjusting the slider immediately scales BGM volume and saves it to local settings. It also unmutes if it was muted.
  - **Volumetric Icon Representation**: Shows matching icons depending on status: `Icons.volume_off_rounded` (muted), `Icons.volume_mute_rounded` (0.0 volume), `Icons.volume_down_rounded` (volume < 0.5), or `Icons.volume_up_rounded` (volume >= 0.5).

### 2. Audio Service Improvements
- **Continuous Silent BGM**: Updated `playBgm()` and `stopBgm()` in [audio_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/audio_service.dart) to set the volume to `0.0` instead of calling `stop()` on the player when disabled/muted. BGM keeps running in the background and resumes seamlessly when unmuted without restarting from the beginning.
- **Drip Click SFX Muting**: Updated `_isSfxEnabled()` to return `false` if `master_mute` is active, seamlessly silencing all sound effects (clicks, pours, level completed sounds) while master mute is enabled.
- **Tube Clicks (No Audio)**: Added `playTubeClick()` which triggers physical haptic feedback (if enabled) without playing any SFX audio.

### 3. Settings Provider
- **UserSettings**: Added `musicVolume` (default `1.0`) and `isMuted` (default `false`) variables to [settings_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/providers/settings_provider.dart), storing them persistently using `SharedPreferences`.
- **Settings Actions**: Implemented `setMusicVolume(double)` and `toggleMasterMute()`.

### 4. Game Integration
- **Silent Tube Taps**: Updated `selectTube` in [game_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/providers/game_provider.dart) to trigger `playTubeClick()`, ensuring gameplay tube selection plays no audio click (only physical haptics) while navigation and menu buttons still play the drip click.

---

## Verification Plan

### How to Run and Test
1. Execute the following command to run the updated application:
   ```bash
   flutter run -d windows
   ```
2. Tap the speaker icon in the top header:
   - Verify that it slides open smoothly and shows a volume slider.
   - Verify that the slider collapses after 3 seconds of inactivity.
   - Verify that dragging the slider resets the 3-second timer and changes BGM volume.
3. Toggle Master Mute:
   - Expand the slider, then tap the speaker icon directly.
   - Verify that it toggles master mute (shows `volume_off` icon, silences all BGM and SFX).
   - Tap it again: verify it unmutes and BGM volume resumes continuously from where it was.
4. Test Tube Selection:
   - Tap a tube to select/deselect it. Verify that it plays **no audio** (only physical haptic vibration if supported).
5. Test Navigation and Settings:
   - Tapping settings switches, back buttons, or menus should play the drip click audio (when sound is enabled and unmuted).
