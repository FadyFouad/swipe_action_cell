# Data Model: Multi-Zone Swipe (F009)

## New Types

### `SwipeZone` (value object, `lib/src/core/swipe_zone.dart`)

Represents a single activation zone within a swipe direction.

| Field | Type | Required | Constraint | Description |
|-------|------|----------|------------|-------------|
| `threshold` | `double` | Yes | `0.0 < threshold < 1.0` | Ratio of full swipe extent at which this zone activates |
| `semanticLabel` | `String` | Yes | Non-empty | Announced by screen readers when this zone becomes active |
| `onActivated` | `VoidCallback?` | No | — | Fired when this is the highest crossed zone at release (intentional/left direction) |
| `stepValue` | `double?` | No | `> 0` when present | Increment applied when this zone is the highest crossed at release (progressive/right direction). Asserted non-null for progressive zones. |
| `background` | `SwipeBackgroundBuilder?` | No | — | Custom background builder parameterized by `SwipeProgress` |
| `color` | `Color?` | No | — | Flat background color (used when `background` is null) |
| `icon` | `Widget?` | No | — | Icon displayed in the zone background |
| `label` | `String?` | No | — | Display text shown below icon in the zone background |
| `hapticPattern` | `SwipeZoneHaptic?` | No | — | Haptic fired when this zone boundary is crossed (forward direction). Null = no haptic. |

**Invariants (asserted on construction)**:
- `threshold > 0.0 && threshold < 1.0`
- `semanticLabel.isNotEmpty`

**Constitution compliance**: `@immutable`, `const` constructor, `copyWith`, `==` / `hashCode`.

---

### `ZoneTransitionStyle` (enum, `lib/src/core/swipe_zone.dart`)

Controls how the background transitions when dragging across zone boundaries.

| Value | Behavior |
|-------|----------|
| `crossfade` | Old zone background fades out, new one fades in, simultaneously |
| `slide` | New zone background slides in from the swipe direction edge |
| `instant` | Immediate cut between backgrounds (default; always used in reduced-motion mode) |

---

### `SwipeZoneHaptic` (enum, `lib/src/core/swipe_zone.dart`)

Maps to Flutter's platform haptic channels.

| Value | Flutter API |
|-------|-------------|
| `light` | `HapticFeedback.lightImpact()` |
| `medium` | `HapticFeedback.mediumImpact()` |
| `heavy` | `HapticFeedback.heavyImpact()` |

---

## Modified Types

### `RightSwipeConfig` (extends existing, `lib/src/config/right_swipe_config.dart`)

Two new optional fields added; all existing fields unchanged.

| New Field | Type | Default | Description |
|-----------|------|---------|-------------|
| `zones` | `List<SwipeZone>?` | `null` | When non-null and non-empty, overrides single-threshold behavior. 1–4 entries. |
| `zoneTransitionStyle` | `ZoneTransitionStyle` | `ZoneTransitionStyle.instant` | Visual transition between zone backgrounds |

**Validation** (in constructor `assert`):
- If `zones != null`: length ≤ 4 (FR-004)
- If `zones != null`: thresholds strictly ascending (FR-003)
- If `zones != null`: each zone has non-empty `semanticLabel` (FR-006)
- If `zones != null`: each zone has non-null `stepValue > 0` (FR-011)

**`copyWith` update**: includes both new fields.

---

### `LeftSwipeConfig` (extends existing, `lib/src/config/left_swipe_config.dart`)

Two new optional fields added; all existing fields unchanged.

| New Field | Type | Default | Description |
|-----------|------|---------|-------------|
| `zones` | `List<SwipeZone>?` | `null` | When non-null and non-empty, overrides single-threshold behavior. 1–4 entries. |
| `zoneTransitionStyle` | `ZoneTransitionStyle` | `ZoneTransitionStyle.instant` | Visual transition between zone backgrounds |

**Validation** (in constructor `assert`):
- If `zones != null`: length ≤ 4 (FR-004)
- If `zones != null`: thresholds strictly ascending (FR-003)
- If `zones != null`: each zone has non-empty `semanticLabel` (FR-006)

(No `stepValue` assertion — intentional zones allow `onActivated: null` per FR-009 visual-only milestone allowance.)

---

## Runtime Concepts (not persisted)

### `ActiveZone` (computed, not a class)

The result of `resolveActiveZone(zones, ratio)`: the `SwipeZone` whose threshold is ≤ current ratio, choosing the highest such zone. Returns `null` when no zone's threshold is met.

Lifecycle:
- Computed during `AnimatedBuilder` (for visual/haptic feedback).
- Snapshot in `_handleDragEnd` → stored as `_activeZoneAtRelease: SwipeZone?`.
- Consumed in `_applyProgressiveIncrement` / `_applyIntentionalAction`.
- Cleared to `null` after consumption.

---

## New Files Summary

| File | Contents |
|------|----------|
| `lib/src/core/swipe_zone.dart` | `SwipeZone`, `ZoneTransitionStyle`, `SwipeZoneHaptic` |
| `lib/src/zones/zone_resolver.dart` | `resolveActiveZone()`, `resolveActiveZoneIndex()`, `assertZonesValid()` |
| `lib/src/zones/zone_background.dart` | `ZoneAwareBackground` (StatefulWidget) |

## Modified Files Summary

| File | Change |
|------|--------|
| `lib/src/config/right_swipe_config.dart` | Add `zones`, `zoneTransitionStyle` fields + assertions |
| `lib/src/config/left_swipe_config.dart` | Add `zones`, `zoneTransitionStyle` fields + assertions |
| `lib/src/widget/swipe_action_cell.dart` | Zone tracking, haptic, release logic, background routing |
| `lib/swipe_action_cell.dart` | Export `SwipeZone`, `ZoneTransitionStyle`, `SwipeZoneHaptic` |
