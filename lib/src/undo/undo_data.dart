import 'package:flutter/widgets.dart';

/// Snapshot of an undo window's state, passed to `onUndoAvailable`.
@immutable
class UndoData {
  /// Progressive value before the action. null for intentional (left-swipe) actions.
  final double? oldValue;

  /// Progressive value after the action. null for intentional (left-swipe) actions.
  final double? newValue;

  /// Approximate time left before the window expires (snapshot at creation time).
  final Duration remainingDuration;

  /// Convenience shortcut — equivalent to calling [SwipeController.undo()] on the associated cell.
  /// No-op if the window has already closed.
  final VoidCallback revert;

  /// Creates an [UndoData].
  const UndoData({
    this.oldValue,
    this.newValue,
    required this.remainingDuration,
    required this.revert,
  });
}
