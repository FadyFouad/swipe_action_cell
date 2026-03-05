# Data Model: Full-Swipe Action Expand

**Branch**: `017-fullswipe-action-expand` | **Date**: 2026-03-06

## Entities

### Expand Progress (existing, no change)

A `double` value (0.0–1.0) already tracked as `_fullSwipeRatio` in `SwipeActionCell`. Computed by `_checkFullSwipeThreshold()` on each drag update.

- **Source**: `_fullSwipeRatio` in `_SwipeActionCellState`
- **Range**: 0.0 (at or below activation threshold) to 1.0 (at or above full-swipe threshold)
- **Lifecycle**: Set during drag, reset to 0.0 on snap-back or action trigger

### SwipeActionPanel (modified)

Receives two new parameters to support full-swipe expand:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `fullSwipeRatio` | `double` | `0.0` | Current expand progress (0.0–1.0). Drives width distribution. |
| `designatedActionIndex` | `int?` | `null` | Index of the full-swipe designated action. Null = no expand behavior. |

### Width Distribution (derived, computed per frame)

For N actions where designated action is at index D:

| Condition | Non-designated width | Designated width |
|-----------|---------------------|-----------------|
| `fullSwipeRatio == 0.0` | `panelWidth / N` | `panelWidth / N` |
| `0.0 < fullSwipeRatio < 1.0` | `(panelWidth / N) * (1.0 - fullSwipeRatio)` | `panelWidth - sum(nonDesignatedWidths)` |
| `fullSwipeRatio == 1.0` | `0.0` | `panelWidth` |

Note: When actions have custom `flex` values, `normalWidth` per action is `panelWidth * (action.flex / totalFlex)` instead of `panelWidth / N`.

### FullSwipeConfig (unchanged)

No modifications. Existing fields:
- `enabled`, `threshold`, `action`, `postActionBehavior`, `expandAnimation`, `enableHaptic`, `fullSwipeProgressBehavior`

### FullSwipeExpandOverlay (removed)

This widget is deleted entirely. Its functionality is absorbed into `SwipeActionPanel`'s width distribution logic.

## State Transitions

No new states added. The existing state machine is unchanged:
`idle → dragging → animatingToOpen → revealed → animatingToClose → idle`

The `_fullSwipeRatio` value changes during the `dragging` state but does not define a new state — it's a continuous property within the `dragging` state.
