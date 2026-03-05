# Data Model: Swipe Background Visual Layer

**Feature**: 002-swipe-background
**Date**: 2026-02-25

---

## Entities

### SwipeBackgroundBuilder *(typedef — already scaffolded in typedefs.dart)*

Signature for a function that builds the background widget for a given swipe direction.
Called on every animation frame while a swipe is in progress or a snap-back is running.

```
SwipeBackgroundBuilder = Widget Function(BuildContext context, SwipeProgress progress)
```

**Contract**:
- MUST return a widget without performing async operations or expensive computation.
- MUST be idempotent: calling with the same `SwipeProgress` twice MUST produce equivalent
  widget trees.
- Exceptions thrown by the function propagate normally (no catch by the host widget).
- The returned widget fills `Positioned.fill` inside the cell's `Stack` — its own size
  constraints are ignored in favor of the cell's full bounds.

---

### SwipeActionBackground *(new — StatefulWidget)*

A built-in, ready-to-use background widget that provides progress-reactive animations out of
the box. Intended as the default rendering choice when a developer does not need a custom
background.

**Location**: `lib/src/visual/swipe_action_background.dart`

| Parameter | Type | Required | Default | Meaning |
|-----------|------|----------|---------|---------|
| `icon` | `Widget` | Yes | — | The icon displayed in the background; scales and fades with `ratio` |
| `backgroundColor` | `Color` | Yes | — | Fill color of the background; intensifies (darkens 0–15%) as `ratio` → 1.0 |
| `foregroundColor` | `Color` | Yes | — | Color applied to `icon` via `IconTheme` and to `label` text |
| `progress` | `SwipeProgress` | Yes | — | Current swipe state; updated each frame by the parent builder |
| `label` | `String?` | No | `null` | Optional text shown below the icon in a column layout; omitted when null |
| `key` | `Key?` | No | `null` | Standard Flutter key |

**Animation behaviors**:

| Behavior | Implementation | Range |
|----------|---------------|-------|
| Icon opacity | `Opacity(opacity: ratio)` | 0.0 (invisible) → 1.0 (fully visible) |
| Icon scale | `Transform.scale(scale: ratio * (1.0 + bumpValue))` | 0.0 (no size) → 1.0+ (full size, briefly overshoots on bump) |
| Background color | HSL lightness −15% × ratio | `backgroundColor` at 0.0 → 15% darker at 1.0 |
| Threshold bump | `_bumpController` fires when `isActivated` transitions false→true; bumpValue 0→0.3→0 over 300ms | icon briefly scales +30% then returns |
| Label | `Text(label)` with `DefaultTextStyle` using `foregroundColor` | Static; no animation |

**State machine for bump**:

```
_wasActivated = false
  ↓ progress.isActivated transitions false → true
_bumpController.forward(from: 0.0)
  ↓ plays: 0.0 → 0.3 → 0.0 over 300ms
bumpValue feeds into scale multiplier
  ↓ progress.isActivated transitions true → false (snap-back crosses threshold)
No new bump fired (false → false is not a new transition)
```

**Invariants**:
- Does not own its own `AnimationController` for progress tracking — receives `SwipeProgress`
  externally each frame.
- Does own one `AnimationController` (`_bumpController`) for the threshold bump effect.
- Layout: `ColoredBox` fills full bounds; `Center(child: Column(mainAxisSize: min))` centers
  the icon + optional label vertically and horizontally.

---

### SwipeActionCell *(update — add background parameters)*

**New parameters added in this feature**:

| Parameter | Type | Default | Meaning |
|-----------|------|---------|---------|
| `leftBackground` | `SwipeBackgroundBuilder?` | `null` | Builder for the background revealed during a left swipe. `null` = no background for left swipes. |
| `rightBackground` | `SwipeBackgroundBuilder?` | `null` | Builder for the background revealed during a right swipe. `null` = no background for right swipes. |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | Clip mode applied to the Stack containing child and background. Use `Clip.none` to disable clipping. |
| `borderRadius` | `BorderRadius?` | `null` | When non-null, the Stack is clipped to this rounded rectangle shape. |

**Existing parameters**: unchanged.

**Internal changes**:
- `build()` wraps the `AnimatedBuilder` result in a clip (see research.md Q2).
- `AnimatedBuilder.builder` now computes `SwipeProgress` unconditionally (not just when
  `onProgressChanged != null`) and calls `_buildBackground`.
- The `Stack` introduces a `Positioned.fill` background slot in front of the clip,
  behind the animated child.

**Background slot visibility rules**:

| State | `progress.direction` | Background rendered? |
|-------|---------------------|----------------------|
| Idle | `none` | No (returns `SizedBox.shrink()`) |
| Dragging | locked (left/right) | Yes, if builder non-null |
| AnimatingToClose (snap-back) | locked (left/right) | Yes, ratio decreasing to 0 |
| AnimatingToOpen (completion) | locked (left/right) | Yes, ratio increasing to 1 |
| Revealed | locked (left/right) | Yes at ratio 1.0 (F4 takes over revealed-state behavior) |

**Null builder rule**: If the non-null direction's builder is null, `SizedBox.shrink()` is
returned — no error, no background, consistent with Principle IX (null = feature disabled).

---

## File Locations

| Entity | File |
|--------|------|
| `SwipeBackgroundBuilder` (typedef) | `lib/src/core/typedefs.dart` *(already exists)* |
| `SwipeActionBackground` | `lib/src/visual/swipe_action_background.dart` *(new)* |
| `SwipeActionCell` (updated) | `lib/src/widget/swipe_action_cell.dart` *(update)* |
| Barrel export | `lib/swipe_action_cell.dart` *(add SwipeActionBackground export)* |
| Tests — background widget | `test/visual/swipe_action_background_test.dart` *(new)* |
| Tests — widget integration | `test/widget/swipe_action_cell_test.dart` *(extend)* |

---

## Unchanged Entities (consumed, not modified)

- `SwipeProgress` — all four fields (`direction`, `ratio`, `isActivated`, `rawOffset`) are
  already present and sufficient for background builders.
- `SwipeDirection` — `none` sentinel is the idle-background gate.
- `SwipeState` — state machine lifecycle governs when `_lockedDirection` is reset to `none`.
- `SwipeGestureConfig`, `SwipeAnimationConfig`, `SpringConfig` — no changes.
