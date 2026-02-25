# Data Model: Foundational Gesture & Spring Animation

**Feature**: 001-gesture-animation
**Date**: 2026-02-25

---

## Entities

### SwipeDirection *(enum — already scaffolded)*

Represents the directional intent of a swipe gesture. Locked early in a gesture and held for
its full duration.

| Value | Meaning |
|-------|---------|
| `left` | Swipe toward the left edge of the screen |
| `right` | Swipe toward the right edge of the screen |
| `none` | No direction has been determined yet (idle or mid-lock window) |

**Invariants**:
- `none` is the initial value before a drag starts.
- Once locked (≠ `none`), direction MUST NOT change during the current gesture.
- Resets to `none` when the gesture ends and state returns to `idle`.

---

### SwipeState *(enum — already scaffolded)*

Represents the current phase of the swipe interaction state machine.

| Value | Entry condition | Exit to |
|-------|----------------|---------|
| `idle` | Initial state; animation settled at origin | `dragging` (drag start) |
| `dragging` | Drag start received; dead zone exceeded | `animatingToClose` or `animatingToOpen` (release) |
| `animatingToClose` | Release below threshold → snap-back spring | `idle` (animation done) |
| `animatingToOpen` | Release at/above threshold or fling → completion spring | `revealed` (animation done) |
| `revealed` | Completion animation settled at max translation | `dragging` (new drag start) |

**Transition diagram**:
```
idle ──drag start──▶ dragging
dragging ──release(below threshold)──▶ animatingToClose ──settled──▶ idle
dragging ──release(at/above threshold or fling)──▶ animatingToOpen ──settled──▶ revealed
animatingToClose ──drag start──▶ dragging  (interrupt)
animatingToOpen  ──drag start──▶ dragging  (interrupt)
revealed ──drag start──▶ dragging
```

**Invariants**:
- No state transition may be skipped. `idle → animatingToOpen` is forbidden without `dragging`.
- All interrupted animation states re-enter `dragging`, never `idle` directly.

---

### SwipeProgress *(data class — already scaffolded)*

An immutable snapshot of the gesture state at a single point in time. Consumed by observers
(e.g., background builders, callbacks) to reflect current progress without coupling to
implementation internals.

| Field | Type | Constraints | Meaning |
|-------|------|-------------|---------|
| `direction` | `SwipeDirection` | Any value | Current locked direction (or `none` if pre-lock) |
| `ratio` | `double` | 0.0 ≤ ratio ≤ 1.0 | Progress from origin (0.0) to max translation (1.0) |
| `isActivated` | `bool` | — | `true` when `ratio ≥ activationThreshold` |
| `rawOffset` | `double` | Any finite double | Signed pixel offset from origin (+ = right, − = left) |

**Equality**: `SwipeProgress` MUST implement value equality (`==` and `hashCode`).
**`copyWith`**: MUST be provided for incremental override support.
**Static constant**: `SwipeProgress.zero` = `(none, 0.0, false, 0.0)` for idle state.

---

### SpringConfig *(new — immutable data class)*

Encapsulates the physics parameters for a single spring animation. Directly maps to
`SpringDescription` in the animation system.

| Field | Type | Default | Constraints | Meaning |
|-------|------|---------|-------------|---------|
| `mass` | `double` | `1.0` | > 0.0 | Simulated mass of the object |
| `stiffness` | `double` | `500.0` | > 0.0 | Spring constant — higher = snappier |
| `damping` | `double` | `28.0` | > 0.0 | Damping coefficient — critical at 2√(mass×stiffness) |

**Preset relationships**:
- **Snap-back default**: mass=1.0, stiffness=400.0, damping=25.0 → slightly underdamped (~300ms,
  subtle bounce)
- **Completion default**: mass=1.0, stiffness=600.0, damping=32.0 → near-critically damped,
  decisive and snappy

**`copyWith`**: MUST be provided.
**`const` constructor**: MUST be provided.

---

### SwipeGestureConfig *(new — immutable config object)*

Groups all gesture-detection parameters. Controls when and how a gesture is recognized.

| Field | Type | Default | Constraints | Meaning |
|-------|------|---------|-------------|---------|
| `deadZone` | `double` | `12.0` | ≥ 0.0 | Min horizontal movement (logical px) before recognition |
| `enabledDirections` | `Set<SwipeDirection>` | `{left, right}` | Subset of {left, right} | Which swipe directions are active |
| `velocityThreshold` | `double` | `700.0` | > 0.0 | Min velocity (px/s) to trigger fling completion |

**Invariants**:
- `enabledDirections` MUST NOT contain `SwipeDirection.none`.
- If `enabledDirections` is empty, the widget passes all touches through to the child.
- `deadZone = 0.0` is valid (no dead zone — every touch starts a swipe).

**`copyWith`**: MUST be provided.
**`const` constructor**: MUST be provided.

---

### SwipeAnimationConfig *(new — immutable config object)*

Groups all animation and physics parameters. Controls how the cell moves and bounces.

| Field | Type | Default | Constraints | Meaning |
|-------|------|---------|-------------|---------|
| `activationThreshold` | `double` | `0.4` | 0.0 < value < 1.0 | Ratio at which a release triggers completion |
| `snapBackSpring` | `SpringConfig` | See presets | — | Spring used for sub-threshold release |
| `completionSpring` | `SpringConfig` | See presets | — | Spring used for at/above-threshold or fling release |
| `resistanceFactor` | `double` | `0.55` | 0.0 ≤ value ≤ 1.0 | Rubber-band resistance (0 = hard clamp, 1 = max resist) |
| `maxTranslationLeft` | `double?` | `null` | null OR > 0.0 | Max left drag in logical px; null = 60% of widget width |
| `maxTranslationRight` | `double?` | `null` | null OR > 0.0 | Max right drag in logical px; null = 60% of widget width |

**Invariants**:
- `maxTranslationLeft = 0.0` or `maxTranslationRight = 0.0` MUST disable that direction
  (equivalent to removing it from `enabledDirections`).
- When `maxTranslation*` is `null`, the widget resolves it from its rendered width after first
  layout. Default resolution = `widget.width * 0.6`.

**`copyWith`**: MUST be provided.
**`const` constructor**: MUST be provided (with `null` defaults for nullable fields).

---

### SwipeActionCell *(widget — update existing skeleton)*

The public-facing composable widget. Wraps any child and wires gesture + animation together.
Exposes state observations via callbacks and an optional listenable.

| Parameter | Type | Default | Meaning |
|-----------|------|---------|---------|
| `child` | `Widget` | required | The wrapped widget (any child) |
| `gestureConfig` | `SwipeGestureConfig` | `const SwipeGestureConfig()` | Gesture detection parameters |
| `animationConfig` | `SwipeAnimationConfig` | `const SwipeAnimationConfig()` | Animation physics parameters |
| `onStateChanged` | `ValueChanged<SwipeState>?` | `null` | Called whenever state machine transitions |
| `onProgressChanged` | `ValueChanged<SwipeProgress>?` | `null` | Called on every drag frame with current progress |
| `enabled` | `bool` | `true` | When `false`, passes child through with no gesture interception |

**Observable listenable** (read-only output):
- `ValueListenable<double> swipeOffsetListenable` — exposes the raw pixel offset as a listenable
  for consumers that want to drive their own visual effects (e.g., background opacity).

**State management**:
- Uncontrolled (default): internal `_SwipeActionCellState` manages all state.
- Controlled: `SwipeController` pattern deferred to future feature.

---

## State Transitions with Data Implications

| Transition | `SwipeState` changes to | `SwipeDirection` | `SwipeProgress.ratio` | `rawOffset` |
|-----------|------------------------|-----------------|----------------------|-------------|
| Drag start (within dead zone) | stays `idle` | stays `none` | stays 0.0 | stays 0.0 |
| Dead zone exceeded | `dragging` | locked | > 0.0, ≤ 1.0 | signed, ≠ 0 |
| Mid-drag update | `dragging` | locked | varies | varies |
| Release (below threshold) | `animatingToClose` | locked | decreasing | decreasing |
| Snap-back settled | `idle` | `none` | 0.0 | 0.0 |
| Release (at/above threshold or fling) | `animatingToOpen` | locked | increasing | increasing |
| Completion settled | `revealed` | locked | 1.0 | ±maxTranslation |
| New drag during animation | `dragging` | reset to `none` → relock | continues from current | continues |
| New drag from `revealed` | `dragging` | reset to `none` → relock | decreasing from 1.0 | from maxTranslation |
