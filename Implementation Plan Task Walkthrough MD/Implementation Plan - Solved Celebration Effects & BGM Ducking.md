# Implementation Plan - Solved Celebration Effects & BGM Ducking

This plan outlines the enhancements to add a metallic lid-closing animation, a custom visual particle burst effect, and custom sound effects when a tube is solved, as well as background music volume ducking.

## Proposed Changes

### 1. BGM Ducking and Dedicated SFX Players
We will update the audio service to track active sound effects and lower the background music (BGM) volume during gameplay when a sound effect plays, restoring it smoothly afterwards.

#### [MODIFY] [audio_service.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/audio_service.dart)
- Import `package:shared_preferences/shared_preferences.dart`.
- Track BGM volume state and duck BGM volume (from `0.40` down to `0.12`) when SFX are active.
- Define `playMiniCelebration()` and `playLidClosing()` to load and play the newly synthesized `mini_celebration.wav` and `lid_closing.wav` effects on independent players, automatically cleaning up resources and unducking BGM after playback.

---

### 2. Animated Lid Closing & Particle Burst Effects
When a tube is filled with a single color, we will trigger an animated cap drop and a gorgeous particle blast shooting out of the tube mouth.

#### [MODIFY] [tube_widget.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/tube_widget.dart)
- Create a new state variable `bool _showBurst` and a new `AnimationController _capCtrl` in `_TubeWidgetState` to drive the metallic lid-closing animation.
- Initialize `_capCtrl` to `1.0` if the tube starts in a solved state, and animate it from `0.0` to `1.0` when it becomes solved.
- Define the `_SolvedBurstEffect` stateful widget:
  - Spawns 18 particles (sparks, circular glows, and stars) that blast upwards from the mouth of the tube, rotate, slow down due to gravity, and fade away.
- Update `_TubePainter` to accept `capProgress` and slide/fade the cap into place.
- Hook into `_triggerSolvedEffect()` to:
  - Toggle `_showBurst = true` (resetting after 1.2 seconds).
  - Play the mini-celebration chime sound.
  - Delay the lid-closing metallic snap sound by 250ms to align with the cap animation completing.

---

## Verification Plan

### Manual Verification
1. Relaunch the application using `flutter run -d windows` in the local terminal.
2. Solve/fill any tube with a single color.
3. Verify that:
   - A beautiful chime arpeggio plays.
   - The BGM volume ducks smoothly while the chime and click play.
   - A metallic cap slides and fades onto the tube, accompanied by a satisfying clink sound.
   - A burst of glowing neon particles blasts upwards from the mouth of the tube, fading away elegantly.
