import 'package:flutter/foundation.dart';
import '../core/swipe_zone.dart';

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

/// Audio event identifiers passed to [SwipeFeedbackConfig.onShouldPlaySound].
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
  final int delayBeforeNextMs;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HapticStep) return false;
    return type == other.type && delayBeforeNextMs == other.delayBeforeNextMs;
  }

  @override
  int get hashCode => Object.hash(type, delayBeforeNextMs);
}

/// An ordered sequence of [HapticStep] values forming a haptic choreography.
@immutable
class HapticPattern {
  /// Creates a [HapticPattern] from an explicit list of steps.
  const HapticPattern(this.steps);

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

  /// Silent pattern — produces no haptic output.
  /// Silent pattern — produces no haptic output.
  static const HapticPattern silent = HapticPattern([]);

  /// Converts a legacy [SwipeZoneHaptic] enum value to a [HapticPattern].
  static HapticPattern? fromZoneHaptic(SwipeZoneHaptic? pattern) {
    if (pattern == null) return null;
    return switch (pattern) {
      SwipeZoneHaptic.light => HapticPattern.light,
      SwipeZoneHaptic.medium => HapticPattern.medium,
      SwipeZoneHaptic.heavy => HapticPattern.heavy,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HapticPattern) return false;
    return listEquals(steps, other.steps);
  }

  @override
  int get hashCode => Object.hashAll(steps);
}

/// Unified configuration for all haptic and audio feedback.
@immutable
class SwipeFeedbackConfig {
  /// Creates a [SwipeFeedbackConfig].
  const SwipeFeedbackConfig({
    this.enableHaptic = true,
    this.enableAudio = false,
    this.hapticOverrides,
    this.onShouldPlaySound,
  });

  /// Master haptic toggle.
  final bool enableHaptic;

  /// Master audio toggle.
  final bool enableAudio;

  /// Per-event haptic pattern overrides.
  final Map<SwipeFeedbackEvent, HapticPattern>? hapticOverrides;

  /// Audio hook callback.
  final void Function(SwipeSoundEvent)? onShouldPlaySound;

  /// Returns a copy with the specified fields replaced.
  SwipeFeedbackConfig copyWith({
    bool? enableHaptic,
    bool? enableAudio,
    Map<SwipeFeedbackEvent, HapticPattern>? hapticOverrides,
    void Function(SwipeSoundEvent)? onShouldPlaySound,
  }) {
    return SwipeFeedbackConfig(
      enableHaptic: enableHaptic ?? this.enableHaptic,
      enableAudio: enableAudio ?? this.enableAudio,
      hapticOverrides: hapticOverrides ?? this.hapticOverrides,
      onShouldPlaySound: onShouldPlaySound ?? this.onShouldPlaySound,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SwipeFeedbackConfig) return false;
    return enableHaptic == other.enableHaptic &&
        enableAudio == other.enableAudio &&
        mapEquals(hapticOverrides, other.hapticOverrides) &&
        onShouldPlaySound == other.onShouldPlaySound;
  }

  @override
  int get hashCode => Object.hash(
        enableHaptic,
        enableAudio,
        hapticOverrides,
        onShouldPlaySound,
      );
}
