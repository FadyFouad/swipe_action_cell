import 'package:flutter/widgets.dart';
import '../animation/swipe_animation_config.dart';
import '../gesture/swipe_gesture_config.dart';
import 'left_swipe_config.dart';
import 'right_swipe_config.dart';
import 'swipe_visual_config.dart';

/// An inherited widget that provides default configuration for [SwipeActionCell]s.
class SwipeActionCellTheme extends InheritedWidget {
  /// Creates a theme for [SwipeActionCell]s.
  const SwipeActionCellTheme({
    super.key,
    required super.child,
    this.gestureConfig,
    this.animationConfig,
    this.leftSwipeConfig,
    this.rightSwipeConfig,
    this.visualConfig,
  });

  /// Default gesture configuration for descendant cells.
  final SwipeGestureConfig? gestureConfig;

  /// Default animation configuration for descendant cells.
  final SwipeAnimationConfig? animationConfig;

  /// Default left-swipe configuration for descendant cells.
  final LeftSwipeConfig? leftSwipeConfig;

  /// Default right-swipe configuration for descendant cells.
  final RightSwipeConfig? rightSwipeConfig;

  /// Default visual configuration for descendant cells.
  final SwipeVisualConfig? visualConfig;

  /// The theme from the closest [SwipeActionCellTheme] ancestor.
  static SwipeActionCellTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SwipeActionCellTheme>();
  }

  @override
  bool updateShouldNotify(SwipeActionCellTheme oldWidget) {
    return gestureConfig != oldWidget.gestureConfig ||
        animationConfig != oldWidget.animationConfig ||
        leftSwipeConfig != oldWidget.leftSwipeConfig ||
        rightSwipeConfig != oldWidget.rightSwipeConfig ||
        visualConfig != oldWidget.visualConfig;
  }
}
