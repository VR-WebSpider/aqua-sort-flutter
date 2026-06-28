# Implementation Plan – Fix Onboarding Tutorial Loop & Level Solvability

This plan introduces a high-performance heuristic DFS solver for Aqua Sort. We will use it to dynamically compute valid tutorial moves (solving the Level 2 tutorial loop) and to ensure that any generated level in the game is 100% solvable.

## Proposed Changes

### Component: Aqua Sort Game Engine & Generator

#### [MODIFY] [game_engine.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/engine/game_engine.dart)

1. **Add `GameSolver` class**:
   - Implement a heuristic Depth-First Search solver that canonicalizes visited states and orders moves using specific game heuristics (prioritizing solves and empty tube creation, penalizing redundant moves).
2. **Modify `PuzzleGenerator.generate`**:
   - Integrate the solver during level generation (for Level 2 and above). If the generated board is unsolvable, re-shuffle the colors and retry (up to 100 times).

---

### Component: Aqua Sort Interactive Tutorial

#### [MODIFY] [tutorial_discovery.dart](file:///f:/.gemini/antigravity/scratch/aqua-sort-flutter/lib/features/game/engine/tutorial_discovery.dart)

- Rewrite `TutorialDiscovery.findMove`:
  - For `level <= 2`, instead of using static heuristics that can loop, invoke `GameSolver.solve` on the current state.
  - Return the first move of the solution path.
  - This dynamically updates and guides the player along the optimal path, automatically recovering even if they undo or if the board layout changes.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure there are no static analysis errors.
- Run a dart test command or a simple script to verify `GameSolver` correctly solves levels.

### Manual Verification
- Launch Level 1 and verify the tutorial operates correctly.
- Launch Level 2 and verify that the infinite loop of swapping water back and forth is gone, and the tutorial successfully guides the player to complete the level.
- Generate several higher-level layouts to confirm they load successfully and are solvable.
