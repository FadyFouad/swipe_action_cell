import 'dart:async';
import 'package:flutter/services.dart';
import 'swipe_feedback_config.dart';

/// Manages haptic dispatch and audio callback invocation.
class FeedbackDispatcher {
  final SwipeFeedbackConfig? _config;
  final bool _legacyEnableHapticForward;
  final bool _legacyEnableHapticBackward;
  final List<Timer> _activeTimers = [];

  /// Creates a [FeedbackDispatcher].
  FeedbackDispatcher({
    SwipeFeedbackConfig? config,
    bool legacyEnableHapticForward = false,
    bool legacyEnableHapticBackward = false,
  })  : _config = config,
        _legacyEnableHapticForward = legacyEnableHapticForward,
        _legacyEnableHapticBackward = legacyEnableHapticBackward;

  /// Resolves the effective dispatcher based on local and theme configs.
  factory FeedbackDispatcher.resolve({
    SwipeFeedbackConfig? cellConfig,
    SwipeFeedbackConfig? themeConfig,
    bool legacyForwardHaptic = false,
    bool legacyBackwardHaptic = false,
  }) {
    return FeedbackDispatcher(
      config: cellConfig ?? themeConfig,
      legacyEnableHapticForward: legacyForwardHaptic,
      legacyEnableHapticBackward: legacyBackwardHaptic,
    );
  }

  /// Fires haptic and audio feedback for the given event.
  void fire(SwipeFeedbackEvent event,
      {bool isForward = true, HapticPattern? pattern}) {
    if (_config == null) {
      _fireLegacy(event, isForward, pattern);
      return;
    }

    if (!_config.enableHaptic) return;

    final effectivePattern =
        pattern ?? _config.hapticOverrides?[event] ?? _defaultPatternFor(event);
    _executePattern(effectivePattern);

    _maybeFireAudio(event);
  }

  /// Cancels all pending timers for multi-step patterns.
  void cancelPendingTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  void _fireLegacy(SwipeFeedbackEvent event, bool isForward,
      HapticPattern? patternOverride) {
    if (patternOverride != null) {
      _executePattern(patternOverride);
      return;
    }

    final enabled =
        isForward ? _legacyEnableHapticForward : _legacyEnableHapticBackward;
    if (!enabled) return;

    switch (event) {
      case SwipeFeedbackEvent.thresholdCrossed:
      case SwipeFeedbackEvent.zoneBoundaryCrossed:
        _fireHapticType(HapticType.lightImpact);
        break;
      case SwipeFeedbackEvent.actionTriggered:
      case SwipeFeedbackEvent.progressIncremented:
        _fireHapticType(HapticType.mediumImpact);
        break;
      default:
        break;
    }
  }

  void _executePattern(HapticPattern pattern) {
    if (pattern.steps.isEmpty) return;

    // First step synchronous
    _fireHapticType(pattern.steps.first.type);

    if (pattern.steps.length > 1) {
      int accumulatedDelay = pattern.steps.first.delayBeforeNextMs;
      for (int i = 1; i < pattern.steps.length; i++) {
        final step = pattern.steps[i];
        final timer = Timer(Duration(milliseconds: accumulatedDelay), () {
          _fireHapticType(step.type);
        });
        _activeTimers.add(timer);
        accumulatedDelay += step.delayBeforeNextMs;
      }
    }
  }

  void _fireHapticType(HapticType type) {
    try {
      switch (type) {
        case HapticType.lightImpact:
          HapticFeedback.lightImpact();
          break;
        case HapticType.mediumImpact:
          HapticFeedback.mediumImpact();
          break;
        case HapticType.heavyImpact:
          HapticFeedback.heavyImpact();
          break;
        case HapticType.successNotification:
        case HapticType.errorNotification:
          HapticFeedback.vibrate();
          break;
        case HapticType.selectionTick:
          HapticFeedback.selectionClick();
          break;
      }
    } catch (_) {
      // Discard exceptions for platform safety (FR-021)
    }
  }

  void _maybeFireAudio(SwipeFeedbackEvent event) {
    if (_config == null ||
        !_config.enableAudio ||
        _config.onShouldPlaySound == null) return;

    final soundEvent = _soundEventFor(event);
    if (soundEvent != null) {
      try {
        _config.onShouldPlaySound!(soundEvent);
      } catch (_) {
        // Silently discard hook exceptions (FR-014)
      }
    }
  }

  HapticPattern _defaultPatternFor(SwipeFeedbackEvent event) {
    return switch (event) {
      SwipeFeedbackEvent.thresholdCrossed => HapticPattern.light,
      SwipeFeedbackEvent.actionTriggered => HapticPattern.medium,
      SwipeFeedbackEvent.progressIncremented => HapticPattern.tick,
      SwipeFeedbackEvent.panelOpened => HapticPattern.tick,
      SwipeFeedbackEvent.panelClosed => HapticPattern.tick,
      SwipeFeedbackEvent.zoneBoundaryCrossed => HapticPattern.light,
      SwipeFeedbackEvent.swipeCancelled => HapticPattern.silent,
    };
  }

  SwipeSoundEvent? _soundEventFor(SwipeFeedbackEvent event) {
    return switch (event) {
      SwipeFeedbackEvent.thresholdCrossed => SwipeSoundEvent.thresholdCrossed,
      SwipeFeedbackEvent.actionTriggered => SwipeSoundEvent.actionTriggered,
      SwipeFeedbackEvent.progressIncremented =>
        SwipeSoundEvent.progressIncremented,
      SwipeFeedbackEvent.panelOpened => SwipeSoundEvent.panelOpened,
      SwipeFeedbackEvent.panelClosed => SwipeSoundEvent.panelClosed,
      SwipeFeedbackEvent.zoneBoundaryCrossed => null,
      SwipeFeedbackEvent.swipeCancelled => null,
    };
  }
}
