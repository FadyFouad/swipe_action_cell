# Public API Contract: Accessibility & RTL Layout Support (F8)

This document defines the full public API surface added or extended by F8. All items below
must be exported from `lib/swipe_action_cell.dart`.

---

## New Types

### `ForceDirection` (enum)

```dart
/// Controls how [SwipeActionCell] resolves its effective text direction.
enum ForceDirection {
  /// Read ambient [Directionality.of(context)] automatically (default).
  auto,

  /// Force left-to-right layout regardless of ambient directionality.
  ltr,

  /// Force right-to-left layout regardless of ambient directionality.
  rtl,
}
```

---

### `SemanticLabel` (value class)

```dart
/// A const-constructable holder for a semantic label that is either a
/// static string or a context-aware builder function.
///
/// Used as the field type in [SwipeSemanticConfig] to support both
/// static and locale-resolved labels.
@immutable
class SemanticLabel {
  /// A static label string.
  const SemanticLabel.string(String value);

  /// A builder function that resolves the label from [BuildContext],
  /// enabling locale-aware labels.
  const SemanticLabel.builder(String Function(BuildContext context) fn);

  /// Resolves the label for the given [context].
  ///
  /// Returns an empty string if the builder returns null or empty.
  String resolve(BuildContext context);
}
```

---

### `SwipeSemanticConfig` (config class)

```dart
/// Configuration for all accessibility labels and screen reader announcements
/// on a [SwipeActionCell].
///
/// All fields are optional. When null or resolving to an empty string, the
/// widget falls back to direction-adaptive built-in defaults.
@immutable
class SwipeSemanticConfig {
  const SwipeSemanticConfig({
    this.cellLabel,
    this.rightSwipeLabel,
    this.leftSwipeLabel,
    this.panelOpenLabel,
    this.progressAnnouncementBuilder,
  });

  /// Semantic label for the whole cell row, announced when the screen reader
  /// focuses the cell. Corresponds to [Semantics.label].
  ///
  /// Defaults to null (no cell-level label unless provided).
  final SemanticLabel? cellLabel;

  /// Label for the right-swipe (forward in LTR / backward in RTL) action as
  /// it appears in the screen reader's custom actions menu.
  ///
  /// Defaults to a direction-adaptive label such as "Swipe right to progress"
  /// (LTR) or "Swipe left to progress" (RTL).
  final SemanticLabel? rightSwipeLabel;

  /// Label for the left-swipe (backward in LTR / forward in RTL) action as
  /// it appears in the screen reader's custom actions menu.
  ///
  /// Defaults to a direction-adaptive label such as "Swipe left for actions"
  /// (LTR) or "Swipe right for actions" (RTL).
  final SemanticLabel? leftSwipeLabel;

  /// Announcement text spoken by the screen reader when the action panel opens.
  ///
  /// Defaults to "Action panel open".
  final SemanticLabel? panelOpenLabel;

  /// Override for the automatic progress announcement.
  ///
  /// When null, the widget generates "Progress incremented to N of M"
  /// automatically from the tracked progressive value. Provide this builder
  /// to customize the announcement format or locale.
  final String Function(double current, double max)? progressAnnouncementBuilder;

  /// Returns a copy with the specified fields replaced.
  SwipeSemanticConfig copyWith({...});
}
```

---

## `SwipeActionCell` — New Parameters

```dart
const SwipeActionCell({
  // ... existing parameters ...

  /// Accessibility labels and announcement configuration.
  ///
  /// When null, all labels use direction-adaptive defaults. When provided,
  /// any null field within this config also falls back to direction-adaptive defaults.
  this.semanticConfig,

  /// Semantic alias for right-swipe config (LTR) / left-swipe config (RTL).
  ///
  /// Use this when you want the same configuration to work correctly as the
  /// "forward" (progressive) action in both LTR and RTL layouts. Takes
  /// precedence over [rightSwipeConfig] in LTR and [leftSwipeConfig] in RTL.
  ///
  /// When null, the system falls back to [rightSwipeConfig] (LTR) or
  /// [leftSwipeConfig] (RTL) as applicable.
  this.forwardSwipeConfig,

  /// Semantic alias for left-swipe config (LTR) / right-swipe config (RTL).
  ///
  /// Use this when you want the same configuration to work correctly as the
  /// "backward" (intentional) action in both LTR and RTL layouts. Takes
  /// precedence over [leftSwipeConfig] in LTR and [rightSwipeConfig] in RTL.
  ///
  /// When null, the system falls back to [leftSwipeConfig] (LTR) or
  /// [rightSwipeConfig] (RTL) as applicable.
  this.backwardSwipeConfig,

  /// Manual override for direction resolution.
  ///
  /// Defaults to [ForceDirection.auto], which reads [Directionality.of(context)].
  /// Set to [ForceDirection.ltr] or [ForceDirection.rtl] to force a specific
  /// layout direction regardless of the ambient [Directionality].
  this.forceDirection = ForceDirection.auto,
})

final SwipeSemanticConfig? semanticConfig;
final RightSwipeConfig? forwardSwipeConfig;
final LeftSwipeConfig? backwardSwipeConfig;
final ForceDirection forceDirection;
```

---

## Behavioral Contracts

### RTL Config Resolution

Given physical drag direction `D` and effective RTL flag `isRtl`:

| Physical Direction | isRtl | Activates Config | Activates Background |
|---|---|---|---|
| right | false | `forwardSwipeConfig ?? rightSwipeConfig` | `visualConfig.rightBackground` |
| right | true | `backwardSwipeConfig ?? leftSwipeConfig` | `visualConfig.leftBackground` |
| left | false | `backwardSwipeConfig ?? leftSwipeConfig` | `visualConfig.leftBackground` |
| left | true | `forwardSwipeConfig ?? rightSwipeConfig` | `visualConfig.rightBackground` |

### Keyboard Navigation (desktop/web only)

| Key | State | Action |
|-----|-------|--------|
| Arrow (forward direction) | idle/dragging | Trigger progressive action |
| Arrow (backward direction) | idle/dragging | Open intentional action panel |
| Escape | revealed | Close panel; focus → cell |
| Tab | revealed | Focus cycles through panel action buttons |
| Tab | idle | Focus moves to next focusable widget |

Forward direction arrow = Right in LTR, Left in RTL.

### Screen Reader Custom Actions

Both actions are registered on the single top-level `Semantics` node using
`CustomSemanticsAction`. Only actions whose backing config is non-null are registered:

| Condition | Registered |
|-----------|-----------|
| `effectiveForwardConfig != null` | Forward action registered |
| `effectiveBackwardConfig != null` | Backward action registered |

### Focus Restoration

Focus returns to `_cellFocusNode` whenever `_state` transitions to `SwipeState.idle` from
`SwipeState.revealed` or `SwipeState.animatingToClose`, and `_cellFocusNode.hasFocus` was
`true` at the time the panel opened.

### Announcement Timing

| Event | Announcement |
|-------|-------------|
| Progressive action completes (snap-back settles) | "Progress incremented to N of M" (or custom) |
| Panel opens (`SwipeState.revealed`) | "Action panel open" (or custom `panelOpenLabel`) |

Announcements fire via `SemanticsService.announce()` in the animation completion callback,
not during the drag.

### Reduced Motion

When `MediaQuery.of(context).disableAnimations` is `true`:
- `_snapBack()` → `_controller.value = 0.0` (no simulation)
- `_animateToOpen()` → `_controller.value = targetOffset` (no simulation)
- All other behavior (state machine, callbacks, announcements) unchanged.
