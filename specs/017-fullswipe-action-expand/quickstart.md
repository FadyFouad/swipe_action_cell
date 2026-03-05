# Quickstart: Full-Swipe Action Expand

**Branch**: `017-fullswipe-action-expand` | **Date**: 2026-03-06

## What Changed

The full-swipe visual behavior was fixed so the designated action expands within the existing reveal panel instead of rendering a separate overlay widget. This is a visual/layout-only change — no API changes.

## Files Modified

1. **`lib/src/actions/intentional/swipe_action_panel.dart`** — Added `fullSwipeRatio` and `designatedActionIndex` parameters. When `fullSwipeRatio > 0`, action widths are interpolated (designated action expands, others shrink and fade).

2. **`lib/src/widget/swipe_action_cell.dart`** — Passes `_fullSwipeRatio` and the designated action index to `SwipeActionPanel`. Removed the `FullSwipeExpandOverlay` from the Stack.

3. **`lib/src/actions/full_swipe/full_swipe_expand_overlay.dart`** — Deleted entirely.

## How It Works

When the user drags past the activation threshold (40% of cell width) toward the full-swipe threshold (default 75%):

1. `_checkFullSwipeThreshold()` computes `_fullSwipeRatio` (0.0 at activation, 1.0 at full-swipe threshold)
2. `_buildRevealPanel()` passes `_fullSwipeRatio` and the designated action's index to `SwipeActionPanel`
3. `SwipeActionPanel` distributes widths:
   - Non-designated actions: `normalWidth * (1.0 - fullSwipeRatio)`, wrapped in `Opacity(opacity: 1.0 - fullSwipeRatio)`
   - Designated action: `panelWidth - sum(otherWidths)` — fills remaining space
4. Dragging back reverses the interpolation (fully reversible)
5. All existing behaviors (haptic, trigger, undo) are unchanged

## Running Tests

```bash
# All tests
flutter test

# Full-swipe specific tests
flutter test test/full_swipe/

# New expand visual tests
flutter test test/full_swipe/full_swipe_expand_visual_test.dart
```

## No API Changes

`FullSwipeConfig` is unchanged. The `expandAnimation` flag still controls whether the visual expand occurs. Setting `expandAnimation: false` keeps all action widths equal during full swipe (trigger still fires on release past threshold).
