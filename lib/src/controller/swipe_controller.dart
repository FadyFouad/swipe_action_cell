import 'package:flutter/foundation.dart';

import '../core/swipe_direction.dart';
import '../core/swipe_state.dart';
import 'swipe_cell_handle.dart';

/// Controller for programmatic interaction with a [SwipeActionCell].
///
/// Create a controller, pass it to [SwipeActionCell.controller], and call
/// methods to programmatically open, close, or adjust a cell:
///
/// ```dart
/// final controller = SwipeController();
///
/// // In build:
/// SwipeActionCell(
///   controller: controller,
///   leftSwipeConfig: LeftSwipeConfig(mode: LeftSwipeMode.reveal, actions: [...]),
///   child: ListTile(...),
/// )
///
/// // Elsewhere:
/// controller.openLeft();  // reveals the action panel
/// controller.close();     // snaps the cell closed
/// ```
///
/// [SwipeController] implements [ChangeNotifier]. Add a listener to react
/// to state changes:
///
/// ```dart
/// controller.addListener(() {
///   if (controller.isOpen) showCloseHint();
/// });
/// ```
///
/// **Lifecycle**: Create the controller before or after the widget mounts.
/// Call [dispose] when done — typically in [State.dispose]:
///
/// ```dart
/// @override
/// void dispose() {
///   controller.dispose();
///   super.dispose();
/// }
/// ```
class SwipeController extends ChangeNotifier {
  /// Creates a [SwipeController].
  SwipeController();

  SwipeCellHandle? _handle;
  SwipeState _currentState = SwipeState.idle;
  double _currentProgress = 0.0;
  SwipeDirection? _openDirection;
  bool _disposed = false;

  // ── Observable properties ──────────────────────────────────────────────────

  /// The current state of the attached cell's state machine.
  ///
  /// Returns [SwipeState.idle] when no cell is attached.
  SwipeState get currentState => _currentState;

  /// The current cumulative progressive value of the attached cell.
  ///
  /// Meaningful only when [SwipeActionCell.rightSwipeConfig] is non-null.
  /// Returns `0.0` when no cell is attached or when no right-swipe config
  /// is active.
  double get currentProgress => _currentProgress;

  /// Whether the attached cell is currently in the [SwipeState.revealed] state.
  bool get isOpen => _currentState == SwipeState.revealed;

  /// Whether a [SwipeCellHandle] is currently attached.
  ///
  /// Package-internal — used by [SwipeActionCellState] to avoid double-attach.
  bool get hasHandle => _handle != null;

  /// The direction the cell is open in, or `null` when [isOpen] is `false`.
  ///
  /// Returns [SwipeDirection.left] when a left-swipe reveal panel is open,
  /// [SwipeDirection.right] is not applicable (right swipe never stays open),
  /// and `null` when the cell is closed.
  SwipeDirection? get openDirection => _openDirection;

  // ── Commands ───────────────────────────────────────────────────────────────

  /// Programmatically triggers a left-swipe open on the attached cell.
  ///
  /// Behaves identically to a user swiping left past the activation threshold.
  /// Runs the completion spring animation; subsequent behaviour is determined
  /// by [LeftSwipeConfig.mode] and [LeftSwipeConfig.postActionBehavior].
  ///
  /// No-op (debug assertion in debug mode) when:
  /// - No cell is currently attached, OR
  /// - The cell has no [SwipeActionCell.leftSwipeConfig], OR
  /// - [currentState] is not [SwipeState.idle].
  void openLeft() {
    assert(
      _handle != null,
      'openLeft() called with no cell attached to this SwipeController. '
      'Ensure the controller is passed to a SwipeActionCell before calling commands.',
    );
    assert(
      _currentState == SwipeState.idle,
      'openLeft() called when currentState is $_currentState. '
      'openLeft() is only valid from the idle state.',
    );
    if (_handle == null || _currentState != SwipeState.idle) return;
    _handle!.executeOpenLeft();
  }

  /// Programmatically triggers a right-swipe increment on the attached cell.
  ///
  /// Behaves identically to a user swiping right past the activation threshold:
  /// runs the completion spring, applies the progressive increment, then
  /// snaps back to idle.
  ///
  /// No-op (debug assertion in debug mode) when:
  /// - No cell is currently attached, OR
  /// - The cell has no [SwipeActionCell.rightSwipeConfig], OR
  /// - [currentState] is not [SwipeState.idle].
  void openRight() {
    assert(
      _handle != null,
      'openRight() called with no cell attached to this SwipeController.',
    );
    assert(
      _currentState == SwipeState.idle,
      'openRight() called when currentState is $_currentState. '
      'openRight() is only valid from the idle state.',
    );
    if (_handle == null || _currentState != SwipeState.idle) return;
    _handle!.executeOpenRight();
  }

  /// Programmatically closes the attached cell, snapping it back to the
  /// resting (origin) position.
  ///
  /// No-op (debug assertion in debug mode) when:
  /// - [currentState] is not [SwipeState.revealed] or [SwipeState.animatingToOpen].
  void close() {
    final canClose = _currentState == SwipeState.revealed ||
        _currentState == SwipeState.animatingToOpen;
    assert(
      canClose,
      'close() called when currentState is $_currentState. '
      'close() is only valid from revealed or animatingToOpen states.',
    );
    if (!canClose) return;
    _handle?.executeClose();
  }

  /// Resets the progressive value of the attached cell to
  /// [RightSwipeConfig.initialValue].
  ///
  /// No-op (debug assertion in debug mode) when no cell is attached.
  void resetProgress() {
    assert(
      _handle != null,
      'resetProgress() called with no cell attached to this SwipeController.',
    );
    if (_handle == null) return;
    _handle!.executeResetProgress();
  }

  /// Sets the progressive value of the attached cell to [value], clamped
  /// to [[RightSwipeConfig.minValue]..[RightSwipeConfig.maxValue]].
  ///
  /// Does not fire [RightSwipeConfig.onProgressChanged] or
  /// [RightSwipeConfig.onSwipeCompleted]. Fires [ChangeNotifier] listeners
  /// when the clamped value differs from the current value.
  ///
  /// No-op (debug assertion in debug mode) when no cell is attached.
  void setProgress(double value) {
    assert(
      _handle != null,
      'setProgress() called with no cell attached to this SwipeController.',
    );
    if (_handle == null) return;
    _handle!.executeSetProgress(value);
  }

  // ── Package-internal ───────────────────────────────────────────────────────

  /// Attaches a [SwipeCellHandle] from [SwipeActionCellState].
  ///
  /// Called by [SwipeActionCellState] in [State.didChangeDependencies] /
  /// [State.initState]. Asserts in debug mode if a handle is already attached
  /// (one controller ↔ one cell invariant).
  ///
  /// Not for consumer use — this method is part of the package-internal
  /// bridge protocol and is not exported from the package barrel.
  void attach(SwipeCellHandle handle) {
    assert(
      _handle == null,
      'attach() called on a SwipeController that already has a handle attached. '
      'A SwipeController may only be attached to one SwipeActionCell at a time.',
    );
    _handle = handle;
  }

  /// Detaches the current [SwipeCellHandle].
  ///
  /// Called by [SwipeActionCellState] in [State.dispose].
  /// No-op if [handle] does not match the currently attached handle.
  ///
  /// Not for consumer use.
  void detach(SwipeCellHandle handle) {
    if (_handle != handle) return;
    _handle = null;
  }

  /// Called by [SwipeActionCellState] to push the latest state into this
  /// controller and notify listeners.
  ///
  /// Not for consumer use.
  void reportState(
      SwipeState state, double progress, SwipeDirection? direction) {
    if (_disposed) return;
    _currentState = state;
    _currentProgress = progress;

    // openDirection is null unless the cell is open (revealed).
    if (state == SwipeState.revealed) {
      _openDirection = direction;
    } else {
      _openDirection = null;
    }

    notifyListeners();
  }

  /// Called by [SwipeActionCellState] to update the cached progress value
  /// without a full state transition. Skips notification when the value is
  /// unchanged.
  ///
  /// Not for consumer use.
  void reportProgress(double progress) {
    if (_disposed) return;
    if (progress == _currentProgress) return;
    _currentProgress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
