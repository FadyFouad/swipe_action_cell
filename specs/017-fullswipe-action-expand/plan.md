# Implementation Plan: Full-Swipe Action Expand

**Branch**: `017-fullswipe-action-expand` | **Date**: 2026-03-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/017-fullswipe-action-expand/spec.md`

## Summary

Fix the full-swipe visual behavior so the designated action expands within the existing reveal panel instead of rendering a separate overlay widget. Modify `SwipeActionPanel` to accept `fullSwipeRatio` and distribute action widths based on expand progress. Remove the `FullSwipeExpandOverlay` widget entirely. This is a visual/layout fix — no API changes to `FullSwipeConfig`.

## Technical Context

**Language/Version**: Dart >=3.4.0 <4.0.0
**Primary Dependencies**: Flutter SDK only (zero external runtime deps — Constitution IV)
**Storage**: N/A (no persistence)
**Testing**: `flutter test` (flutter_test framework)
**Target Platform**: All Flutter-supported platforms (iOS, Android, web, macOS, Windows, Linux)
**Project Type**: Flutter library/package
**Performance Goals**: 60 fps during all drag interactions (Constitution X)
**Constraints**: No external runtime dependencies; const-friendly config objects; all public members dartdoc'd
**Scale/Scope**: 3 files modified, 1 file deleted, 1 new test file

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Composition over Inheritance | PASS | No class hierarchy changes. `SwipeActionPanel` remains a composable widget. |
| II. Explicit State Machine | PASS | No new states. `_fullSwipeRatio` is a continuous property within `dragging` state. |
| III. Spring-Based Physics | PASS | No new animations introduced. Expand is drag-driven, not animation-driven. |
| IV. Zero External Runtime Deps | PASS | No new dependencies. |
| V. Controlled/Uncontrolled | PASS | No change to controller pattern. |
| VI. Const-Friendly Config | PASS | `FullSwipeConfig` unchanged. `SwipeActionPanel` constructor remains const. |
| VII. Test-First | PASS | Tests specified for expand visual behavior. Existing tests must pass. |
| VIII. Dartdoc Everything | PASS | New parameters on `SwipeActionPanel` must have dartdoc. |
| IX. Null Config = Feature Disabled | PASS | `designatedActionIndex: null` disables expand behavior. |
| X. Performance: 60 fps | PASS | Constant widget tree structure during drag. No rebuilds. |

**Gate result**: All principles pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/017-fullswipe-action-expand/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── swipe_action_panel.md
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/src/
├── actions/
│   ├── full_swipe/
│   │   ├── full_swipe_config.dart         # Unchanged
│   │   └── full_swipe_expand_overlay.dart  # DELETED
│   └── intentional/
│       └── swipe_action_panel.dart         # MODIFIED (add fullSwipeRatio, designatedActionIndex)
└── widget/
    └── swipe_action_cell.dart              # MODIFIED (pass ratio to panel, remove overlay from Stack)

test/
└── full_swipe/
    └── full_swipe_expand_visual_test.dart  # NEW (expand layout tests)
```

**Structure Decision**: Existing feature-first structure. No new directories. One file deleted (overlay), two files modified (panel + main widget), one test file added.

## Complexity Tracking

No constitution violations — this section is not applicable.

## Implementation Strategy

### Phase 1: Modify SwipeActionPanel (Core Layout Change)

**Goal**: Make `SwipeActionPanel` aware of full-swipe expand progress and distribute widths accordingly.

**Changes to `SwipeActionPanel`** (`lib/src/actions/intentional/swipe_action_panel.dart`):

1. Add `fullSwipeRatio` (double, default 0.0) and `designatedActionIndex` (int?, default null) parameters
2. In `build()`, when `fullSwipeRatio > 0.0` and `designatedActionIndex != null`:
   - Calculate `normalWidth` per action using flex ratios: `panelWidth * (action.flex / totalFlex)`
   - Calculate non-designated widths: `normalWidth * (1.0 - fullSwipeRatio)`
   - Calculate designated width: `panelWidth - sum(nonDesignatedWidths)`
   - Replace `Expanded` children with `SizedBox(width: calculatedWidth)` children
   - Wrap non-designated actions in `Opacity(opacity: 1.0 - fullSwipeRatio)`
   - Wrap all action content in `ClipRect` to prevent overflow during shrink
3. When `fullSwipeRatio == 0.0` (default): use existing `Expanded(flex: ...)` layout — zero behavioral change for non-full-swipe cases
4. Keep destructive two-tap expansion (`_expandedIndex`) unchanged — it operates independently

**Widget tree invariant**: The Row always has `actions.length` children. During expand, each child is: `SizedBox > ClipRect > Opacity > GestureDetector > ColoredBox > content`. Properties (width, opacity) change but structure doesn't — Element reuse is preserved.

### Phase 2: Wire Up in SwipeActionCell

**Goal**: Pass `_fullSwipeRatio` and designated action index from `SwipeActionCell` to `SwipeActionPanel`.

**Changes to `swipe_action_cell.dart`**:

1. In `_buildRevealPanel()` (line ~1852):
   - Compute `designatedIndex`: find the index of `fullSwipeConfig.action` in the actions list (by identity or equality)
   - Pass `fullSwipeRatio: _fullSwipeRatio` and `designatedActionIndex: designatedIndex` to `SwipeActionPanel`
   - Only pass non-null `designatedIndex` when `fullSwipeConfig?.expandAnimation == true`

2. In `build()` Stack (line ~2214):
   - Remove the `FullSwipeExpandOverlay` widget entirely (lines 2214–2225)
   - The reveal panel now handles all full-swipe visual feedback internally

### Phase 3: Delete FullSwipeExpandOverlay

**Goal**: Remove the deprecated overlay widget.

1. Delete `lib/src/actions/full_swipe/full_swipe_expand_overlay.dart`
2. Remove import from `swipe_action_cell.dart`
3. Remove export from `lib/swipe_action_cell.dart` barrel file (if exported — likely internal-only)

### Phase 4: Tests

**New test file**: `test/full_swipe/full_swipe_expand_visual_test.dart`

Test cases:
1. At `fullSwipeRatio == 0.0`: all actions have equal width (`panelWidth / N`)
2. At `fullSwipeRatio == 0.5`: designated action is wider, others narrower, sum == panelWidth
3. At `fullSwipeRatio == 1.0`: designated action width == panelWidth, others == 0
4. Drag back reverses: widths restore to equal when ratio returns to 0.0
5. Single action expand: one action grows from normalWidth to panelWidth
6. Designated action at index 0 (first): works correctly, later actions shrink
7. Designated action in middle: actions on both sides shrink
8. 2, 3 actions: layout correct for various action counts
9. Opacity of shrinking actions: 0.0 at fullSwipeRatio 1.0, 0.5 at 0.5
10. Icon stays centered during expand (Center widget still centers within expanding SizedBox)
11. Existing full-swipe trigger/haptic/undo tests pass unchanged
12. No FullSwipeExpandOverlay in widget tree during full swipe

### Phase 5: Verify Existing Tests

Run full test suite. All existing tests in `test/full_swipe/` must pass without modification.

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Existing tests break due to widget tree changes | Only the overlay is removed — reveal panel structure stays the same. Tests finding reveal panel buttons should still work. |
| Width rounding causes 1-pixel gaps | Use `panelWidth - sum(otherWidths)` for designated action (absorbs rounding error). |
| Destructive two-tap expansion conflicts | Two-tap expansion uses `_expandedIndex` state, orthogonal to drag-driven `fullSwipeRatio`. Cannot co-occur (tap vs drag). |
| Performance: SizedBox rebuilds | SizedBox with changing width triggers relayout but NOT Element rebuild. Row with same number of same-type children preserves Elements. |
