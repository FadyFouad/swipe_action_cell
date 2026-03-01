# Public API Contract: Multi-Zone Swipe (F009)

This document defines the Dart public API surface introduced or modified by F009.
All types are exported from `package:swipe_action_cell/swipe_action_cell.dart`.

---

## New Types

### `SwipeZone`

```dart
@immutable
class SwipeZone {
  const SwipeZone({
    required double threshold,
    required String semanticLabel,
    VoidCallback? onActivated,
    double? stepValue,
    SwipeBackgroundBuilder? background,
    Color? color,
    Widget? icon,
    String? label,
    SwipeZoneHaptic? hapticPattern,
  });

  final double threshold;
  final String semanticLabel;
  final VoidCallback? onActivated;
  final double? stepValue;
  final SwipeBackgroundBuilder? background;
  final Color? color;
  final Widget? icon;
  final String? label;
  final SwipeZoneHaptic? hapticPattern;

  SwipeZone copyWith({ ... });

  @override bool operator ==(Object other);
  @override int get hashCode;
}
```

**Constraints enforced by assert**:
- `threshold > 0.0 && threshold < 1.0`
- `semanticLabel.isNotEmpty`

---

### `ZoneTransitionStyle`

```dart
enum ZoneTransitionStyle {
  /// Backgrounds cross-dissolve over the transition duration.
  crossfade,

  /// New background slides in from the swipe direction edge.
  slide,

  /// Immediate cut — no animation. Default and forced when reduced motion is on.
  instant,
}
```

---

### `SwipeZoneHaptic`

```dart
enum SwipeZoneHaptic {
  /// HapticFeedback.lightImpact()
  light,

  /// HapticFeedback.mediumImpact()
  medium,

  /// HapticFeedback.heavyImpact()
  heavy,
}
```

---

## Modified Types

### `RightSwipeConfig` — additive changes only

```dart
const RightSwipeConfig({
  // ... all existing fields unchanged ...

  // NEW:
  List<SwipeZone>? zones,              // default: null
  ZoneTransitionStyle zoneTransitionStyle, // default: ZoneTransitionStyle.instant
})
```

**New assert added** (fires only when `zones != null`):
```
'zones must have at most 4 entries for the right swipe direction.'
'Zone thresholds must be strictly ascending.'
'All zones must have a non-empty semanticLabel.'
'Progressive zones must each have a stepValue > 0.'
```

**`copyWith` signature** — adds `zones` and `zoneTransitionStyle` as optional override parameters.

---

### `LeftSwipeConfig` — additive changes only

```dart
const LeftSwipeConfig({
  // ... all existing fields unchanged ...

  // NEW:
  List<SwipeZone>? zones,              // default: null
  ZoneTransitionStyle zoneTransitionStyle, // default: ZoneTransitionStyle.instant
})
```

**New assert added** (fires only when `zones != null`):
```
'zones must have at most 4 entries for the left swipe direction.'
'Zone thresholds must be strictly ascending.'
'All zones must have a non-empty semanticLabel.'
```

**`copyWith` signature** — adds `zones` and `zoneTransitionStyle` as optional override parameters.

---

## Precedence Rules

| Scenario | Behavior |
|----------|----------|
| `zones: null` | Single-threshold mode — all F003/F004 behavior unchanged |
| `zones: []` | Treated as `null` — falls back to single-threshold |
| `zones: [one]` | Behaves as single-threshold at `zones[0].threshold` |
| `zones: [a, b]` | Multi-zone — highest crossed zone wins at release |
| Both `zones` and `stepValue` provided | `zones` takes precedence for per-release step value |
| Both `zones` and `onActionTriggered` provided | `zones` take precedence; `onActionTriggered` is ignored |

---

## Unchanged Surface

All other types in the package are unmodified:
- `SwipeProgress` — no new fields
- `SwipeVisualConfig` — no changes
- `SwipeSemanticConfig` — no changes
- `SwipeController` / `SwipeGroupController` — no changes
- `SwipeActionCell` widget constructor — no new parameters
