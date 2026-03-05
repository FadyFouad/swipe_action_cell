# Research: Scroll Conflict Resolution & Gesture Arena (F007)

**Branch**: `007-scroll-conflict` | **Date**: 2026-02-27

---

## Decision 1: Custom Recognizer vs. `GestureDetector` Workarounds

**Decision**: Replace `GestureDetector(onHorizontalDragStart: ...)` in `SwipeActionCellState.build` with a `RawGestureDetector` wrapping a custom `_SwipeHorizontalRecognizer extends HorizontalDragGestureRecognizer`.

**Rationale**: `GestureDetector` with `onHorizontalDragStart` installs a stock `HorizontalDragGestureRecognizer`. That recognizer accepts the gesture as soon as horizontal movement exceeds `kTouchSlop` (≈ 8 logical pixels), regardless of whether the gesture is diagonal. A 45-degree swipe accumulates `kTouchSlop` of horizontal movement when total movement is only `1.41 × kTouchSlop`, so it wins the arena before the vertical recognizer in the parent `ListView` has a chance. A custom subclass overrides `addAllowedPointer` and `handleEvent` to accumulate both axes and call `resolve(GestureDisposition.rejected)` when vertical dominates.

**Alternatives considered**:
- `GestureDetector` + `onPanStart/Update/End` with manual axis detection — avoids `RawGestureDetector` but creates a `PanGestureRecognizer` that competes with BOTH horizontal and vertical recognizers, degrading `PageView` and nested-list behavior.
- Listening on `ScrollController` to detect when the parent scrolled and then snapping back — reactive, not proactive; the swipe still activates for one frame before being cancelled.
- Using `AbsorbPointer` during scroll — breaks tap-through for the child during scroll momentum.

---

## Decision 2: Which `DragGestureRecognizer` Methods to Override

**Decision**: Override `addAllowedPointer(PointerDownEvent)` and `handleEvent(PointerEvent)`.

**Rationale**:
- `addAllowedPointer`: Called when a new pointer goes down. This is where edge-gesture rejection happens — if `respectEdgeGestures` is `true` and `event.position.dx < edgeWidth`, we skip calling `super.addAllowedPointer`, so the recognizer never enters the arena for that gesture.
- `handleEvent(PointerMoveEvent)`: Accumulates `dx` and `dy` from each `PointerMoveEvent`. Once the total movement exceeds `kTouchSlop` (so sampling noise is averaged out), we check the ratio. If `|absH| < |absV| × thresholdRatio`, we call `resolve(GestureDisposition.rejected)` and stop tracking. If horizontal dominates, we let `super.handleEvent` run, which continues the normal acceptance flow.
- `hasSufficientGlobalDistanceToConsider`: We do NOT override this. It already correctly gates on the horizontal component alone. Our override of `handleEvent` calls `resolve(rejected)` before `hasSufficientGlobalDistanceToConsider` can return `true` when the gesture is mostly vertical.

**Key constant**: `kTouchSlop = 8.0` logical pixels (from `flutter/gestures.dart`) — the minimum total movement before any drag recognizer considers accepting. We use this as the minimum total displacement before making the ratio decision, to avoid noise-based rejection on tiny early movements.

---

## Decision 3: `ScrollStartNotification` for Auto-Close Trigger

**Decision**: Use `NotificationListener<ScrollStartNotification>` wrapping the `RawGestureDetector`. Check `notification.dragDetails != null` to distinguish user-initiated from programmatic scroll.

**Rationale**:
- `ScrollStartNotification` is dispatched by `Scrollable` every time scrolling begins.
- Its `dragDetails` field is `DragStartDetails?` — non-null when triggered by a pointer gesture, `null` when triggered by a programmatic call such as `ScrollController.animateTo()` or `ScrollController.jumpTo()`. This matches FR-008 exactly.
- `return false` from `onNotification` so the notification bubbles up to parent scrollables (important for nested `PageView > ListView` scenarios).
- The `NotificationListener` is placed OUTSIDE the `LayoutBuilder` to ensure it captures scroll notifications from any ancestor `Scrollable`, not just a direct parent.

**Alternatives considered**:
- `ScrollController` listener — doesn't provide "user vs. programmatic" distinction; all position changes fire equally.
- `ScrollUpdateNotification` — fires on every frame of scrolling (too frequent); `ScrollStartNotification` fires once per gesture which is sufficient.
- `ScrollNotification` (supertype) — overly broad; `ScrollStartNotification` is precise.

---

## Decision 4: `RawGestureDetector` Factory Pattern

**Decision**: Use `GestureRecognizerFactoryWithHandlers<_SwipeHorizontalRecognizer>` with two closures — one to construct, one to configure.

**Rationale**: `RawGestureDetector` requires a `Map<Type, GestureRecognizerFactory>` where the key is the runtime type of the recognizer. `GestureRecognizerFactoryWithHandlers` is the standard Flutter utility that takes a constructor closure and an initializer closure. The initializer closure sets `onStart`, `onUpdate`, `onEnd` after construction. Config values (`thresholdRatio`, `edgeWidth`, `respectEdgeGestures`) are captured by the constructor closure from `effectiveGestureConfig` at build time — so config changes on rebuild automatically produce a fresh recognizer factory.

**Important**: `RawGestureDetector` re-uses existing recognizer instances across rebuilds when the type key does not change. The `_initializer` closure is re-called on each rebuild, so `onStart/Update/End` callbacks stay current even without recreating the recognizer object. Config fields captured by the constructor closure DO NOT update unless the recognizer is recreated. Therefore, the constructor closure must pass config values as named parameters, and the `key` or `widget.key` mechanism must ensure the recognizer is recreated when `effectiveGestureConfig` changes significantly. Alternatively, the recognizer stores a reference to a config getter lambda rather than fixed values.

**Simplest correct approach**: Store the config in mutable fields on the recognizer, and update them from the initializer closure on each rebuild.

---

## Decision 5: Edge Zone Width

**Decision**: Default to `20.0` logical pixels from the left edge. Expose via internal constant `_kEdgeGestureZoneWidth = 20.0`.

**Rationale**: Flutter's own `BackButtonBehavior` and the iOS simulator use 20 logical pixels as the edge-swipe detection zone (matches `EdgeDraggingAutoScroller` internals and iOS HIG recommendations). This matches the spec's assumption. The value is not user-configurable — the platform defines it. Documented as an assumption in spec.md.

---

## Decision 6: Where the Three New Fields Live

**Decision**: Add `horizontalThresholdRatio`, `closeOnScroll`, `respectEdgeGestures` to `SwipeGestureConfig` — no new top-level widget parameter.

**Rationale**: All three are gesture-recognition concerns that naturally belong alongside `deadZone` and `velocityThreshold`. `closeOnScroll` is triggered by a scroll event but controls swipe behavior, not scroll behavior — it belongs to the swipe gesture config. Adding them to `SwipeGestureConfig` means they inherit the three-level theme cascade (local → theme → default) for free and require no new constructor parameter on `SwipeActionCell`.

**Validation**: `horizontalThresholdRatio` MUST assert `>= 1.0` in the constructor. A ratio below 1.0 would classify vertical gestures as horizontal, which is logically inverted.

---

## Decision 7: State Machine — No New States

**Decision**: Reuse existing states (`idle → dragging → animatingToOpen → revealed → animatingToClose → idle`). Auto-close on scroll triggers `executeClose()` which transitions `revealed → animatingToClose`.

**Rationale**: `executeClose()` is already defined on `SwipeCellHandle` and implemented in `SwipeActionCellState`. The `NotificationListener` callback calls `executeClose()` directly. No new state is needed. This satisfies Constitution II without amendment.

---

## Decision 8: `const` Compatibility for New Config Fields

**Decision**: `horizontalThresholdRatio` and `respectEdgeGestures` can be `const`. `closeOnScroll` is a `bool`, also `const`-compatible. All new fields have `const`-compatible types and defaults, so `SwipeGestureConfig()` stays constructable with `const`.

**Rationale**: Constitution VI requires all config objects to be `const`-constructable. All three new fields are primitives (`double`, `bool`), so this is satisfied without any architecture change.
