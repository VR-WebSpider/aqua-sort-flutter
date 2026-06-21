# Implementation Plan - Empty Tube Repulsion Fix

This plan details the changes to ensure that the visual repulsion effect (impact shake and splash particles) shows correctly when liquid is poured into an empty destination tube.

## User Review Required

> [!IMPORTANT]
> The changes affect liquid stream length, splash particle positioning, and empty tube impact physical shudder. No breaking changes or game logic modifications are introduced.

## Proposed Changes

---

### 1. Game Widgets

#### [MODIFY] [tube_widget.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/tube_widget.dart)
- Update `didUpdateWidget` to:
  1. Trigger a physical shudder (`_shakeCtrl.forward(from: 0.0)`) when the tube starts receiving liquid (`widget.isReceiving && !old.isReceiving`).
  2. Prevent the wobble animation controller (`_wobbleCtrl`) from being reset on every frame during active pours. Check color list elements for actual changes and only wobble when the tube is NOT receiving liquid, or when receiving stops.

#### [MODIFY] [pouring_animation_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/pouring_animation_overlay.dart)
- In `_buildStream`, adjust the bottom clamp limit for the stream endpoint (`destY`) from `h - 10.0` to `h - 3.0` (which is `127.0` relative to the tube top). This extends the stream and splash particles to touch the bottom tip of the empty tube instead of stopping 10 pixels above it.

---

## Verification Plan

### Automated Tests
- Build and run the Flutter application:
  ```powershell
  flutter run -d windows
  ```

### Manual Verification
1. Open a level with empty tubes.
2. Select a tube with liquid and pour it into an empty tube.
3. Verify that:
   - The destination tube physically shudders (shakes) on the first impact of the liquid.
   - The liquid stream goes all the way down to the bottom of the empty tube.
   - The splash/repulsion particles are drawn continuously right at the bottom center where the stream meets the glass.
   - The liquid wobbles and settles smoothly after the pour animation completes.
