# Research: Multi-Zone Swipe (F009)

## D1 — Zone model file location

**Decision**: `lib/src/core/swipe_zone.dart`
**Rationale**: All domain-level value types (`SwipeProgress`, `SwipeState`, `SwipeDirection`) live in `lib/src/core/`. `SwipeZone` is a pure data value object with no widget or framework coupling, so it belongs here. `ZoneTransitionStyle` and `SwipeZoneHaptic` are also placed here because they are used by `SwipeZone` directly.
**Alternatives considered**: Placing inside `lib/src/zones/` — rejected because pure data classes with no logic should be in `core/`.

---

## D2 — Zone management namespace

**Decision**: `lib/src/zones/` containing `zone_resolver.dart` and `zone_background.dart`.
**Rationale**: The zone-specific computation (resolving active zone, validating list) and the zone-specific visual widget are cohesive concerns that warrant a dedicated namespace, consistent with the feature-first directory structure in CLAUDE.md.
**Alternatives considered**: Inlining everything into `lib/src/widget/swipe_action_cell.dart` — rejected because it would bloat the already 1000-line file and make the zone logic untestable in isolation.

---

## D3 — Per-zone haptic type

**Decision**: `SwipeZoneHaptic` enum with three values: `light`, `medium`, `heavy`. Maps to `HapticFeedback.lightImpact()`, `.mediumImpact()`, `.heavyImpact()` respectively.
**Rationale**: The codebase already uses `HapticFeedback.lightImpact()` and `.mediumImpact()` directly in the widget (F003/F004 pattern). F011 (Feedback) has not yet been implemented; introducing a small enum here mirrors the planned F011 taxonomy without depending on it. A per-zone haptic null means no haptic at that boundary (FR-022).
**Alternatives considered**: Reusing a string identifier — rejected (not const-friendly, brittle). Waiting for F011 — rejected (creates a spec dependency; F011 will be able to subsume this enum).

---

## D4 — Zone-aware background widget architecture

**Decision**: `ZoneAwareBackground` widget in `lib/src/zones/zone_background.dart`. It takes `zones`, `progress` (ratio + direction), and `transitionStyle`. Internally it owns:
- An `AnimationController _clickController` (150ms, per FR-016) for the scale bump.
- An `AnimationController _transitionController` for crossfade/slide transitions.
- `int _previousZoneIndex = -1` to detect boundary crossings.

The `_buildBackground` method in `SwipeActionCellState` checks whether zones are configured for the current direction. If so, it delegates to `ZoneAwareBackground`; otherwise it falls through to the existing `SwipeVisualConfig.leftBackground` / `.rightBackground` builder.
**Rationale**: Encapsulating zone visual logic in its own `StatefulWidget` keeps the parent widget's `AnimatedBuilder` frame loop focused on offset tracking and avoids deeply nested setState calls. The existing `SwipeActionBackground` widget follows the same encapsulation pattern.
**Alternatives considered**: Extending `SwipeActionBackground` — rejected because that widget is single-zone by design; extension would force breaking changes.

---

## D5 — Zone boundary haptic detection site

**Decision**: Detected inside the `AnimatedBuilder` builder closure in `SwipeActionCellState.build`, gated on `_state == SwipeState.dragging`. A new `int _lastHapticZoneIndex = -1` field tracks the last zone at which haptic fired. Reset to `-1` on each drag start.
**Rationale**: The `AnimatedBuilder` fires on every animation frame, making it the correct place for per-frame threshold comparisons — identical to the existing `_hapticThresholdFired` guard for single-threshold haptic. Gating on `SwipeState.dragging` prevents false triggers during snap-back animations when the ratio passes through zone thresholds in reverse.
**Alternatives considered**: Detecting in `_handleDragUpdate` — rejected because gesture events are coarser than frame events and may miss rapid crossings on fast devices.

---

## D6 — Active zone at release

**Decision**: A `SwipeZone? _activeZoneAtRelease` field set inside `_handleDragEnd` immediately before triggering the open animation. Cleared to `null` after `_applyProgressiveIncrement` / `_applyIntentionalAction` consume it.
**Rationale**: `_handleDragEnd` already computes `ratio` at release time (from `_controller.value / maxT`). Computing the active zone there and caching it avoids recomputing it in the async animation-settled callbacks.
**Alternatives considered**: Re-computing in `_applyProgressiveIncrement` — rejected because `_controller.value` may have changed by the time the animation settles.

---

## D7 — `zoneTransitionStyle` placement

**Decision**: Add `zoneTransitionStyle: ZoneTransitionStyle` as a field on both `RightSwipeConfig` and `LeftSwipeConfig`, defaulting to `ZoneTransitionStyle.instant`.
**Rationale**: Zones are already scoped per config object; keeping the visual transition style alongside the zone list is the least-surprise API. The default of `instant` matches the spec Assumption and is the simplest fallback.
**Alternatives considered**: Placing in `SwipeVisualConfig` — rejected because `SwipeVisualConfig` is shared across both directions and doesn't know which direction is currently active during rendering.

---

## D8 — Pre-first-zone background state

**Decision**: When `ratio < zones[0].threshold`, `ZoneAwareBackground` renders `const SizedBox.shrink()` (transparent, zero-size). No zone background is visible.
**Rationale**: Matches clarification Q2. Consistent with the existing `SwipeVisualConfig.leftBackground` / `.rightBackground` pattern where background visibility is driven by the builder returning whatever it chooses.
**Alternatives considered**: Fading in the first zone's background at reduced opacity — rejected per clarification.

---

## D9 — Visual click effect on backward drag

**Decision**: `ZoneAwareBackground` fires the 150ms scale-bump animation on BOTH forward and backward zone boundary crossings (when `_previousZoneIndex != newZoneIndex`). `_lastHapticZoneIndex` tracking in the widget fires haptic ONLY on forward crossing (newZoneIndex > _lastHapticZoneIndex).
**Rationale**: Matches clarification Q3 and FR-016 / FR-020 separation.

---

## D10 — Backward compatibility wire-up

**Decision**: When `zones` is `null` or empty on a config, all existing code paths execute exactly as before. `_applyProgressiveIncrement` reads `config.stepValue`; `_applyIntentionalAction` calls `config.onActionTriggered`. Zone code paths are entered only when `effectiveZones(config)` is non-null and non-empty.
**Rationale**: FR-012 is a hard constraint. The `zones` field is optional with `null` default in both configs. A helper `_effectiveZones(config)` encapsulates the null/empty guard in a single place.
