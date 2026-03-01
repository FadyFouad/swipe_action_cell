# Public API Contract: Unified Feedback System (F010)

**Generated**: 2026-03-01
**Feature**: [spec.md](../spec.md)

All types below are exported from `package:swipe_action_cell/swipe_action_cell.dart`.

---

## Enumerations

### `SwipeFeedbackEvent`

```dart
/// All trigger points where the feedback system can fire haptic or audio feedback.
enum SwipeFeedbackEvent {
  /// Fired when the drag position crosses the activation threshold in either direction.
  thresholdCrossed,

  /// Fired when an intentional (left-swipe) action triggers on release,
  /// or when a reveal-panel button is tapped.
  actionTriggered,

  /// Fired when a progressive (right-swipe) increment completes on release.
  progressIncremented,

  /// Fired when the reveal panel finishes its open animation and reaches the
  /// [SwipeState.revealed] state.
  panelOpened,

  /// Fired when the reveal panel finishes its close animation and returns to
  /// [SwipeState.idle].
  panelClosed,

  /// Fired when a zone boundary is crossed in the forward direction during drag.
  /// Only fires when zone mode is active (zones list is non-null and non-empty).
  zoneBoundaryCrossed,

  /// Fired when a drag gesture is released below the activation threshold.
  /// Defaults to silent (no haptic); override via [SwipeFeedbackConfig.hapticOverrides].
  swipeCancelled,
}
```

---

### `HapticType`

```dart
/// The haptic channel to invoke for a single pattern step.
enum HapticType {
  /// Corresponds to [HapticFeedback.lightImpact].
  lightImpact,

  /// Corresponds to [HapticFeedback.mediumImpact].
  mediumImpact,

  /// Corresponds to [HapticFeedback.heavyImpact].
  heavyImpact,

  /// Corresponds to [HapticFeedback.vibrate] with a success notification.
  successNotification,

  /// Corresponds to [HapticFeedback.vibrate] with an error notification.
  errorNotification,

  /// Corresponds to [HapticFeedback.selectionClick].
  selectionTick,
}
```

---

### `SwipeSoundEvent`

```dart
/// Audio event identifiers passed to [SwipeFeedbackConfig.onShouldPlaySound].
///
/// This enum is a strict subset of [SwipeFeedbackEvent]: not every feedback
/// trigger has an audio counterpart.
enum SwipeSoundEvent {
  /// Corresponds to [SwipeFeedbackEvent.thresholdCrossed].
  thresholdCrossed,

  /// Corresponds to [SwipeFeedbackEvent.actionTriggered].
  actionTriggered,

  /// Corresponds to [SwipeFeedbackEvent.panelOpened].
  panelOpened,

  /// Corresponds to [SwipeFeedbackEvent.panelClosed].
  panelClosed,

  /// Corresponds to [SwipeFeedbackEvent.progressIncremented].
  progressIncremented,
}
```

---

## Data Classes

### `HapticStep`

```dart
/// A single step in a multi-step haptic pattern.
@immutable
class HapticStep {
  /// Creates a [HapticStep].
  const HapticStep({
    required this.type,
    this.delayBeforeNextMs = 0,
  });

  /// The haptic channel to invoke for this step.
  final HapticType type;

  /// Milliseconds to wait before the next step fires.
  /// Has no effect on the last step in a pattern.
  /// Must be >= 0.
  final int delayBeforeNextMs;

  // == and hashCode
}
```

---

### `HapticPattern`

```dart
/// An ordered sequence of [HapticStep] values forming a haptic choreography.
///
/// Patterns may contain 0–8 steps. A zero-step pattern produces no haptic
/// for its mapped event, effectively disabling it for that event only.
/// A pattern with more than 8 steps will throw an [AssertionError] in debug mode.
@immutable
class HapticPattern {
  /// Creates a [HapticPattern] from an explicit list of steps.
  ///
  /// Asserts that [steps] contains no more than 8 entries.
  const HapticPattern(this.steps)
    : assert(
        steps.length <= 8,
        'HapticPattern may have at most 8 steps, got ${steps.length}',
      );

  /// The ordered steps of this pattern.
  final List<HapticStep> steps;

  /// Single light-impact step.
  static const HapticPattern light = HapticPattern(
    [HapticStep(type: HapticType.lightImpact)],
  );

  /// Single medium-impact step.
  static const HapticPattern medium = HapticPattern(
    [HapticStep(type: HapticType.mediumImpact)],
  );

  /// Single heavy-impact step.
  static const HapticPattern heavy = HapticPattern(
    [HapticStep(type: HapticType.heavyImpact)],
  );

  /// Single selection-tick step.
  static const HapticPattern tick = HapticPattern(
    [HapticStep(type: HapticType.selectionTick)],
  );

  /// Single success-notification step.
  static const HapticPattern success = HapticPattern(
    [HapticStep(type: HapticType.successNotification)],
  );

  /// Single error-notification step.
  static const HapticPattern error = HapticPattern(
    [HapticStep(type: HapticType.errorNotification)],
  );

  /// Silent pattern — produces no haptic output. Useful to disable a single event.
  static const HapticPattern silent = HapticPattern([]);

  // == and hashCode
}
```

---

## Configuration Class

### `SwipeFeedbackConfig`

```dart
/// Unified configuration for all haptic and audio feedback in a [SwipeActionCell].
///
/// Provide at the cell level via [SwipeActionCell.feedbackConfig], or at the
/// app level via [SwipeActionCellTheme.feedbackConfig].
///
/// When present, this config takes precedence over any [enableHaptic] flags on
/// [LeftSwipeConfig] or [RightSwipeConfig]. In debug builds, an [AssertionError]
/// is thrown when [enableHaptic] is set to `true` on a direction config while
/// a [SwipeFeedbackConfig] is active.
@immutable
class SwipeFeedbackConfig {
  /// Creates a [SwipeFeedbackConfig].
  ///
  /// [enableHaptic] defaults to `true`; [enableAudio] defaults to `false`.
  const SwipeFeedbackConfig({
    this.enableHaptic = true,
    this.enableAudio = false,
    this.hapticOverrides,
    this.onShouldPlaySound,
  });

  /// Master haptic toggle.
  ///
  /// When `false`, no haptic fires for this cell under any circumstance,
  /// regardless of [hapticOverrides].
  final bool enableHaptic;

  /// Master audio toggle.
  ///
  /// When `false`, [onShouldPlaySound] is never called, regardless of the
  /// presence of the callback.
  final bool enableAudio;

  /// Per-event haptic pattern overrides.
  ///
  /// Each entry replaces the predefined default for its key event. Events
  /// not present in the map use their predefined defaults. A `null` map is
  /// equivalent to an empty map — all events use predefined defaults.
  final Map<SwipeFeedbackEvent, HapticPattern>? hapticOverrides;

  /// Audio hook callback.
  ///
  /// Called synchronously on the same frame as the triggering event when
  /// [enableAudio] is `true` and this callback is non-null. The package ships
  /// no audio; the consumer is responsible for dispatching playback.
  ///
  /// Any exception thrown by this callback is caught and suppressed; swipe
  /// behavior is unaffected.
  final void Function(SwipeSoundEvent)? onShouldPlaySound;

  /// Returns a copy with the specified fields replaced.
  SwipeFeedbackConfig copyWith({
    bool? enableHaptic,
    bool? enableAudio,
    Map<SwipeFeedbackEvent, HapticPattern>? hapticOverrides,
    void Function(SwipeSoundEvent)? onShouldPlaySound,
  });

  // == and hashCode
}
```

---

## Modified Widget Constructor

### `SwipeActionCell` (new parameter)

```dart
const SwipeActionCell({
  // ... existing parameters unchanged ...

  /// Per-cell feedback configuration.
  ///
  /// When non-null, takes precedence over any [SwipeActionCellTheme.feedbackConfig]
  /// in the widget tree, and over [enableHaptic] flags on [leftSwipeConfig] and
  /// [rightSwipeConfig].
  ///
  /// When null, the nearest ancestor [SwipeActionCellTheme.feedbackConfig] is used.
  /// When both are null, the legacy [enableHaptic] flags on direction configs apply.
  final SwipeFeedbackConfig? feedbackConfig,
})
```

---

## Modified Theme

### `SwipeActionCellTheme` (new field)

```dart
const SwipeActionCellTheme({
  // ... existing fields unchanged ...

  /// App-wide default feedback configuration.
  ///
  /// Inherited by all [SwipeActionCell] widgets in the tree that do not provide
  /// their own [SwipeActionCell.feedbackConfig].
  final SwipeFeedbackConfig? feedbackConfig,
})
```

---

## Migration Guide

### Before (F003/F004 pattern)

```dart
SwipeActionCell(
  rightSwipeConfig: RightSwipeConfig(
    enableHaptic: true,
    // ...
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    enableHaptic: true,
    // ...
  ),
)
```

### After (F010 unified pattern)

```dart
SwipeActionCell(
  feedbackConfig: SwipeFeedbackConfig(enableHaptic: true),
  rightSwipeConfig: RightSwipeConfig(/* enableHaptic removed */),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    /* enableHaptic removed */
  ),
)
```

### After with custom patterns

```dart
SwipeActionCell(
  feedbackConfig: SwipeFeedbackConfig(
    enableHaptic: true,
    hapticOverrides: {
      SwipeFeedbackEvent.thresholdCrossed: HapticPattern.light,
      SwipeFeedbackEvent.actionTriggered: HapticPattern.heavy,
      SwipeFeedbackEvent.progressIncremented: HapticPattern.tick,
    },
  ),
)
```

### After with audio hook

```dart
SwipeActionCell(
  feedbackConfig: SwipeFeedbackConfig(
    enableHaptic: true,
    enableAudio: true,
    onShouldPlaySound: (event) {
      switch (event) {
        case SwipeSoundEvent.actionTriggered:
          audioPlayer.play('action_complete.mp3');
        default:
          break;
      }
    },
  ),
)
```

### App-wide via theme

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      SwipeActionCellTheme(
        feedbackConfig: SwipeFeedbackConfig(enableHaptic: true),
      ),
    ],
  ),
)
```
