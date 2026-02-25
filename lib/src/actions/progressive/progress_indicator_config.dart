import 'package:flutter/widgets.dart';

/// Appearance configuration for the persistent progress bar rendered on the
/// leading edge of a [SwipeActionCell] when
/// [ProgressiveSwipeConfig.showProgressIndicator] is `true`.
@immutable
class ProgressIndicatorConfig {
  /// Creates a [ProgressIndicatorConfig].
  const ProgressIndicatorConfig({
    this.color = const Color(0xFF4CAF50),
    this.width = 4.0,
    this.backgroundColor,
    this.borderRadius,
  }) : assert(width > 0.0, 'width must be positive');

  /// Fill color of the progress bar. Default: green (0xFF4CAF50).
  final Color color;

  /// Width of the progress bar in logical pixels. Default: 4.0. Must be > 0.
  final double width;

  /// Optional background (track) color rendered at full height behind the fill.
  ///
  /// When `null`, no background is painted.
  final Color? backgroundColor;

  /// Optional corner radius applied to both the fill and background rects.
  final BorderRadius? borderRadius;

  /// Returns a copy with the specified fields replaced.
  ProgressIndicatorConfig copyWith({
    Color? color,
    double? width,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return ProgressIndicatorConfig(
      color: color ?? this.color,
      width: width ?? this.width,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressIndicatorConfig &&
        other.color == color &&
        other.width == width &&
        other.backgroundColor == backgroundColor &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(
        color,
        width,
        backgroundColor,
        borderRadius,
      );
}
