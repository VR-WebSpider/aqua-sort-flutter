# Custom Designer Tubes in Marketplace and Game

## Overview
This plan implements custom designer tube shapes across all screens in the game (tube marketplace grid, customization details, and the gameplay board) using the unique bezier paths defined in [skin_catalogue.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/models/skin_catalogue.dart). It ensures that:
1. Grid previews (`MiniTubePreview`) use the custom shapes and align their top lip lines.
2. Detail screen previews (`LargeTubePreview`) use the custom shapes and align their top lip lines.
3. Active gameplay board tubes (`TubeWidget`) render using the custom shapes, align the top lip, and scale/re-align the solved container caps to match the specific neck bounds of each tube style.
4. **All interactive features — including the closing lid/cap, the lid-closing sound effects, and the celebratory solved burst/sparkle particle effects — are preserved and dynamically repositioned to match the center and width of the custom tube necks.**

---

## Proposed Changes

### 1. Update Preview Painters — `[MODIFY]`
#### [MODIFY] [skin_provider.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/profile/providers/skin_provider.dart)
- Replace the hardcoded U-shaped `Path` in `_MiniTubePainter.paint` and `_LargeTubePainter.paint` with `SkinCatalogue.getTubePath(skin.id, w, h, lipH, r)`.
- Use `SkinCatalogue.getTubeTopBounds(skin.id, w)` to determine the start and end coordinates of the top lip line.
- Update `shouldRepaint` checks to ensure repaint is triggered if the skin ID changes.

### 2. Update Active Gameplay Tube Painter — `[MODIFY]`
#### [MODIFY] [tube_widget.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/widgets/tube_widget.dart)
- Replace the hardcoded U-shaped `Path` in `_TubePainter.paint` with `SkinCatalogue.getTubePath(activeSkinId, w, h, lipH, r)`.
- Update the top lip line drawing to use boundaries returned by `SkinCatalogue.getTubeTopBounds(activeSkinId, w)`.
- Update the `_drawCap` method to retrieve the active skin's top bounds and scale/position the metallic cap path, gradient, and details precisely over the custom neck width.
- Adjust sparkle and burst effect positioning so they center correctly over the customized tube neck.
- Ensure `shouldRepaint` checks for `activeSkinId` differences.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure clean code with zero errors/warnings.
- Run `flutter build apk --debug` to verify successful compilation.

### Manual Verification
- Verify grid previews in customization shop are rendered in distinct shapes (e.g., beakers, hourglasses, v-shapes).
- Verify the active gameplay screen matches the selected skin's shape, and solved tube caps fit the neck precisely.
- Confirm that the lid closing animation plays, the lid closing sound triggers, and the post-completion particle/sparkle effects burst from the center of the customized tube neck.
