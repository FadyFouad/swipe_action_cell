import 'package:flutter/widgets.dart';

import 'swipe_progress.dart';

/// Signature for background widget builders.
///
/// Called during a swipe gesture to build the widget shown behind the cell.
/// [progress] reflects the current drag state.
typedef SwipeBackgroundBuilder = Widget Function(
  BuildContext context,
  SwipeProgress progress,
);

/// Signature for dynamic step-size calculation.
///
/// Receives the [currentValue] and returns the step size to apply for the next
/// increment during a progressive (right) swipe.
typedef DynamicStepCallback = double Function(double currentValue);

/// Signature for progress change notifications on progressive (right) swipes.
///
/// Called whenever the tracked value changes, with [newValue] and [oldValue].
typedef ProgressChangeCallback = void Function(
  double newValue,
  double oldValue,
);
