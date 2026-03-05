# Research: Full-Swipe Auto-Trigger (F016)

**Branch**: `016-full-swipe-trigger` | **Date**: 2026-03-02

---

## D1 — FullSwipeConfig location & file structure

**Decision**: New directory `lib/src/actions/full_swipe/` with two files:
- `full_swipe_config.dart` — `FullSwipeConfig` data class + `FullSwipeProgressBehavior` enum
- `full_swipe_expand_overlay.dart` — `FullSwipeExpandOverlay` widget (expand-to-fill visual)

**Rationale**: Mirrors the existing `lib/src/actions/intentional/` and `lib/src/actions/progressive/` directories. Keeps concerns isolated and discovery natural. Avoids adding full-swipe fields directly to core files.

**Alternatives considered**:
- Adding `FullSwipeConfig` to `lib/src/config/` — rejected: config/ holds top-level cell configs; full-swipe is a sub-config of direction configs.
- Embedding in `left_swipe_config.dart`/`right_swipe_config.dart` directly — rejected: two files would duplicate the class definition.

---

## D2 — SwipeProgress extension for visual layer

**Decision**: Add `fullSwipeRatio` (double, 0.0–1.0) to `SwipeProgress`. When `FullSwipeConfig` is null for the active direction, `fullSwipeRatio` is always 0.0. The field is included in `copyWith`, `==`, and `hashCode`.

**Rationale**: The visual layer (background builders) already receives `SwipeProgress` on every frame. Adding `fullSwipeRatio` gives background builder authors direct access without coupling to internal widget state. Smooth bidirectional transitions are trivially driven by interpolating on `fullSwipeRatio`. A `bool isFullSwipeActive` would only give binary state, preventing smooth animations.

**Alternatives considered**:
- Separate `ValueNotifier<double> fullSwipeRatioNotifier` — rejected: adds allocation overhead; `SwipeProgress` already flows through the pipeline.
- New `FullSwipeProgress` wrapper class — rejected: forces background builder authors to cast/check type.

---

## D3 — Expand-to-fill visual implementation

**Decision**: A new stateful widget `FullSwipeExpandOverlay` is placed in the Stack **between the reveal panel and the decoratedChild**. It wraps the reveal panel's content and uses `fullSwipeRatio` from `SwipeProgress` to:
1. Fade out non-designated actions (opacity = 1.0 - fullSwipeRatio)
2. Scale+center the designated action icon (scale = 1.0 + 0.3 * fullSwipeRatio at rest; bump animation overlaid)
3. Expand background color of the designated action to full cell width

The "locked-in" bump is a separate `AnimationController` (`_fullSwipeBumpController`, 150ms `TweenSequence` 1.0→1.15→1.0) that fires once on threshold entry. When `MediaQuery.disableAnimations` is true, the bump is suppressed.

**Rationale**: The `FullSwipeExpandOverlay` encapsulates the full-swipe visual completely, so `SwipeActionPanel` is unchanged. Adding the overlay to the Stack means the existing z-order and hit-testing logic is unaffected.

**Alternatives considered**:
- Modifying `SwipeActionPanel` directly to accept `fullSwipeRatio` — rejected: couples the reveal panel widget to full-swipe logic; violates separation of concerns.
- Driving the animation entirely from the background builder — rejected: the background builder is consumer-defined; the package cannot guarantee the default expand-to-fill visual for arbitrary builders.

---

## D4 — Gesture locking after action fires

**Decision**: A `_fullSwipeTriggered` bool field on `SwipeActionCellState` is set to `true` when the full-swipe action fires and reset to `false` when the post-action animation completes (in `_handleAnimationStatusChange` for `animatingOut`/`animatingToClose`). In `_handleDragStart`, if `_fullSwipeTriggered == true`, return early.

**Rationale**: The simplest possible guard. Since `FullSwipeState.triggered` is internal-only, a bool flag avoids extending the public `SwipeState` enum (which would be a breaking change for consumers pattern-matching on it).

**Alternatives considered**:
- Extending `SwipeState` with a `fullSwipePending` value — rejected: breaking change for consumers using exhaustive switch on `SwipeState`.
- Using `_state == SwipeState.animatingOut` as the guard — rejected: `animatingOut` is also used by normal `PostActionBehavior.animateOut`, so the guard would incorrectly block normal re-swipe scenarios.

---

## D5 — Full-swipe threshold detection during drag update

**Decision**: In `_handleDragUpdate`, after setting `_controller.value`, compute `ratio = _controller.value.abs() / widgetWidth`. If the active direction has a `FullSwipeConfig` with `enabled: true`, compare `ratio` to `config.threshold`. Track `_isFullSwipeArmed` (bool). On transition (armed/unarmed), fire haptic and start/stop the bump animation. Also compute `fullSwipeRatio = (ratio - activationThreshold) / (config.threshold - activationThreshold)` clamped to [0.0, 1.0], and include it in the `SwipeProgress` broadcast.

**Rationale**: Computing in `_handleDragUpdate` ensures every frame update captures the latest drag position, enabling smooth bidirectional threshold hovering.

**Alternatives considered**:
- Computing `fullSwipeRatio` only at threshold crossing (binary) — rejected: produces jitter at the threshold; ratio-driven interpolation is required for smooth animation.

---

## D6 — Haptic event names

**Decision**: Add two new values to `SwipeFeedbackEvent`:
- `fullSwipeThresholdCrossed` — fires each time the drag crosses the full-swipe threshold (both entering and exiting).
- `fullSwipeActivation` — fires on release above the threshold, before the action executes.

Default patterns (when no override in `hapticOverrides`):
- `fullSwipeThresholdCrossed` → `HapticPattern.heavy` (distinct from `thresholdCrossed` which defaults to medium)
- `fullSwipeActivation` → `HapticPattern.success`

Gated by `FullSwipeConfig.enableHaptic` (not the cell-level `feedbackConfig.enableHaptic`).

**Rationale**: Reuses existing `FeedbackDispatcher` machinery. Adding to the enum is non-breaking for consumers who don't pattern-match on it. The gate being on `FullSwipeConfig.enableHaptic` (not the global toggle) gives per-direction control without overriding global silence.

**Alternatives considered**:
- Calling `HapticFeedback.heavyImpact()` directly — rejected: bypasses `FeedbackDispatcher` and breaks consumer haptic overrides.

---

## D7 — triggerFullSwipe programmatic API

**Decision**: Add to `SwipeCellHandle`:
```dart
void executeTriggerFullSwipe(SwipeDirection direction);
```
Add to `SwipeController`:
```dart
void triggerFullSwipe(SwipeDirection direction)
```
When called, fires the full-swipe action for the given direction if `FullSwipeConfig.enabled` is true. No-op (with debug assert) if not configured for that direction or if state is not idle.

**Rationale**: Follows the existing `openLeft()`/`openRight()` bridge pattern precisely. `executeTriggerFullSwipe` is added to `SwipeCellHandle` and implemented by `SwipeActionCellState`. The public-facing method on `SwipeController` delegates to the handle.

---

## D8 — Accessibility integration

**Decision**:
- `SwipeSemanticConfig` gets two new optional fields: `fullSwipeLeftLabel: SemanticLabel?` and `fullSwipeRightLabel: SemanticLabel?`. When null, defaults to `"Swipe fully to [action.label]"`.
- The existing `FocusNode.onKeyEvent` in `SwipeActionCellState` handles `Shift+Arrow` keys. For left full-swipe: `LogicalKeyboardKey.arrowLeft` + shift modifier. For right: `LogicalKeyboardKey.arrowRight` + shift modifier. RTL flips the mapping via `_isRtl`.
- The `Semantics` widget for the cell includes a `customSemanticsAction` for full-swipe when enabled.

**Rationale**: Follows the existing keyboard handling pattern in the widget. No new infrastructure needed.

---

## D9 — animateOut direction for full-swipe

**Decision**: Modify `_animateOut()` to accept a `SwipeDirection direction` parameter (defaulting to `SwipeDirection.left` for backward compatibility). Right full-swipe with `animateOut` animates to `+widgetWidth * 1.5`.

**Rationale**: Existing callers of `_animateOut()` are only from left-swipe intentional context, so the default parameter preserves backward compatibility. Full-swipe callers pass the actual direction.

---

## D10 — Template integration

**Decision**: `SwipeActionCell.delete` and `SwipeActionCell.archive` factory constructors gain an optional `FullSwipeConfig? fullSwipeConfig` parameter (default: a pre-built config that matches the template's action). Since templates currently use `onActionTriggered` callbacks (not `SwipeAction` directly), the template constructs an internal `SwipeAction` instance that calls the same callback. The full-swipe action's `SwipeAction` is constructed from the template's icon/color/callback.

**Rationale**: Zero-config full-swipe for the most common use cases. The `FullSwipeConfig` can be overridden by the consumer if they want non-default behavior.
