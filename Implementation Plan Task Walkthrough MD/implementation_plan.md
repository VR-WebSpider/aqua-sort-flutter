# Implementation Plan - Liquid Visuals and SFX Fixes

This plan outlines the visual and auditory enhancements to the **Aqua Sort** game to ensure a premium, polished user experience.

## Proposed Changes

### 1. Liquid Color Palette Enhancements
We will replace the generic Material color palette with highly vibrant, bright neon colors. These colors are optimized for a dark slate background and will shine under the 3D cylindrical glass specular highlights.

#### [MODIFY] [game_engine.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/engine/game_engine.dart)
- Replace `kTubeColors` with a carefully calibrated, bright neon palette.

```dart
const List<Color> kTubeColors = [
  Color(0xFFFF3B30), // Vivid Neon Red
  Color(0xFF007AFF), // Electric Blue
  Color(0xFF00E676), // Neon Green
  Color(0xFFFFD60A), // Neon Yellow
  Color(0xFFBF5AF2), // Electric Purple
  Color(0xFFFF9F0A), // Bright Neon Orange
  Color(0xFF0AFFFF), // Cyan/Turquoise Glow
  Color(0xFFFF2D55), // Hot Pink/Magenta
];
```

---

### 2. Pour Stream and Sound Triggering Fixes
Currently, the pour stream and sound are cut off or skip rendering during short animations (such as single-color pours where `count == 1`). We will ensure:
- The stream starts immediately at the beginning of the pouring animation and stays visible until it is fully completed.
- The pouring sound starts playing as the liquid tilts and runs robustly throughout the pour, stopping only when the widget is disposed.

#### [MODIFY] [pouring_animation_overlay.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/pouring_animation_overlay.dart)
- Change `_stream.value > 0.05 && _stream.value < 0.98` to `_stream.value > 0.0 && _stream.value < 1.0` to prevent clipping due to frame drops.
- Remove early sound stoppage logic in the listener, and instead call `AudioService.instance.stopPour()` in `dispose()` to guarantee a full and satisfying sound effect.

---

### 3. Straight Color Boundaries and Soft Blending Effects
Different liquid colors stacked in a tube should have perfectly straight boundary lines reflecting fluid balance under gravity, rather than wavy meniscus-like lines. Additionally, a soft color blending transition should be visible where they touch.

#### [MODIFY] [liquid_painter.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/liquid_painter.dart)
- Update the custom painter to render perfectly straight horizontal/tilted boundaries for internal liquid interfaces.
- Retain the curvy meniscus shape only for the top-most air-liquid surface.
- Add an overlay pass to draw a soft, semi-transparent gradient blending band (12.0 pixels tall) at the interface where different colors meet.

---

## Verification Plan

### Manual Verification
1. Relaunch the application using `flutter run -d windows` in the local terminal.
2. Verify that:
   - All colors are bright, vivid, and charming.
   - Doing a single-color pour displays a visible stream and plays the full pouring sound without getting cut off.
   - The boundaries between different liquid colors in vertical tubes are straight horizontal lines, with a soft, natural blending transition.
