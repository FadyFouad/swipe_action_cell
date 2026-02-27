import 'package:flutter/widgets.dart';
import '../core/typedefs.dart';


/// Configuration for the visual appearance and backgrounds of [SwipeActionCell].
@immutable
class SwipeVisualConfig {
  /// Creates a visual configuration for [SwipeActionCell].
  const SwipeVisualConfig({
    this.leftBackground,
    this.rightBackground,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius,
  });

  /// Builder for the background displayed during a left swipe.
  final SwipeBackgroundBuilder? leftBackground;

  /// Builder for the background displayed during a right swipe.
  final SwipeBackgroundBuilder? rightBackground;

  /// How to clip the cell and its background during swipe.
  final Clip clipBehavior;

  /// The border radius applied to the cell and background clipping.
  final BorderRadius? borderRadius;

  /// Creates a copy of this configuration with the given fields replaced.
  SwipeVisualConfig copyWith({
    SwipeBackgroundBuilder? leftBackground,
    SwipeBackgroundBuilder? rightBackground,
    Clip? clipBehavior,
    BorderRadius? borderRadius,
  }) {
    return SwipeVisualConfig(
      leftBackground: leftBackground ?? this.leftBackground,
      rightBackground: rightBackground ?? this.rightBackground,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeVisualConfig &&
          runtimeType == other.runtimeType &&
          leftBackground == other.leftBackground &&
          rightBackground == other.rightBackground &&
          clipBehavior == other.clipBehavior &&
          borderRadius == other.borderRadius;

  @override
  int get hashCode =>
      leftBackground.hashCode ^
      rightBackground.hashCode ^
      clipBehavior.hashCode ^
      borderRadius.hashCode;
}
