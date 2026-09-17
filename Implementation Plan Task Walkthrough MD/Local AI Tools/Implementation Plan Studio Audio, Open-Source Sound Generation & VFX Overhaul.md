# Implementation Plan: Studio Audio, Open-Source Sound Generation & VFX Overhaul

## Overview
This plan establishes an open-source audio generation pipeline (including **Stable Audio Open** / **AudioCraft** integration scripts + high-fidelity digital sound synthesis engine) to produce studio-grade water SFX, ambient soundscapes, and UI sounds, while upgrading the in-game visual special effects (micro-bubbles, dynamic liquid meniscus, sparkle bursts, and pouring streams).

---

## Proposed Changes

### 1. Open-Source Sound Generation Pipeline
#### [NEW] [`assets/audio/generate_studio_sfx.py`](file:///D:/.gemini/antigravity/scratch/aqua-sort-flutter/assets/audio/generate_studio_sfx.py)
* High-fidelity multi-oscillator synthesizer engine with harmonic resonance, acoustic water modeling, granular noise shaping, and reverbs to generate:
  1. `water_drop_tap.wav` - Crisp water droplet tap for tube selections and UI buttons.
  2. `tube_pour_liquid.wav` - Rich continuous water flow with dynamic pitch bubbling.
  3. `cork_snap_lock.wav` - Punchy airtight cork & glass seal pop when a tube is completed.
  4. `solved_chime_sparkle.wav` - Pentatonic shimmer chime with crystal resonance for mini-victories.
  5. `coin_pickup.wav` - Metallic brass/gold ring for coin gains and shop rewards.
  6. `undo_rewind_whoosh.wav` - Time-reverse water swoosh for undos.
  7. `victory_fanfare_orchestral.wav` - Full euphoric victory theme for level completion.
  8. `ambient_ocean_loop.wav` - Soothing ambient underwater drone pad with gentle wave frequencies.

#### [NEW] [`assets/audio/stable_audio_generator.py`](file:///D:/.gemini/antigravity/scratch/aqua-sort-flutter/assets/audio/stable_audio_generator.py)
* Ready-to-run pipeline script using `diffusers` & Hugging Face (`stabilityai/stable-audio-open-1.0` / `facebook/audiocraft`) for generating AI-prompted game SFX and background music directly on GPU or CPU.

---

### 2. Audio Engine Integration
#### [MODIFY] [`lib/core/services/audio_service.dart`](file:///D:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/core/services/audio_service.dart)
* Add handlers for `playWaterDropTap()`, `playPourLoop()`, `playCorkSnap()`, `playSolvedChime()`, `playCoinReward()`, and `playUndoWhoosh()`.
* Add ambient sound layer support with dynamic volume blending between background music and water soundscapes.

---

### 3. Visual Special Effects & Liquid Animations
#### [MODIFY] [`lib/features/game/widgets/liquid_painter.dart`](file:///D:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/liquid_painter.dart)
* Add dynamic liquid meniscus curvature with dual wave harmonic ripples.
* Add rising buoyant micro-bubbles inside the liquid layers when settling.
* Add glass rim reflections and ambient specular highlights.

#### [MODIFY] [`lib/features/game/widgets/tube_widget.dart`](file:///D:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/tube_widget.dart)
* Enhance solved particle burst with radial rainbow sparkles and star trails.
* Hook audio triggers for instant tactile and auditory feedback on tube interaction.

---

## Verification Plan

### Automated Verification
* Execute `python generate_studio_sfx.py` to generate and validate all 44.1kHz stereo audio assets.
* Run `flutter analyze` to ensure 100% type safety and zero compile errors across audio and VFX widgets.

### Manual Verification
* Test in-game pouring, cork closing, and victory overlays to ensure zero audio latency and smooth 60fps animations.
