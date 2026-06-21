# Implementation Plan - Sound FX Polish & Navigation Clicks

This plan details changes to fix overlapping completion sounds (keeping only the cork sound) and ensure the water drip click sound plays for all screen/modal navigations.

## User Review Required

> [!IMPORTANT]
> - **Only Cork Sound on Solve**: We will remove the overlapping mini-celebration sound from the tube completion effect in [tube_widget.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/tube_widget.dart), leaving only the pressurized cork pop sound (`playLidClosing()`).
> - **Navigation Drip Click**: We will implement a custom `NavigationAudioObserver` in [app_router.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/router/app_router.dart) that automatically plays the water drip click sound (`playClick()`) when routes (pages, general dialogs, bottom sheets) are pushed or popped, ensuring navigation plays sound consistently.
> - **Settings Respect**: The navigation sound automatically respects the user's settings (muted status, SFX settings switches) because it routes through `AudioService.playClick()`.

## Proposed Changes

---

### 1. Tube Solved Sound Effects

#### [MODIFY] [tube_widget.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/tube_widget.dart)
- Remove `AudioService.instance.playMiniCelebration();` from the `_triggerSolvedEffect()` method.

---

### 2. Navigation Sound Observer

#### [MODIFY] [app_router.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/router/app_router.dart)
- Import `audio_service.dart`.
- Define a custom `NavigationAudioObserver` extending `NavigatorObserver` that plays the drip click sound (`AudioService.instance.playClick()`) on `didPush` and `didPop`.
- Pass this observer to the `GoRouter` configuration.

---

## Verification Plan

### Automated Tests
- Run static analysis to verify compile health:
  ```powershell
  f:\.gemini\antigravity\scratch\flutter\bin\flutter.bat analyze
  ```

### Manual Verification
1. Solve a tube during gameplay: verify only the pressurized cork pop sound plays.
2. Navigate between pages (e.g., Lobby -> Profile -> Leaderboard -> Campaign): verify the water drip click sound plays.
3. Open any profile modal (e.g., Settings, achievements): verify the click sound plays on open and close.
4. Mute the audio (or disable SFX in Settings) and perform navigations: verify no click sounds play.
