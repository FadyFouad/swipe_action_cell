# Implementation Plan: Full-Swipe Auto-Trigger (F016)

**Branch**: `016-full-swipe-trigger` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/016-full-swipe-trigger/spec.md`

---

## Summary

Add an iOS Mail-style "swipe fully to act" pattern to `SwipeActionCell`. When a cell is dragged past a configurable threshold (default 75% of cell width), the designated action fires automatically on release — skipping the reveal panel tap. Works symmetrically on both left and right directions. Configurable via `FullSwipeConfig` added to `LeftSwipeConfig` and `RightSwipeConfig`. Includes expand-to-fill visual animation, bidirectional threshold hover, haptic feedback, undo support, `SwipeController.triggerFullSwipe`, keyboard shortcuts, and screen reader semantics. Disabled by default — zero overhead when not configured.

---

## Technical Context

**Language/Version**: Dart >= 3.4.0 < 4.0.0
**Primary Dependencies**: Flutter SDK only (Constitution IV)
**Storage**: N/A — stateless config; no persistence
**Testing**: `flutter test` (widget + unit tests)
**Target Platform**: All Flutter-supported platforms
**Performance Goals**: 60fps on mid-range devices; zero overhead when disabled (Constitution X)
**Constraints**: Zero external runtime deps; `FullSwipeConfig` null = feature disabled (Constitution IX); all new public API needs dartdoc (Constitution VIII)
**Scale/Scope**: 2 new source files, 13 modified files, 6 new test files

---

## Constitution Check

*GATE: Must pass before implementation. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Composition over Inheritance | PASS | `FullSwipeConfig` wraps existing `SwipeAction`. `FullSwipeExpandOverlay` wraps existing panel. No new base classes. |
| II. Explicit State Machine | PASS | New internal `_isFullSwipeArmed` / `_fullSwipeTriggered` flags extend the state machine without modifying the public `SwipeState` enum. Transitions are explicit: idle to armed to triggered to idle. |
| III. Spring-Based Physics | PASS | `_animateOutDirectional` reuses the existing `SpringSimulation` / `effectiveAnimationConfig.completionSpring`. Bump animation uses `TweenSequence` on an `AnimationController` with vsync. |
| IV. Zero External Runtime Deps | PASS | No new packages. All code uses Flutter SDK only. |
| V. Controlled/Uncontrolled Pattern | PASS | `SwipeController.triggerFullSwipe` is opt-in. Full-swipe works without any controller. |
| VI. Const-Friendly Configuration | PASS | `FullSwipeConfig` is `@immutable` with a `const` constructor and `copyWith`. |
| VII. Test-First (NON-NEGOTIABLE) | PASS | Red tests written before each implementation cluster. |
| VIII. Dartdoc Everything | PASS | All new public classes, methods, enum values, and fields carry `///` comments. |
| IX. Null Config = Feature Disabled | PASS | `FullSwipeConfig? fullSwipeConfig = null` on both direction configs. Null = zero gesture listeners, no visual nodes, no `_fullSwipeBumpController` allocation. |
| X. 60 fps Budget | PASS | `fullSwipeRatio` is computed inline in `_handleDragUpdate` (no async). `FullSwipeExpandOverlay` is driven by the existing animation controller frame — no additional `ValueListenable` or `StreamBuilder`. |

---

## Complexity Tracking

No constitution violations. No exceptions required.

---

## Project Structure

### Documentation (this feature)

```text
specs/016-full-swipe-trigger/
├── plan.md              <- This file
├── research.md          <- Phase 0 output
├── data-model.md        <- Phase 1 output
├── quickstart.md        <- Phase 1 output
├── contracts/
│   └── public-api.md   <- Phase 1 output
└── tasks.md             <- Phase 2 output (/speckit.tasks)
```

### Source Code

```text
lib/
├── swipe_action_cell.dart           <- MODIFIED: +1 export (full_swipe_config.dart)
└── src/
    ├── actions/
    │   └── full_swipe/              <- NEW directory (F016)
    │       ├── full_swipe_config.dart         <- FullSwipeConfig, FullSwipeProgressBehavior
    │       └── full_swipe_expand_overlay.dart <- FullSwipeExpandOverlay widget
    ├── core/
    │   └── swipe_progress.dart      <- MODIFIED: +fullSwipeRatio field
    ├── config/
    │   ├── left_swipe_config.dart   <- MODIFIED: +fullSwipeConfig field
    │   └── right_swipe_config.dart  <- MODIFIED: +fullSwipeConfig field
    ├── feedback/
    │   └── swipe_feedback_config.dart <- MODIFIED: +2 SwipeFeedbackEvent values
    ├── accessibility/
    │   └── swipe_semantic_config.dart <- MODIFIED: +fullSwipeLeftLabel/rightLabel
    ├── controller/
    │   ├── swipe_cell_handle.dart   <- MODIFIED: +executeTriggerFullSwipe
    │   └── swipe_controller.dart    <- MODIFIED: +triggerFullSwipe
    ├── widget/
    │   └── swipe_action_cell.dart   <- MODIFIED: main integration
    ├── templates/
    │   └── swipe_cell_templates.dart <- MODIFIED: delete/archive get FullSwipeConfig
    └── testing/
        └── swipe_tester.dart        <- MODIFIED: +fullSwipeLeft/fullSwipeRight

test/
└── full_swipe/                      <- NEW test directory (F016)
    ├── full_swipe_config_test.dart
    ├── full_swipe_gesture_test.dart
    ├── full_swipe_visual_test.dart
    ├── full_swipe_haptic_test.dart
    ├── full_swipe_integration_test.dart
    └── full_swipe_controller_test.dart
```

---

## Phase 0: Research Output

See [research.md](research.md) for all 10 architectural decisions (D1-D10).

Key decisions summary:
- **D1** — `FullSwipeConfig` in `lib/src/actions/full_swipe/` (new directory)
- **D2** — Add `fullSwipeRatio` to `SwipeProgress` (smooth visual interpolation)
- **D3** — `FullSwipeExpandOverlay` widget in Stack above reveal panel, below child
- **D4** — `_fullSwipeTriggered` bool flag for gesture lock (avoids extending public `SwipeState`)
- **D5** — `fullSwipeRatio` computed inline in `_handleDragUpdate` every frame
- **D6** — Two new `SwipeFeedbackEvent` values; gated by `FullSwipeConfig.enableHaptic`
- **D7** — `triggerFullSwipe` on `SwipeController` / `executeTriggerFullSwipe` on `SwipeCellHandle`
- **D8** — Two new `SemanticLabel` fields on `SwipeSemanticConfig`; `Shift+Arrow` keyboard
- **D9** — `_animateOutDirectional(SwipeDirection)` for direction-aware exit animation
- **D10** — Delete/archive templates add `FullSwipeConfig` defaults; `SwipeAction` constructed internally

---

## Phase 1: Design Artifacts

- **Data Model**: [data-model.md](data-model.md) — all new/modified types, fields, lifecycle
- **Public API Contract**: [contracts/public-api.md](contracts/public-api.md) — full Dart signatures, behavioral contracts
- **Quickstart**: [quickstart.md](quickstart.md) — 8 usage scenarios, 30+ test checkpoints

---

## Implementation Clusters

```
Cluster A  Foundation (no dependencies)
  T001: Create FullSwipeConfig + FullSwipeProgressBehavior (RED test first)
  T002: Add fullSwipeRatio to SwipeProgress (RED test first)
  T003: Add fullSwipeConfig to LeftSwipeConfig + RightSwipeConfig (RED test first)
  T004: Add 2 values to SwipeFeedbackEvent enum

Cluster B  Gesture integration [after A]
  T005: RED tests -- full swipe past threshold triggers action
  T006: RED tests -- below full-swipe but above reveal = normal reveal
  T007: RED tests -- re-entry lock (gesture blocked during animation)
  T008: Implement _checkFullSwipeThreshold, _isFullSwipeArmed, _fullSwipeTriggered
  T009: Implement _applyFullSwipeAction + _animateOutDirectional
  T010: Wire into _handleDragUpdate and _handleDragEnd

Cluster C  Visual layer [after A, parallel with B]
  T011: RED tests -- expand animation plays; fullSwipeRatio values
  T012: RED tests -- other actions fade out; drag back reverses expansion
  T013: Implement FullSwipeExpandOverlay widget
  T014: Integrate FullSwipeExpandOverlay into SwipeActionCell Stack
  T015: Implement _fullSwipeBumpController (TweenSequence 1.0->1.15->1.0, 150ms)
  T016: Wire bump controller: fire on arm, suppress on Reduce Motion

Cluster D  Haptic feedback [after A, parallel with B+C]
  T017: RED tests -- haptic fires at threshold crossing + on activation
  T018: RED tests -- enableHaptic: false suppresses events
  T019: Add haptic fire calls to _checkFullSwipeThreshold and _applyFullSwipeAction

Cluster E  Controller & programmatic [after B]
  T020: Add executeTriggerFullSwipe to SwipeCellHandle
  T021: RED tests -- triggerFullSwipe fires action; no-op when not configured
  T022: Implement triggerFullSwipe on SwipeController

Cluster F  Callbacks & config validation [after A]
  T023: Add onFullSwipeTriggered parameter to SwipeActionCell
  T024: Add _validateFullSwipeConfigs (all asserts)

Cluster G  Accessibility [after B]
  T025: Add fullSwipeLeftLabel/fullSwipeRightLabel to SwipeSemanticConfig
  T026: RED tests -- screen reader announcement; Shift+Arrow keyboard trigger
  T027: Add Shift+Arrow handler in existing FocusNode.onKeyEvent
  T028: Update Semantics widget with full-swipe custom action labels

Cluster H  Integration scenarios [after B+C+D+E+F]
  T029: RED tests -- undo integration (full-swipe action undoable)
  T030: RED tests -- RTL directions correct
  T031: RED tests -- SwipeGroupController accordion closes siblings
  T032: RED tests -- left auto-trigger + full-swipe = two actions at two thresholds
  T033: RED tests -- right setToMax jumps to maxValue
  T034: RED tests -- disabled = zero overhead

Cluster I  Templates + testing utils [after H]
  T035: Update SwipeActionCell.delete with default FullSwipeConfig
  T036: Update SwipeActionCell.archive with default FullSwipeConfig
  T037: RED tests -- templates include fullSwipeConfig
  T038: Add SwipeTester.fullSwipeLeft + fullSwipeRight helpers
  T039: RED tests -- SwipeTester helpers work

Cluster J  Exports + polish [after all clusters]
  T040: Add full_swipe_config.dart to lib/swipe_action_cell.dart barrel
  T041: flutter analyze -- zero warnings
  T042: dart format .
  T043: Regression run -- all 383 existing tests pass
```

**Dependency graph**:
```
A --> B  [parallel]
A --> C  [parallel with B]
A --> D  [parallel with B, C]
B --> E
A --> F  [parallel with B, C, D]
B + C + D + E + F --> G  [parallel]
B + C + D + E + F + G --> H
H --> I
I --> J
```

---

## Key Implementation Notes

### `_handleDragUpdate` integration (Cluster B)

After computing `_controller.value = _applyResistance(...)`, call:

```dart
_checkFullSwipeThreshold(_controller.value.abs(), widgetWidth);
```

```dart
void _checkFullSwipeThreshold(double absOffset, double widgetWidth) {
  final cfg = _resolvedFullSwipeConfig(_lockedDirection);
  if (cfg == null || !cfg.enabled) {
    if (_isFullSwipeArmed) {
      _isFullSwipeArmed = false;
      _fullSwipeRatio = 0.0;
    }
    return;
  }
  final rawRatio = absOffset / widgetWidth;
  final activationThreshold = effectiveAnimationConfig.activationThreshold;
  _fullSwipeRatio = ((rawRatio - activationThreshold) /
          (cfg.threshold - activationThreshold))
      .clamp(0.0, 1.0);
  final nowArmed = rawRatio >= cfg.threshold;
  if (nowArmed != _isFullSwipeArmed) {
    _isFullSwipeArmed = nowArmed;
    if (cfg.enableHaptic) {
      _feedbackDispatcher?.fire(
        SwipeFeedbackEvent.fullSwipeThresholdCrossed,
        isForward: _dragIsForward,
      );
    }
    if (nowArmed && cfg.expandAnimation && !_fullSwipeTriggered) {
      _triggerFullSwipeBump();
    }
  }
}
```

### `_handleDragEnd` integration (Cluster B)

Before the normal zone/activation check, insert:

```dart
final fsCfg = _resolvedFullSwipeConfig(_lockedDirection);
if (fsCfg != null && fsCfg.enabled && _isFullSwipeArmed) {
  _applyFullSwipeAction(_lockedDirection, fsCfg);
  return;
}
```

### `_applyFullSwipeAction` (Cluster B)

```dart
void _applyFullSwipeAction(SwipeDirection direction, FullSwipeConfig cfg) {
  _fullSwipeTriggered = true;
  _isFullSwipeArmed = false;
  _fullSwipeRatio = 0.0;
  if (cfg.enableHaptic) {
    _feedbackDispatcher?.fire(
      SwipeFeedbackEvent.fullSwipeActivation,
      isForward: _dragIsForward,
    );
  }
  if (_dragIsForward &&
      cfg.fullSwipeProgressBehavior == FullSwipeProgressBehavior.setToMax) {
    final fwdCfg = _resolvedForwardConfig!;
    final oldValue = _progressValueNotifier!.value;
    _progressValueNotifier!.value = fwdCfg.maxValue;
    fwdCfg.onMaxReached?.call();
    fwdCfg.onProgressChanged?.call(fwdCfg.maxValue, oldValue);
  } else {
    cfg.action.onTap();
  }
  widget.onFullSwipeTriggered?.call(direction, cfg.action);
  _lastPostActionBehavior = cfg.postActionBehavior;
  switch (cfg.postActionBehavior) {
    case PostActionBehavior.snapBack:
      _isPostActionSnapBack = true;
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, 0.0);
    case PostActionBehavior.animateOut:
      _updateState(SwipeState.animatingOut);
      _animateOutDirectional(direction);
      if (widget.undoConfig != null) _startUndoWindow();
    case PostActionBehavior.stay:
      _fullSwipeTriggered = false;
      _updateState(SwipeState.revealed);
  }
}
```

### `_animateOutDirectional` (Cluster B)

```dart
void _animateOutDirectional(SwipeDirection direction) {
  if (MediaQuery.of(context).disableAnimations) {
    _controller.value = direction == SwipeDirection.right
        ? _widgetWidth * 1.5
        : -(_widgetWidth * 1.5);
    return;
  }
  final target = direction == SwipeDirection.right
      ? _widgetWidth * 1.5
      : -(_widgetWidth * 1.5);
  final spring = effectiveAnimationConfig.completionSpring;
  _controller.animateWith(SpringSimulation(
    SpringDescription(
        mass: spring.mass, stiffness: spring.stiffness, damping: spring.damping),
    _controller.value,
    target,
    0.0,
  ));
}
```

### Gesture lock release (Cluster B)

In `_handleAnimationStatusChange`, at the start of the `animatingToClose` and `animatingOut` completion branches:

```dart
if (_fullSwipeTriggered) _fullSwipeTriggered = false;
```

### SwipeTester helpers (Cluster I)

```dart
/// Drags the cell left past the full-swipe threshold (default 80%) and releases.
static Future<void> fullSwipeLeft(WidgetTester tester, Finder finder,
    {double ratio = 0.8}) async {
  final rect = tester.getRect(finder);
  await tester.drag(finder, Offset(-(rect.width * ratio), 0), warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Drags the cell right past the full-swipe threshold (default 80%) and releases.
static Future<void> fullSwipeRight(WidgetTester tester, Finder finder,
    {double ratio = 0.8}) async {
  final rect = tester.getRect(finder);
  await tester.drag(finder, Offset(rect.width * ratio, 0), warnIfMissed: false);
  await tester.pumpAndSettle();
}
```

---

## Post-Design Constitution Re-Check

All 10 principles confirmed compliant after Phase 1 design. No exceptions required. No gate violations. Proceed to `/speckit.tasks`.
