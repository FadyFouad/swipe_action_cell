import 'package:flutter/material.dart';

import '../animation/swipe_animation_config.dart';
import '../gesture/swipe_gesture_config.dart';
import 'left_swipe_config.dart';
import 'right_swipe_config.dart';
import 'swipe_visual_config.dart';

/// App-level defaults for all [SwipeActionCell] widgets in the widget tree.
///
/// Install in [ThemeData.extensions] to provide default configurations that
/// every [SwipeActionCell] inherits when no local override is provided:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [
///       SwipeActionCellTheme(
///         gestureConfig: SwipeGestureConfig.loose(),
///         animationConfig: SwipeAnimationConfig.smooth(),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// Per-widget override: pass a non-null config to the relevant [SwipeActionCell]
/// parameter. The local config fully replaces the theme config for that parameter
/// (no field-level merging). Use `copyWith` on the theme's config to merge fields:
///
/// ```dart
/// SwipeActionCell(
///   gestureConfig: SwipeActionCellTheme.maybeOf(context)
///       ?.gestureConfig
///       ?.copyWith(deadZone: 8.0),
/// )
/// ```
@immutable
class SwipeActionCellTheme extends ThemeExtension<SwipeActionCellTheme> {
  /// Creates a [SwipeActionCellTheme].
  ///
  /// All parameters are optional. A null field means "no theme default for
  /// that parameter" — the widget falls back to its package-level defaults.
  const SwipeActionCellTheme({
    this.rightSwipeConfig,
    this.leftSwipeConfig,
    this.gestureConfig,
    this.animationConfig,
    this.visualConfig,
  });

  /// Default right-swipe configuration applied to all cells in the tree.
  final RightSwipeConfig? rightSwipeConfig;

  /// Default left-swipe configuration applied to all cells in the tree.
  final LeftSwipeConfig? leftSwipeConfig;

  /// Default gesture recognition configuration applied to all cells in the tree.
  final SwipeGestureConfig? gestureConfig;

  /// Default animation physics configuration applied to all cells in the tree.
  final SwipeAnimationConfig? animationConfig;

  /// Default visual presentation configuration applied to all cells in the tree.
  final SwipeVisualConfig? visualConfig;

  /// Returns the nearest [SwipeActionCellTheme] from [context], or `null` if
  /// none is installed in the app theme.
  static SwipeActionCellTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<SwipeActionCellTheme>();

  /// Returns a copy with the specified fields replaced.
  @override
  SwipeActionCellTheme copyWith({
    RightSwipeConfig? rightSwipeConfig,
    LeftSwipeConfig? leftSwipeConfig,
    SwipeGestureConfig? gestureConfig,
    SwipeAnimationConfig? animationConfig,
    SwipeVisualConfig? visualConfig,
  }) {
    return SwipeActionCellTheme(
      rightSwipeConfig: rightSwipeConfig ?? this.rightSwipeConfig,
      leftSwipeConfig: leftSwipeConfig ?? this.leftSwipeConfig,
      gestureConfig: gestureConfig ?? this.gestureConfig,
      animationConfig: animationConfig ?? this.animationConfig,
      visualConfig: visualConfig ?? this.visualConfig,
    );
  }

  /// Hard-cutover lerp: returns [other] when [t] >= 1.0, [this] otherwise.
  ///
  /// Spring stiffness, damping, and gesture thresholds are not numerically
  /// interpolated — a mid-lerp mix would produce undefined physical behavior.
  @override
  SwipeActionCellTheme lerp(
    ThemeExtension<SwipeActionCellTheme>? other,
    double t,
  ) {
    if (other is! SwipeActionCellTheme) return this;
    return t >= 1.0 ? other : this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeActionCellTheme &&
          runtimeType == other.runtimeType &&
          rightSwipeConfig == other.rightSwipeConfig &&
          leftSwipeConfig == other.leftSwipeConfig &&
          gestureConfig == other.gestureConfig &&
          animationConfig == other.animationConfig &&
          visualConfig == other.visualConfig;

  @override
  int get hashCode => Object.hash(
        rightSwipeConfig,
        leftSwipeConfig,
        gestureConfig,
        animationConfig,
        visualConfig,
      );
}
