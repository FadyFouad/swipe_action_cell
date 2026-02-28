import 'package:flutter/widgets.dart';
import 'package:swipe_action_cell/src/core/typedefs.dart';

/// Controls how the background transitions when dragging across zone boundaries.
enum ZoneTransitionStyle {
  /// Backgrounds cross-dissolve over the transition duration.
  crossfade,

  /// New background slides in from the swipe direction edge.
  slide,

  /// Immediate cut — no animation. Default and forced when reduced motion is on.
  instant,
}

/// Maps to Flutter's platform haptic channels.
enum SwipeZoneHaptic {
  /// HapticFeedback.lightImpact()
  light,

  /// HapticFeedback.mediumImpact()
  medium,

  /// HapticFeedback.heavyImpact()
  heavy,
}

/// Represents a single activation zone within a swipe direction.
@immutable
class SwipeZone {
  /// The ratio of full swipe extent at which this zone activates.
  /// Must be between 0.0 and 1.0 exclusive.
  final double threshold;

  /// Announced by screen readers when this zone becomes active.
  final String semanticLabel;

  /// Fired when this is the highest crossed zone at release (intentional/left direction).
  final VoidCallback? onActivated;

  /// Increment applied when this zone is the highest crossed at release (progressive/right direction).
  final double? stepValue;

  /// Custom background builder parameterized by [SwipeProgress].
  final SwipeBackgroundBuilder? background;

  /// Flat background color (used when [background] is null).
  final Color? color;

  /// Icon displayed in the zone background.
  final Widget? icon;

  /// Display text shown below icon in the zone background.
  final String? label;

  /// Haptic fired when this zone boundary is crossed (forward direction).
  final SwipeZoneHaptic? hapticPattern;

  /// Creates a [SwipeZone] configuration.
  const SwipeZone({
    required this.threshold,
    required this.semanticLabel,
    this.onActivated,
    this.stepValue,
    this.background,
    this.color,
    this.icon,
    this.label,
    this.hapticPattern,
  })  : assert(threshold > 0.0 && threshold < 1.0, 'Threshold must be between 0.0 and 1.0 exclusive'),
        assert(semanticLabel.length > 0, 'semanticLabel must not be empty');

  /// Creates a copy of this [SwipeZone] with the given fields replaced.
  SwipeZone copyWith({
    double? threshold,
    String? semanticLabel,
    VoidCallback? onActivated,
    double? stepValue,
    SwipeBackgroundBuilder? background,
    Color? color,
    Widget? icon,
    String? label,
    SwipeZoneHaptic? hapticPattern,
  }) {
    return SwipeZone(
      threshold: threshold ?? this.threshold,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      onActivated: onActivated ?? this.onActivated,
      stepValue: stepValue ?? this.stepValue,
      background: background ?? this.background,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      label: label ?? this.label,
      hapticPattern: hapticPattern ?? this.hapticPattern,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SwipeZone) return false;
    return threshold == other.threshold &&
        semanticLabel == other.semanticLabel &&
        onActivated == other.onActivated &&
        stepValue == other.stepValue &&
        background == other.background &&
        color == other.color &&
        icon == other.icon &&
        label == other.label &&
        hapticPattern == other.hapticPattern;
  }

  @override
  int get hashCode => Object.hash(
        threshold,
        semanticLabel,
        onActivated,
        stepValue,
        background,
        color,
        icon,
        label,
        hapticPattern,
      );

  @override
  String toString() => 'SwipeZone(threshold: $threshold, semanticLabel: $semanticLabel)';
}
