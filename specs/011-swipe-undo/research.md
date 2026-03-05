# Research: Swipe Action Undo/Revert Support (F011)

**Branch**: `011-swipe-undo` | **Date**: 2026-03-01

---

## Decision 1: Configuration Shape — `enableUndo: bool` vs `undoConfig: SwipeUndoConfig?`

**Decision**: Use `undoConfig: SwipeUndoConfig?` (null = undo disabled).

**Rationale**: Constitution IX and the Development Standards both prohibit boolean feature-flag
fields (`Boolean feature-flag fields are not permitted`). The spec's `enableUndo: bool` is a
specification-level concept. The correct Dart implementation translates it to the null-config
pattern: passing `null` to `SwipeActionCell.undoConfig` disables the feature entirely with zero
overhead (no timer allocated, no overlay rendered, no controller fields touched).

**Alternatives considered**:
- `enableUndo: bool` — explicitly prohibited by Constitution IX and Dev Standards. Rejected.
- Separate boolean field alongside `SwipeUndoConfig` — redundant; `SwipeUndoConfig?` is the
  single unambiguous toggle.

---

## Decision 2: Countdown Timer Architecture — Single `AnimationController` vs `Timer` + `AnimationController`

**Decision**: Two separate objects — one `dart:async Timer` for expiry, one `AnimationController`
for the progress bar visual.

**Rationale**: The spec clarifies that "expiry timer still runs; only the visual animation is
omitted" under `reduceMotion`. A single `AnimationController` cannot satisfy this: if we call
`controller.value = 0.0` immediately for `reduceMotion`, the `AnimationStatus.dismissed` listener
fires instantly, committing the undo immediately — wrong behavior. Decoupling expiry (Timer) from
the visual (AnimationController) lets us suppress the visual independently of the real clock.

**Architecture**:
- `Timer _undoTimer` — fires `_commitUndo()` after `undoConfig.duration`. Cancelled on
  `_triggerUndo()`, `dispose()`, and the start of each new undo window.
- `AnimationController _undoBarController` — animates 1.0 → 0.0 over `undoConfig.duration`.
  Under `reduceMotion` (`MediaQuery.disableAnimations`): never started (progress bar not shown);
  timer still runs normally.

**Alternatives considered**:
- Single `AnimationController` — cannot satisfy "timer still runs under reduceMotion". Rejected.
- `Timer.periodic` for tick-based countdown — wasteful; `AnimationController` already provides
  smooth interpolation. Rejected.

---

## Decision 3: Undo State Representation — New `SwipeState` vs Boolean Flag

**Decision**: Boolean flag `_undoPending` in `SwipeActionCellState`; NOT a new `SwipeState` enum
value.

**Rationale**: The undo window runs *after* the action animation completes. At that point, the
cell is in `idle` (after `snapBack`/`animateOut`) or `revealed` (after `stay`). Adding a new
`undoPending` state to `SwipeState` would mean the cell cannot accept new gestures while undo is
pending — but the spec requires that a new gesture *commits* the previous undo immediately. A
parallel flag is the correct model: the state machine continues operating normally; undo pending
is an orthogonal concern managed by `_undoPending: bool`.

`SwipeController` exposes `isUndoPending: bool` as a derived getter, reported via a new
`reportUndoPending(bool)` bridge method (same pattern as `reportProgress(double)`).

**Alternatives considered**:
- New `SwipeState.undoPending` — conflicts with gesture acceptance; complicates state machine
  transitions unnecessarily. Rejected.
- Store pending state only on controller — requires controller to exist; violates
  Controlled/Uncontrolled principle (V). Rejected.

---

## Decision 4: Undo Revert Animation for `animateOut` — Spring Parameters

**Decision**: Use an underdamped spring with `stiffness: 300.0`, `damping: 18.0` for the
"animate back in" reversal.

**Rationale**: The spec requires "visually distinct animation... different spring, slight bounce".
The existing springs are:
- `snapBackSpring`: stiffness 400, damping 25 (critically-damped, clean)
- `completionSpring`: stiffness 600, damping 32 (fast, firm)

An underdamped spring (damping ratio < 1.0) produces natural overshoot/bounce. With mass=1.0,
stiffness=300, damping=18: damping ratio = 18 / (2 * √(1.0 * 300)) ≈ 0.52 — clearly
underdamped, producing noticeable but not excessive bounce. This is perceptually distinct from
both existing springs and signals "reversal" rather than a normal close.

The undo spring config will be a package-internal constant on `SpringConfig`:
`SpringConfig.undoReveal = const SpringConfig(mass: 1.0, stiffness: 300.0, damping: 18.0)`

**Alternatives considered**:
- Re-use `snapBackSpring` — indistinguishable from a normal close. Rejected.
- Very high damping (overdamped, slow) — sluggish; poor UX. Rejected.

---

## Decision 5: `SwipeUndoOverlay` Rendering Strategy

**Decision**: `SwipeUndoOverlay` is positioned as an additional `Positioned` child in the
existing `Stack` inside `SwipeActionCell.build()`. It animates in/out using `AnimatedSwitcher`
or `AnimatedOpacity`.

**Rationale**: The existing widget already uses a `Stack` for layering the background behind the
child. Adding the overlay as a `Positioned` child (top or bottom, per `overlayConfig.position`)
requires zero architectural change to the widget tree structure. The overlay is conditionally
built only when `undoConfig != null` and `_undoPending` is true — satisfying the zero-overhead
guarantee when disabled.

The overlay itself is a separate `StatefulWidget` (`SwipeUndoOverlay`) that:
- Receives the `_undoBarController` animation for the progress bar
- Renders: description text + "Undo" button + `AnimatedBuilder` progress bar
- Uses `Semantics` for the "Undo" button (F8 integration, Constitution VIII)

**Alternatives considered**:
- `OverlayEntry` (global overlay) — unnecessarily complex; doesn't clip to cell bounds. Rejected.
- `SizeTransition` for overlay entry — adequate, but `AnimatedOpacity` is simpler and sufficient
  for a bar overlay. Chosen: simple fade-in via `AnimatedOpacity` wrapping the bar.

---

## Decision 6: `UndoData.revert()` Closure Safety

**Decision**: `revert` is a `VoidCallback` closure that captures `SwipeActionCellState` weakly
via `_triggerUndo()` method reference. `UndoData` is created fresh per undo window; the reference
becomes stale (and a no-op) after `_cancelUndoWindow()` is called.

**Rationale**: Capturing `this._triggerUndo` via a closure is safe in Dart — the `UndoData`
object holds a strong reference to the closure, but the closure captures `this` (the `State`).
If the `State` is disposed before `revert()` is called, the undo timer is cancelled in `dispose()`
first (FR-011: "Timer cleaned up on dispose"), so `revert()` from a stale `UndoData` will be a
no-op (guarded by `if (!mounted || !_undoPending) return`).

**Alternatives considered**:
- `WeakReference<SwipeActionCellState>` — unnecessary complexity; `dispose()` cleanup is
  sufficient. Rejected.

---

## Decision 7: `UndoData` type for `oldValue`/`newValue`

**Decision**: `double?` — `null` for intentional actions, numeric value for progressive actions.

**Rationale**: Progressive actions track a `double` cumulative value. Making these `double?`
matches the spec clarification (Q3) and avoids over-engineering with generics or discriminated
unions. Consumers receive `UndoData` via `onUndoAvailable(UndoData data)` and can check
`data.oldValue != null` to determine the action type.

**Alternatives considered**:
- Generic `UndoData<T>` — premature abstraction; no use case for non-double progressive values
  in this package. Rejected.
- Discriminated union (`ProgressiveUndoData` / `IntentionalUndoData`) — more correct but adds
  complexity not justified by the use case. Rejected.

---

## Integration Points in `SwipeActionCellState`

| Hook point | What F011 does |
|---|---|
| `_applyProgressiveIncrement()` | Capture `_oldProgressValue` before increment |
| `_applyPostActionBehavior()` | Call `_startUndoWindow(old, new)` after behavior applied |
| `_handleDragStart` | If `_undoPending`, call `_commitUndo()` before gesture handling |
| `didChangeDependencies()` / `initState()` | Create `_undoBarController` when `undoConfig != null` |
| `dispose()` | Cancel `_undoTimer`; dispose `_undoBarController` |
| `build()` | Wrap `Stack` with `SwipeUndoOverlay` when `_undoPending && undoConfig!.showBuiltInOverlay` |

---

## Dependency Matrix

| Cluster | Depends On |
|---|---|
| A — Core data types (`SwipeUndoConfig`, `UndoData`) | None |
| B — `SwipeUndoOverlay` widget | A |
| C — Controller extension (`isUndoPending`, `undo()`, etc.) | A |
| D — Widget integration | A, B, C |
| E — Barrel export | A |
| F — Regression verification | D |
