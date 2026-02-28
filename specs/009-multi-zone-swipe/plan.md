# Implementation Plan: Multi-Zone Swipe (F009)

**Branch**: `009-multi-zone-swipe`
**Spec**: `specs/009-multi-zone-swipe/spec.md`
**Status**: Ready for implementation

---

## Technical Context

| Item | Value |
|------|-------|
| Dart SDK | `>=3.4.0 <4.0.0` |
| Flutter SDK | `>=3.22.0` |
| Runtime dependencies | None (Flutter SDK only — Constitution IV) |
| Entry point | `lib/swipe_action_cell.dart` |
| Test utilities | `lib/testing.dart` |
| Feature prefix | F009 |
| Predecessor features | F001–F008 (all complete) |

---

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I — Composition over Inheritance | ✅ | `ZoneAwareBackground` wraps zone list; no base class |
| II — Explicit State Machine | ✅ | No new states added; zones act within existing `dragging → animatingToOpen → animatingToClose` transitions |
| III — Spring-Based Physics | ✅ | Existing spring physics unchanged; 150ms click effect uses standard `AnimationController` + `TweenSequence` (same pattern as `SwipeActionBackground`) |
| IV — Zero External Runtime Dependencies | ✅ | Only Flutter SDK |
| V — Controlled/Uncontrolled Pattern | ✅ | Zone logic is internal state; `SwipeController` API unchanged |
| VI — Const-Friendly Configuration | ✅ | `SwipeZone` and enum values are `const`-constructable |
| VII — Test-First | ✅ | Tests written before implementation in each task cluster |
| VIII — Dartdoc Everything | ✅ | All new public members require `///` |
| IX — Null Config = Feature Disabled | ✅ | `zones: null` = single-threshold mode; existing paths unchanged |
| X — 60 fps Budget | ✅ | Zone transitions and click effect use `AnimationController`; zone boundary detection in `AnimatedBuilder` frame loop |

---

## Phase 0: Research

> Completed. See `specs/009-multi-zone-swipe/research.md`.

**Key decisions**:
- `SwipeZone` + enums in `lib/src/core/swipe_zone.dart`
- Zone logic in `lib/src/zones/` (resolver + background widget)
- Zone tracking in `AnimatedBuilder` frame loop, gated on `_state == dragging`
- Active zone at release snapshotted in `_handleDragEnd`
- `zoneTransitionStyle` on each config object (not `SwipeVisualConfig`)
- Pre-first-zone background = transparent
- Visual click fires both directions; haptic fires forward-only

---

## Phase 1: Design & Contracts

> Completed. See `specs/009-multi-zone-swipe/data-model.md` and `specs/009-multi-zone-swipe/contracts/public-api.md`.

---

## Implementation Tasks

Tasks are ordered by dependency. Each cluster follows **Red → Green → Refactor** (Constitution VII).

---

### Cluster A — Core Value Types

#### T001 · Define `SwipeZone`, `ZoneTransitionStyle`, `SwipeZoneHaptic`

**File**: `lib/src/core/swipe_zone.dart` *(new)*

**What to implement**:

```dart
// ZoneTransitionStyle enum — 3 values: crossfade, slide, instant
// SwipeZoneHaptic enum — 3 values: light, medium, heavy

// SwipeZone immutable data class:
//   Fields: threshold (double, required), semanticLabel (String, required),
//           onActivated (VoidCallback?), stepValue (double?),
//           background (SwipeBackgroundBuilder?), color (Color?),
//           icon (Widget?), label (String?), hapticPattern (SwipeZoneHaptic?)
//   assert: threshold > 0.0 && threshold < 1.0
//   assert: semanticLabel.isNotEmpty
//   const constructor, copyWith, ==, hashCode, toString, ///docs
```

**Tests** (write first → `test/core/swipe_zone_test.dart`):
- `const SwipeZone(threshold: 0.5, semanticLabel: 'Archive')` constructs without error
- `SwipeZone(threshold: 0.0, ...)` throws AssertionError
- `SwipeZone(threshold: 1.0, ...)` throws AssertionError
- `SwipeZone(threshold: -0.1, ...)` throws AssertionError
- `SwipeZone(threshold: 1.1, ...)` throws AssertionError
- `SwipeZone(threshold: 0.5, semanticLabel: '')` throws AssertionError
- `copyWith` returns new instance with overridden fields
- `==` and `hashCode` equality by value
- `ZoneTransitionStyle.values` has exactly 3 members
- `SwipeZoneHaptic.values` has exactly 3 members

---

#### T002 · Implement `zone_resolver.dart` — pure zone functions

**File**: `lib/src/zones/zone_resolver.dart` *(new)*

**What to implement**:

```dart
// resolveActiveZoneIndex(List<SwipeZone> zones, double ratio) → int
//   Returns index of highest zone with threshold ≤ ratio, or -1 if none.
//   Assumes zones are already sorted ascending.

// resolveActiveZone(List<SwipeZone> zones, double ratio) → SwipeZone?
//   Convenience wrapper over resolveActiveZoneIndex. Returns null if -1.

// assertZonesValid(List<SwipeZone> zones, {bool progressive = false})
//   Asserts: zones.length <= 4
//   Asserts: thresholds strictly ascending
//   Asserts: each zone semanticLabel.isNotEmpty
//   Asserts if progressive: each zone stepValue != null && > 0
```

**Tests** (write first → `test/zones/zone_resolver_test.dart`):
- `resolveActiveZoneIndex([], 0.5)` → `-1`
- `resolveActiveZoneIndex([z(0.3)], 0.2)` → `-1`
- `resolveActiveZoneIndex([z(0.3)], 0.3)` → `0`
- `resolveActiveZoneIndex([z(0.3)], 0.5)` → `0`
- `resolveActiveZoneIndex([z(0.3), z(0.6)], 0.65)` → `1`
- `resolveActiveZoneIndex([z(0.3), z(0.6), z(0.9)], 0.95)` → `2`
- `resolveActiveZone(...)` returns null when no zone crossed, correct zone when crossed
- `assertZonesValid` throws on > 4 zones with message containing "at most 4"
- `assertZonesValid` throws on duplicate thresholds with message containing "ascending"
- `assertZonesValid` throws on descending thresholds
- `assertZonesValid` throws on missing semanticLabel
- `assertZonesValid(progressive: true)` throws on null stepValue
- `assertZonesValid(progressive: true)` passes when all stepValues present

---

### Cluster B — Config Extensions

#### T003 · Extend `RightSwipeConfig` with zone fields

**File**: `lib/src/config/right_swipe_config.dart` *(modify)*

**What to add**:
- `final List<SwipeZone>? zones` (default `null`)
- `final ZoneTransitionStyle zoneTransitionStyle` (default `ZoneTransitionStyle.instant`)
- In constructor `assert`: if `zones != null && zones.isNotEmpty`, call `assertZonesValid(zones!, progressive: true)`
- Update `copyWith`, `==`, `hashCode`
- Add `///` docs to new fields

**Tests** (write first → `test/config/right_swipe_config_test.dart`, extend existing):
- Existing config without zones still constructs and works
- `RightSwipeConfig(zones: [z1, z2])` constructs when thresholds valid
- `RightSwipeConfig(zones: [z2, z1])` throws AssertionError (wrong order)
- `RightSwipeConfig(zones: [z1, z2, z3, z4, z5])` throws "at most 4"
- `RightSwipeConfig(zones: [zNoStep])` throws missing stepValue assertion
- `copyWith(zones: newList)` returns new instance with updated zones
- `==` reflects zone list equality via `listEquals`

---

#### T004 · Extend `LeftSwipeConfig` with zone fields

**File**: `lib/src/config/left_swipe_config.dart` *(modify)*

**What to add**:
- `final List<SwipeZone>? zones` (default `null`)
- `final ZoneTransitionStyle zoneTransitionStyle` (default `ZoneTransitionStyle.instant`)
- In constructor `assert`: if `zones != null && zones.isNotEmpty`, call `assertZonesValid(zones!)`
- Update `copyWith`, `==`, `hashCode`
- Add `///` docs to new fields

**Tests** (write first → `test/config/left_swipe_config_test.dart`, extend existing):
- Existing config without zones still constructs and works
- `LeftSwipeConfig(mode: autoTrigger, zones: [z1, z2])` constructs when thresholds valid
- `LeftSwipeConfig(mode: autoTrigger, zones: [z2, z1])` throws (wrong order)
- `LeftSwipeConfig(mode: autoTrigger, zones: [z1, z2, z3, z4, z5])` throws "at most 4"
- Zone with `onActivated: null` does NOT throw (visual-only milestone allowed)
- `copyWith(zones: newList)` returns updated instance
- `==` reflects zone list equality

---

### Cluster C — Visual Zone Background

#### T005 · Implement `ZoneAwareBackground` widget

**File**: `lib/src/zones/zone_background.dart` *(new)*

**What to implement**:

```dart
// ZoneAwareBackground StatefulWidget:
//   Inputs: zones (List<SwipeZone>), progress (SwipeProgress),
//           transitionStyle (ZoneTransitionStyle)
//   State fields:
//     int _previousZoneIndex = -1
//     late AnimationController _clickController  // 150ms, for scale bump
//     late AnimationController _transitionController  // for crossfade/slide
//
//   In didUpdateWidget:
//     Compute newZoneIndex = resolveActiveZoneIndex(zones, progress.ratio)
//     If newZoneIndex != _previousZoneIndex:
//       Fire _clickController.forward(from: 0.0)    // visual click always
//       _previousZoneIndex = newZoneIndex
//
//   Pre-first-zone (newZoneIndex == -1): return SizedBox.shrink()
//   Active zone: render zone's color / icon / label / custom builder
//   Transition: based on transitionStyle
//     instant: immediate switch
//     crossfade: AnimatedSwitcher with FadeTransition
//     slide: AnimatedSwitcher with SlideTransition
//   Click effect: AnimatedBuilder over _clickController, applies scale bump
//                 (same TweenSequence pattern as SwipeActionBackground)
//   Reduced motion (MediaQuery.disableAnimations):
//     transitionStyle → instant, suppress click scale bump
```

**Tests** (write first → `test/zones/zone_background_test.dart`):
- Widget renders nothing when ratio < first zone threshold (pre-first-zone)
- Widget renders first zone color when ratio >= zone[0].threshold
- Widget renders second zone color when ratio >= zone[1].threshold
- Widget key changes on zone transition (triggers AnimatedSwitcher rebuild)
- `transitionStyle: instant` → no AnimatedSwitcher animation duration
- `transitionStyle: crossfade` → AnimatedSwitcher with fade curve
- `transitionStyle: slide` → AnimatedSwitcher with slide direction
- Reduced motion: transition is instant regardless of configured style
- Click effect controller fires when zone boundary is crossed
- Click effect fires on backward crossing (zone[1] → zone[0])

---

### Cluster D — Widget Integration

#### T006 · Add zone tracking fields and drag start reset

**File**: `lib/src/widget/swipe_action_cell.dart` *(modify)*

**What to add** to `SwipeActionCellState`:
```dart
// New fields:
int _lastHapticZoneIndex = -1;
SwipeZone? _activeZoneAtRelease;

// Helper:
List<SwipeZone>? _effectiveForwardZones() =>
    _resolvedForwardConfig?.zones?.isNotEmpty == true
        ? _resolvedForwardConfig!.zones
        : null;

List<SwipeZone>? _effectiveBackwardZones() =>
    _resolvedBackwardConfig?.zones?.isNotEmpty == true
        ? _resolvedBackwardConfig!.zones
        : null;
```

In `_handleDragStart`: reset `_lastHapticZoneIndex = -1` and `_activeZoneAtRelease = null`.

**Tests** (write first → `test/widget/swipe_action_cell_zones_test.dart`):
- On drag start, zone tracking fields reset to initial values
- `_effectiveForwardZones()` returns null when `zones` is null
- `_effectiveForwardZones()` returns null when `zones` is empty
- `_effectiveForwardZones()` returns zones list when non-empty

---

#### T007 · Zone haptic detection in `AnimatedBuilder`

**File**: `lib/src/widget/swipe_action_cell.dart` *(modify)*

**What to add** inside the `AnimatedBuilder` builder, after computing `progress`:

```dart
// If in dragging state AND forward direction has zones:
//   newZoneIndex = resolveActiveZoneIndex(forwardZones, ratio)
//   if newZoneIndex > _lastHapticZoneIndex && newZoneIndex >= 0:
//     fire zone haptic (zone.hapticPattern → SwipeZoneHaptic._execute())
//   _lastHapticZoneIndex = newZoneIndex
// Else fall through to existing _hapticThresholdFired single-threshold logic.
// Same symmetrical block for backward direction + backward zones.

// Add private helper: void _fireZoneHaptic(SwipeZoneHaptic? pattern)
//   Dispatches light/medium/heavy or no-op when null.
```

**Tests** (pump gesture, verify haptic channel calls via `tester.binding.defaultBinaryMessenger`):
- Crossing zone[0] forward fires zone[0].hapticPattern haptic
- Crossing zone[1] forward fires zone[1].hapticPattern haptic
- Retreating from zone[1] to zone[0] does NOT fire haptic
- Re-crossing zone[0] forward after retreat DOES fire haptic again
- Zone with `hapticPattern: null` → no haptic at that boundary
- Single-threshold config (no zones) → existing haptic behavior unchanged

---

#### T008 · Capture active zone at release in `_handleDragEnd`

**File**: `lib/src/widget/swipe_action_cell.dart` *(modify)*

**What to change** in `_handleDragEnd`:

```dart
// Before the existing shouldComplete check:
final forwardZones = _effectiveForwardZones();
final backwardZones = _effectiveBackwardZones();
final activeForwardZone = (forwardZones != null && _dragIsForward)
    ? resolveActiveZone(forwardZones, ratio)
    : null;
final activeBackwardZone = (backwardZones != null && _dragIsBackward)
    ? resolveActiveZone(backwardZones, ratio)
    : null;
_activeZoneAtRelease = activeForwardZone ?? activeBackwardZone;

// Update shouldComplete:
// When zones present: shouldComplete = isFling || _activeZoneAtRelease != null
// When no zones: existing logic (isFling || ratio >= activationThreshold)
```

**Tests**:
- Right swipe to zone[0] threshold → `_activeZoneAtRelease` == zone[0]
- Right swipe to zone[1] threshold → `_activeZoneAtRelease` == zone[1]
- Right swipe below zone[0] threshold → `_activeZoneAtRelease` == null → snap back
- Left swipe to zone[0] threshold → `_activeZoneAtRelease` == zone[0]
- Left swipe below all thresholds → snap back, no action fired
- `_activeZoneAtRelease` cleared to null after action fires

---

#### T009 · Use zone `stepValue` in `_applyProgressiveIncrement`

**File**: `lib/src/widget/swipe_action_cell.dart` *(modify)*

**What to change** in `_applyProgressiveIncrement`:

```dart
// If _activeZoneAtRelease != null:
//   Use _activeZoneAtRelease!.stepValue! as the step (not config.stepValue).
//   Then call existing overflow/clamp logic with that step value.
//   Fire zone's hapticPattern (or config.enableHaptic fallback).
//   Call config.onSwipeCompleted (unchanged).
// Else: existing behavior.
// Clear _activeZoneAtRelease = null.
```

**Tests** (all in `test/widget/swipe_action_cell_zones_test.dart`):
- Two-zone right swipe (z1: step 1.0, z2: step 5.0):
  - Release at zone[0] → value increments by 1.0
  - Release at zone[1] → value increments by 5.0
- Three-zone right swipe (0.3→+1, 0.6→+5, 0.9→+10):
  - Release at 35% → +1
  - Release at 65% → +5
  - Release at 92% → +10
- Single-threshold config (no zones) → step value unchanged
- Zone increment respects `overflowBehavior: clamp`
- `onSwipeCompleted` called with final value after zone increment

---

#### T010 · Use zone `onActivated` in `_applyIntentionalAction`

**File**: `lib/src/widget/swipe_action_cell.dart` *(modify)*

**What to change** in `_applyIntentionalAction`:

```dart
// If _activeZoneAtRelease != null:
//   Call _activeZoneAtRelease!.onActivated?.call() instead of config.onActionTriggered.
//   (null onActivated = visual-only milestone; no error)
//   Fire zone hapticPattern if present, else config.enableHaptic fallback.
//   Then apply postActionBehavior as before.
// Else: existing behavior.
// Clear _activeZoneAtRelease = null.
```

**Tests**:
- Two-zone left swipe (z1: archive, z2: delete):
  - Release at zone[0] → archive fires, delete does not
  - Release at zone[1] → delete fires, archive does not
  - Release below all zones → no action fires
- Three-zone left swipe (z1, z2, z3):
  - Release at zone[2] → only zone[2].onActivated fires
- Zone with `onActivated: null` (visual-only) → no callback, no error
- `postActionBehavior` still applies after zone action
- Single-threshold config (no zones) → onActionTriggered behavior unchanged

---

#### T011 · Route background to `ZoneAwareBackground` when zones present

**File**: `lib/src/widget/swipe_action_cell.dart` *(modify)*

**What to change** in `_buildBackground`:

```dart
// After resolving isForward and getting current direction's zones:
// If zones != null && zones.isNotEmpty:
//   Return ZoneAwareBackground(zones: zones, progress: progress,
//                               transitionStyle: resolvedConfig.zoneTransitionStyle)
// Else: existing rightBackground / leftBackground builder from SwipeVisualConfig.
```

**Tests**:
- Cell with zones renders `ZoneAwareBackground` widget
- Cell without zones renders `SwipeVisualConfig.rightBackground` builder output
- Switching from no-zones to zones mid-test reflects correct background type

---

#### T012 · Zone semantic label announcement

**File**: `lib/src/widget/swipe_action_cell.dart` *(modify)*

When `_currentZoneIndex` changes in the `AnimatedBuilder`, announce the newly active zone's `semanticLabel` via `SemanticsService.announce`. Suppress if `_currentZoneIndex == -1` (no zone active). Track `_currentZoneIndex` as a state field updated in the AnimatedBuilder.

```dart
// New field: int _currentZoneIndex = -1;
// In AnimatedBuilder, after computing zone index:
//   if newZoneIndex != _currentZoneIndex:
//     _currentZoneIndex = newZoneIndex
//     if newZoneIndex >= 0:
//       SemanticsService.announce(zones[newZoneIndex].semanticLabel, textDirection)
```

**Tests**:
- Dragging into zone[0] announces zone[0].semanticLabel
- Dragging into zone[1] announces zone[1].semanticLabel
- Retreating to zone[0] announces zone[0].semanticLabel again
- Retreating below all zones announces nothing (no-op)

---

### Cluster E — Exports & Backward Compat

#### T013 · Update barrel export

**File**: `lib/swipe_action_cell.dart` *(modify)*

Add:
```dart
export 'src/core/swipe_zone.dart';
export 'src/zones/zone_background.dart';
```

**Test**: `import 'package:swipe_action_cell/swipe_action_cell.dart'` exposes `SwipeZone`, `ZoneTransitionStyle`, `SwipeZoneHaptic`, `ZoneAwareBackground`.

---

#### T014 · Backward compatibility regression tests

**File**: `test/widget/swipe_action_cell_zones_test.dart` (a dedicated section)

Verify that all existing single-threshold test scenarios still pass unchanged:
- Right swipe with `stepValue: 1.0` (no zones) → increments by 1
- Left swipe with `onActionTriggered` (no zones) → fires callback
- `enableHaptic: true` single-threshold → fires existing haptic
- `SwipeVisualConfig.rightBackground` (no zones) → renders custom background
- `LeftSwipeConfig(mode: reveal)` (no zones) → reveal panel unchanged

---

## File Creation / Modification Summary

| Action | File | Task |
|--------|------|------|
| **NEW** | `lib/src/core/swipe_zone.dart` | T001 |
| **NEW** | `lib/src/zones/zone_resolver.dart` | T002 |
| **NEW** | `lib/src/zones/zone_background.dart` | T005 |
| **MODIFY** | `lib/src/config/right_swipe_config.dart` | T003 |
| **MODIFY** | `lib/src/config/left_swipe_config.dart` | T004 |
| **MODIFY** | `lib/src/widget/swipe_action_cell.dart` | T006–T012 |
| **MODIFY** | `lib/swipe_action_cell.dart` | T013 |
| **NEW** | `test/core/swipe_zone_test.dart` | T001 |
| **NEW** | `test/zones/zone_resolver_test.dart` | T002 |
| **NEW** | `test/zones/zone_background_test.dart` | T005 |
| **NEW** | `test/widget/swipe_action_cell_zones_test.dart` | T006–T014 |
| **MODIFY** | `test/config/right_swipe_config_test.dart` | T003 |
| **MODIFY** | `test/config/left_swipe_config_test.dart` | T004 |

---

## Dependency Order

```
T001 (SwipeZone types)
  └─ T002 (zone_resolver)
       └─ T003, T004 (config extensions — import SwipeZone + call assertZonesValid)
            └─ T005 (ZoneAwareBackground — needs SwipeZone, zone_resolver)
                 └─ T006 (widget fields — needs SwipeZone)
                      └─ T007 (haptic — needs T006 + zone_resolver)
                           └─ T008 (release capture — needs T006 + zone_resolver)
                                └─ T009 (progressive step — needs T008)
                                └─ T010 (intentional action — needs T008)
                                └─ T011 (background route — needs T005 + T006)
                                └─ T012 (semantic announce — needs T006)
                                     └─ T013 (barrel export)
                                          └─ T014 (backward compat tests)
```

---

## Key Implementation Notes

### `ZoneAwareBackground` animation controller scope

Both `_clickController` and `_transitionController` are owned by `ZoneAwareBackground`, a `StatefulWidget` with `SingleTickerProviderStateMixin` (or `TickerProviderStateMixin` if two controllers needed). The 150ms click animation must complete within one animation frame budget per FR-016/SC-004; since `AnimationController` runs on the platform vsync, this is automatically 60fps-compliant.

### Zone boundary detection is per-frame, not per-gesture-event

Haptic and semantic announcement detection happen in the `AnimatedBuilder` frame callback. Zone boundary tracking fields (`_lastHapticZoneIndex`, `_currentZoneIndex`) are updated there without calling `setState` — they are plain `int` fields, not `State` fields. This is safe because the `AnimatedBuilder` already rebuilds on every frame via `_controller`.

### `_activeZoneAtRelease` concurrency safety

There is no concurrency concern: all gesture callbacks, animation callbacks, and frame callbacks run on the main isolate in Flutter. `_activeZoneAtRelease` is written in `_handleDragEnd` and read in `_applyProgressiveIncrement` / `_applyIntentionalAction`, which are both called synchronously from the animation status listener — on the same frame or next frame.

### `const` on `SwipeZone` with callback fields

`const SwipeZone(threshold: 0.4, semanticLabel: 'Archive')` is valid (null callbacks). `SwipeZone(threshold: 0.4, semanticLabel: 'Archive', onActivated: someFunction)` is non-const but fully valid. This mirrors `LeftSwipeConfig` and `RightSwipeConfig`.

### Minimum zone count after clarification

FR-001 updated: zones list accepts 1–4 entries. A 1-entry list is silently treated as single-threshold (`assertZonesValid` with `minLength: 1`). `resolveActiveZone` already handles single-zone lists correctly.

---

## Acceptance Checklist

- [ ] `flutter analyze` → 0 warnings/errors
- [ ] `dart format --set-exit-if-changed .` → passes
- [ ] `flutter test` → all tests pass (no skips)
- [ ] New tests cover: 2-zone right swipe step values, 3-zone left swipe action firing, zone boundary haptic, visual transition between zones, release picks highest crossed, single-threshold backward compat, overlapping zones assert, >4 zones assert, ascending order assert, semantic labels per zone
- [ ] Semantics tree test: each zone's `semanticLabel` is announced when that zone becomes active
- [ ] Manual verify on device: smooth 60fps during zone transitions (no jank on mid-range Android)
