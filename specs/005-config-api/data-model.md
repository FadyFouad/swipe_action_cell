# Data Model: Consolidated Configuration API & Theme Support (F005)

**Branch**: `005-config-api` | **Date**: 2026-02-26

---

## Entity Overview

F005 introduces three new entities and modifies three existing ones. The two renamed config
types (`RightSwipeConfig`, `LeftSwipeConfig`) are clean renames with new assertions added.
Gesture and animation configs gain factory preset constructors. The widget constructor changes
its parameter set.

| Entity | Status | File |
|--------|--------|------|
| `RightSwipeConfig` | New (renamed from `ProgressiveSwipeConfig`) | `lib/src/config/right_swipe_config.dart` |
| `LeftSwipeConfig` | New (renamed from `IntentionalSwipeConfig`) | `lib/src/config/left_swipe_config.dart` |
| `SwipeVisualConfig` | New | `lib/src/config/swipe_visual_config.dart` |
| `SwipeActionCellTheme` | New | `lib/src/config/swipe_action_cell_theme.dart` |
| `SwipeController` | New (stub) | `lib/src/controller/swipe_controller.dart` |
| `SwipeGestureConfig` | Modified (add presets) | `lib/src/gesture/swipe_gesture_config.dart` |
| `SwipeAnimationConfig` | Modified (add presets + assert) | `lib/src/animation/swipe_animation_config.dart` |
| `SwipeActionCell` | Modified (new constructor) | `lib/src/widget/swipe_action_cell.dart` |
| `ProgressiveSwipeConfig` | Deleted | `lib/src/actions/progressive/progressive_swipe_config.dart` |
| `IntentionalSwipeConfig` | Deleted | `lib/src/actions/intentional/intentional_swipe_config.dart` |

---

## New Entities

### `RightSwipeConfig`

Renamed from `ProgressiveSwipeConfig`. All fields and semantics preserved. Located in
`lib/src/config/right_swipe_config.dart`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `value` | `double?` | `null` | Externally-managed progress value (controlled mode) |
| `initialValue` | `double` | `0.0` | Starting cumulative value in uncontrolled mode |
| `stepValue` | `double` | `1.0` | Fixed increment per successful swipe (must be > 0) |
| `maxValue` | `double` | `double.infinity` | Upper bound for cumulative value |
| `minValue` | `double` | `0.0` | Lower bound and wrap target |
| `overflowBehavior` | `OverflowBehavior` | `.clamp` | How to handle overflow at `maxValue` |
| `dynamicStep` | `DynamicStepCallback?` | `null` | Callback returning step size for next swipe |
| `showProgressIndicator` | `bool` | `false` | Whether to render a persistent progress bar |
| `progressIndicatorConfig` | `ProgressIndicatorConfig?` | `null` | Progress bar appearance |
| `enableHaptic` | `bool` | `false` | Whether haptic fires at swipe milestones |
| `onProgressChanged` | `ProgressChangeCallback?` | `null` | Fires when cumulative value changes |
| `onMaxReached` | `VoidCallback?` | `null` | Fires when value reaches or would exceed `maxValue` |
| `onSwipeStarted` | `VoidCallback?` | `null` | Fires when right-swipe direction is locked |
| `onSwipeCompleted` | `ValueChanged<double>?` | `null` | Fires after successful swipe settles |
| `onSwipeCancelled` | `VoidCallback?` | `null` | Fires when right swipe released below threshold |

**Validation** (debug-mode assertions):
- `stepValue > 0.0` — message: `"stepValue must be > 0, got $stepValue"`
- `minValue < maxValue` — message: `"minValue ($minValue) must be < maxValue ($maxValue)"`

**Constructor**: `const RightSwipeConfig({...})`
**copyWith**: all fields nullable in signature; returns new instance.

---

### `LeftSwipeConfig`

Renamed from `IntentionalSwipeConfig`. All fields and semantics preserved. A new assertion is
added for reveal mode + empty actions. Located in `lib/src/config/left_swipe_config.dart`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `mode` | `LeftSwipeMode` | required | `autoTrigger` or `reveal` |
| `actions` | `List<SwipeAction>` | `const []` | Buttons shown in reveal panel (1–3) |
| `actionPanelWidth` | `double?` | `null` | Panel width override; auto-calculated when null |
| `postActionBehavior` | `PostActionBehavior` | `.snapBack` | Cell position after auto-trigger fires |
| `requireConfirmation` | `bool` | `false` | Whether a second gesture confirms the action |
| `enableHaptic` | `bool` | `false` | Whether haptic fires at swipe milestones |
| `onActionTriggered` | `VoidCallback?` | `null` | Fires when auto-trigger action executes |
| `onSwipeCancelled` | `VoidCallback?` | `null` | Fires when swipe released below threshold |
| `onPanelOpened` | `VoidCallback?` | `null` | Fires when reveal panel animation settles open |
| `onPanelClosed` | `VoidCallback?` | `null` | Fires when reveal panel closes (any trigger) |

**Validation** (debug-mode assertions):
- `actionPanelWidth == null || actionPanelWidth > 0` — message: `"actionPanelWidth must be > 0 when provided, got $actionPanelWidth"`
- `mode != LeftSwipeMode.reveal || actions.isNotEmpty` — message: `"LeftSwipeConfig in reveal mode requires at least one action, but actions is empty."`

**Constructor**: `const LeftSwipeConfig({required this.mode, ...})`
**copyWith**: all fields nullable in signature; returns new instance.

---

### `SwipeVisualConfig`

New entity consolidating the four visual presentation parameters previously on `SwipeActionCell`.
Located in `lib/src/config/swipe_visual_config.dart`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `leftBackground` | `SwipeBackgroundBuilder?` | `null` | Builder for background during left swipe |
| `rightBackground` | `SwipeBackgroundBuilder?` | `null` | Builder for background during right swipe |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | How the background+child stack is clipped |
| `borderRadius` | `BorderRadius?` | `null` | Optional rounded corners for clipping |

**Constructor**: `const SwipeVisualConfig({...})`
**copyWith**: all fields nullable in signature; returns new instance.

**Note on `SwipeBackgroundBuilder`**: Reuses existing typedef from `lib/src/core/typedefs.dart`:
`typedef SwipeBackgroundBuilder = Widget Function(BuildContext context, SwipeProgress progress);`

---

### `SwipeActionCellTheme`

New entity. Implements `ThemeExtension<SwipeActionCellTheme>`. Installed in `ThemeData.extensions`
at the app level to provide widget-tree-wide defaults. Located in
`lib/src/config/swipe_action_cell_theme.dart`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `rightSwipeConfig` | `RightSwipeConfig?` | `null` | Default right-swipe config for all cells |
| `leftSwipeConfig` | `LeftSwipeConfig?` | `null` | Default left-swipe config for all cells |
| `gestureConfig` | `SwipeGestureConfig?` | `null` | Default gesture config for all cells |
| `animationConfig` | `SwipeAnimationConfig?` | `null` | Default animation config for all cells |
| `visualConfig` | `SwipeVisualConfig?` | `null` | Default visual config for all cells |

**Constructor**: `const SwipeActionCellTheme({...})`

**Static API**:
- `SwipeActionCellTheme.maybeOf(BuildContext context)` → `SwipeActionCellTheme?`
  Returns the nearest `SwipeActionCellTheme` extension from `Theme.of(context)`, or `null`.

**ThemeExtension contract**:
- `copyWith({...})` — all fields nullable; returns new instance.
- `lerp(ThemeExtension<SwipeActionCellTheme>? other, double t)` — hard cutover:
  returns `other` when `t >= 1.0`; returns `this` otherwise. No numeric interpolation.

---

### `SwipeController`

New stub entity. Reserved for full implementation in F007. Located in
`lib/src/controller/swipe_controller.dart`.

| Aspect | Value |
|--------|-------|
| Supertype | `ChangeNotifier` |
| Public API | `dispose()` only (inherited) |
| Behavior | No-op in F005 |

**Constructor**: `SwipeController()` (no `const` — `ChangeNotifier` is mutable)

---

## Modified Entities

### `SwipeGestureConfig` (Modified)

Two factory preset constructors are added. All existing fields and defaults are unchanged.

| Preset | `deadZone` | `velocityThreshold` | `enabledDirections` |
|--------|------------|---------------------|---------------------|
| `SwipeGestureConfig()` (default) | `12.0` | `700.0` | both directions |
| `SwipeGestureConfig.loose()` | `4.0` | `300.0` | both directions |
| `SwipeGestureConfig.tight()` | `24.0` | `1000.0` | both directions |

**2× rule**: `tight().deadZone (24.0) / loose().deadZone (4.0) = 6.0×` ✓

---

### `SwipeAnimationConfig` (Modified)

Two factory preset constructors added. A new assertion is added for `activationThreshold`.

| Preset | `activationThreshold` | `completionSpring.stiffness` | `completionSpring.damping` | `snapBackSpring.stiffness` | `snapBackSpring.damping` | `resistanceFactor` |
|--------|----------------------|------------------------------|---------------------------|---------------------------|--------------------------|-------------------|
| default | `0.4` | `600.0` | `32.0` | `400.0` | `25.0` | `0.55` |
| `smooth()` | `0.5` | `180.0` | `45.0` | `160.0` | `42.0` | `0.45` |
| `snappy()` | `0.3` | `700.0` | `26.0` | `550.0` | `24.0` | `0.60` |

**2× rule**: `snappy().completionSpring.stiffness (700.0) / smooth().completionSpring.stiffness (180.0) ≈ 3.89×` ✓

**New validation** (debug-mode assertion):
- `activationThreshold >= 0.0 && activationThreshold <= 1.0`
- Message: `"activationThreshold must be between 0.0 and 1.0, got $activationThreshold"`

---

### `SwipeActionCell` (Modified)

The widget constructor is refactored. Removed parameters are replaced by equivalents inside
config objects.

| Parameter | F004 | F005 | Notes |
|-----------|------|------|-------|
| `child` | required `Widget` | required `Widget` | Unchanged |
| `rightSwipe` | `ProgressiveSwipeConfig?` | **removed** | → `rightSwipeConfig: RightSwipeConfig?` |
| `leftSwipe` | `IntentionalSwipeConfig?` | **removed** | → `leftSwipeConfig: LeftSwipeConfig?` |
| `gestureConfig` | `SwipeGestureConfig` (non-null, defaulted) | `SwipeGestureConfig?` (nullable) | Null → theme → package default |
| `animationConfig` | `SwipeAnimationConfig` (non-null, defaulted) | `SwipeAnimationConfig?` (nullable) | Null → theme → package default |
| `leftBackground` | `SwipeBackgroundBuilder?` (top-level) | **removed** | → `visualConfig.leftBackground` |
| `rightBackground` | `SwipeBackgroundBuilder?` (top-level) | **removed** | → `visualConfig.rightBackground` |
| `clipBehavior` | `Clip` (top-level, default `hardEdge`) | **removed** | → `visualConfig.clipBehavior` |
| `borderRadius` | `BorderRadius?` (top-level) | **removed** | → `visualConfig.borderRadius` |
| `visualConfig` | absent | `SwipeVisualConfig?` | New |
| `controller` | absent | `SwipeController?` | New (reserved for F007) |
| `enabled` | `bool` (default `true`) | `bool` (default `true`) | Unchanged |
| `onStateChanged` | `ValueChanged<SwipeState>?` | `ValueChanged<SwipeState>?` | Unchanged (top-level) |
| `onProgressChanged` | `ValueChanged<SwipeProgress>?` | `ValueChanged<SwipeProgress>?` | Unchanged (top-level) |

**Effective config resolution** (in `build()`):
```
effectiveGestureConfig   = gestureConfig   ?? theme?.gestureConfig   ?? const SwipeGestureConfig()
effectiveAnimationConfig = animationConfig ?? theme?.animationConfig ?? const SwipeAnimationConfig()
effectiveVisualConfig    = visualConfig    ?? theme?.visualConfig
effectiveRightConfig     = rightSwipeConfig ?? theme?.rightSwipeConfig
effectiveLeftConfig      = leftSwipeConfig  ?? theme?.leftSwipeConfig
```

---

## Deleted Entities

| Type | Replaced By |
|------|-------------|
| `ProgressiveSwipeConfig` | `RightSwipeConfig` |
| `IntentionalSwipeConfig` | `LeftSwipeConfig` |

No deprecation aliases. CHANGELOG documents the rename.

---

## File Changes Summary

**New files**:
```
lib/src/config/right_swipe_config.dart
lib/src/config/left_swipe_config.dart
lib/src/config/swipe_visual_config.dart
lib/src/config/swipe_action_cell_theme.dart
lib/src/controller/swipe_controller.dart
```

**Modified files**:
```
lib/src/gesture/swipe_gesture_config.dart         (add tight()/loose())
lib/src/animation/swipe_animation_config.dart     (add snappy()/smooth(), add assert)
lib/src/widget/swipe_action_cell.dart             (new constructor, theme lookup)
lib/swipe_action_cell.dart                        (update exports)
CHANGELOG.md                                      (migration section)
pubspec.yaml                                      (version bump)
```

**Deleted files**:
```
lib/src/actions/progressive/progressive_swipe_config.dart
lib/src/actions/intentional/intentional_swipe_config.dart
```

**Test files**:
```
test/config/right_swipe_config_test.dart          (new)
test/config/left_swipe_config_test.dart           (new)
test/config/swipe_visual_config_test.dart         (new)
test/config/swipe_action_cell_theme_test.dart     (new)
test/gesture/swipe_gesture_config_preset_test.dart (new)
test/animation/swipe_animation_config_preset_test.dart (new)
test/widget/swipe_action_cell_migration_test.dart  (new — verifies F001–F004 parity)
test/widget/swipe_action_cell_theme_test.dart      (new — theme inheritance + override)
test/widget/swipe_action_cell_validation_test.dart (new — assertion messages)
```
