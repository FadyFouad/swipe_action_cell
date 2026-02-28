# Data Model: Unified Feedback System (F010)

**Generated**: 2026-03-01
**Feature**: [spec.md](spec.md)

---

## New Entities

### `SwipeFeedbackEvent` (enum)

Enumeration of all trigger points where feedback can fire.

| Value | Default Haptic | Has Sound Event |
|---|---|---|
| `thresholdCrossed` | light impact | yes |
| `actionTriggered` | medium impact | yes |
| `progressIncremented` | selection tick | yes |
| `panelOpened` | selection tick | yes |
| `panelClosed` | selection tick | yes |
| `zoneBoundaryCrossed` | light impact | no |
| `swipeCancelled` | none (silent) | no |

**File**: `lib/src/feedback/swipe_feedback_config.dart`

---

### `HapticType` (enum)

Maps to Flutter `HapticFeedback` service calls and `UINotificationFeedbackGenerator` types.

| Value | Flutter API |
|---|---|
| `lightImpact` | `HapticFeedback.lightImpact()` |
| `mediumImpact` | `HapticFeedback.mediumImpact()` |
| `heavyImpact` | `HapticFeedback.heavyImpact()` |
| `successNotification` | `HapticFeedback.vibrate()` with success notification pattern |
| `errorNotification` | `HapticFeedback.vibrate()` with error notification pattern |
| `selectionTick` | `HapticFeedback.selectionClick()` |

**File**: `lib/src/feedback/swipe_feedback_config.dart`

---

### `HapticStep` (immutable data class)

A single step within a multi-step haptic pattern.

| Field | Type | Default | Constraint |
|---|---|---|---|
| `type` | `HapticType` | required | — |
| `delayBeforeNextMs` | `int` | `0` | `>= 0` |

- `const` constructor
- `==` and `hashCode`
- Dartdoc on all fields

**File**: `lib/src/feedback/swipe_feedback_config.dart`

---

### `HapticPattern` (immutable class)

An ordered sequence of 1–8 `HapticStep` values defining a haptic choreography.

| Field | Type | Constraint |
|---|---|---|
| `steps` | `List<HapticStep>` | `1 ≤ steps.length ≤ 8`; assert on construction |

**Named factory constructors** (single-step convenience):
- `HapticPattern.light()` → `[HapticStep(type: HapticType.lightImpact)]`
- `HapticPattern.medium()` → `[HapticStep(type: HapticType.mediumImpact)]`
- `HapticPattern.heavy()` → `[HapticStep(type: HapticType.heavyImpact)]`
- `HapticPattern.tick()` → `[HapticStep(type: HapticType.selectionTick)]`
- `HapticPattern.success()` → `[HapticStep(type: HapticType.successNotification)]`
- `HapticPattern.error()` → `[HapticStep(type: HapticType.errorNotification)]`

**Zero-step** (`steps.length == 0`): produces no haptic for the mapped event (valid use case — effectively disables haptic for that event).

**Assertions**:
- `steps.length <= 8`: asserts with `'HapticPattern may have at most 8 steps, got ${steps.length}'`

- `const` constructor, `==`, `hashCode`

**File**: `lib/src/feedback/swipe_feedback_config.dart`

---

### `SwipeSoundEvent` (enum)

Audio event identifiers passed to `onShouldPlaySound`. A strict subset of `SwipeFeedbackEvent`.

| Value | Corresponding `SwipeFeedbackEvent` |
|---|---|
| `thresholdCrossed` | `SwipeFeedbackEvent.thresholdCrossed` |
| `actionTriggered` | `SwipeFeedbackEvent.actionTriggered` |
| `panelOpened` | `SwipeFeedbackEvent.panelOpened` |
| `panelClosed` | `SwipeFeedbackEvent.panelClosed` |
| `progressIncremented` | `SwipeFeedbackEvent.progressIncremented` |

**File**: `lib/src/feedback/swipe_feedback_config.dart`

---

### `SwipeFeedbackConfig` (immutable config class)

Top-level configuration object for the unified feedback system.

| Field | Type | Default | Description |
|---|---|---|---|
| `enableHaptic` | `bool` | `true` | Master haptic toggle; when `false`, no haptic fires under any circumstance |
| `enableAudio` | `bool` | `false` | Master audio toggle; when `false`, `onShouldPlaySound` is never called |
| `hapticOverrides` | `Map<SwipeFeedbackEvent, HapticPattern>?` | `null` | Per-event haptic override; null entries use predefined defaults |
| `onShouldPlaySound` | `void Function(SwipeSoundEvent)?` | `null` | Audio hook callback; called synchronously when audio event fires |

**Predefined defaults** (used when `hapticOverrides` does not contain a key):

| `SwipeFeedbackEvent` | Default `HapticPattern` |
|---|---|
| `thresholdCrossed` | `HapticPattern.light()` |
| `actionTriggered` | `HapticPattern.medium()` |
| `progressIncremented` | `HapticPattern.tick()` |
| `panelOpened` | `HapticPattern.tick()` |
| `panelClosed` | `HapticPattern.tick()` |
| `zoneBoundaryCrossed` | `HapticPattern.light()` |
| `swipeCancelled` | `HapticPattern([])` (silent) |

**Methods**: `const` constructor, `copyWith`, `==`, `hashCode`

**File**: `lib/src/feedback/swipe_feedback_config.dart`

---

## Internal Entities (not public API)

### `FeedbackDispatcher` (internal service class)

Manages haptic dispatch and audio callback invocation for a single `SwipeActionCell` instance.

| Field | Type | Description |
|---|---|---|
| `_config` | `SwipeFeedbackConfig?` | Resolved config; `null` → legacy/silent mode |
| `_legacyEnableHapticForward` | `bool` | Legacy flag from `RightSwipeConfig.enableHaptic` |
| `_legacyEnableHapticBackward` | `bool` | Legacy flag from `LeftSwipeConfig.enableHaptic` |
| `_activeTimers` | `List<Timer>` | In-flight pattern step timers |

**Methods**:

| Method | Description |
|---|---|
| `fire(SwipeFeedbackEvent event, {bool isForward = true})` | Fires haptic + audio for the event. Checks master toggle, looks up override or default pattern, executes first step synchronously, schedules subsequent steps. `isForward` used only for legacy mode direction selection. |
| `cancelPendingTimers()` | Cancels and clears all active pattern timers |
| `_executePattern(HapticPattern pattern)` | Fires first step immediately, schedules rest via `Timer` |
| `_fireHapticType(HapticType type)` | Calls the corresponding `HapticFeedback.*` method inside try/catch |

**Factory**:
```
FeedbackDispatcher.resolve({
  SwipeFeedbackConfig? cellConfig,
  SwipeFeedbackConfig? themeConfig,
  bool legacyForwardHaptic = false,
  bool legacyBackwardHaptic = false,
})
```
Returns a dispatcher configured with the effective config and legacy flags.

**File**: `lib/src/feedback/feedback_dispatcher.dart`

---

## Modified Entities

### `SwipeActionCellTheme` (modified)

**New field added**:

| Field | Type | Default | Description |
|---|---|---|---|
| `feedbackConfig` | `SwipeFeedbackConfig?` | `null` | App-wide default feedback configuration |

- `copyWith`, `==`, `hashCode`, `lerp` updated to include new field
- Existing fields unchanged

**File**: `lib/src/config/swipe_action_cell_theme.dart`

---

### `SwipeActionCell` widget (modified)

**New constructor parameter**:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `feedbackConfig` | `SwipeFeedbackConfig?` | `null` | Per-cell feedback config; overrides theme |

**New internal state**:

| Field | Type | Description |
|---|---|---|
| `_feedbackDispatcher` | `FeedbackDispatcher?` | Created in `didChangeDependencies` |

All scattered `HapticFeedback.*` calls replaced with `_feedbackDispatcher?.fire(event)`.
`_feedbackDispatcher?.cancelPendingTimers()` called in `_handleDragStart` and `dispose()`.

**File**: `lib/src/widget/swipe_action_cell.dart`

---

### `SwipeActionPanel` (modified)

**New constructor parameter**:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `onFeedbackRequest` | `VoidCallback?` | `null` | Called instead of direct haptic when non-null |

When `onFeedbackRequest` is non-null, replaces `HapticFeedback.mediumImpact()` calls.
When null, existing `enableHaptic: bool` path is unchanged (backward compat).

**File**: `lib/src/actions/intentional/swipe_action_panel.dart`

---

## State Transitions (Haptic Fire Points)

```
idle
  └─ _handleDragStart ─────────────────────────► cancelPendingTimers()
dragging
  └─ AnimatedBuilder frame (threshold crossed) ─► fire(thresholdCrossed)
  └─ AnimatedBuilder frame (zone crossed) ──────► fire(zoneBoundaryCrossed) [if dispatcher]
  └─ _handleDragEnd (below threshold) ──────────► fire(swipeCancelled)
animatingToOpen
  └─ animation settle ──────────────────────────► fire(panelOpened)  [reveal mode only]
revealed
animatingToClose
  └─ animation settle (was revealed) ──────────► fire(panelClosed)  [reveal mode only]
  └─ action trigger (autoTrigger/progressive) ─► fire(actionTriggered) or fire(progressIncremented)
idle
```

---

## Barrel Export Changes

**`lib/swipe_action_cell.dart`** — add:
```dart
export 'src/feedback/swipe_feedback_config.dart';
```

`FeedbackDispatcher` is NOT exported (internal class).
