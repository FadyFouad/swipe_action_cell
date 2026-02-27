# Contract: Programmatic Control & Multi-Cell Coordination (F006)

**Branch**: `006-controller-group` | **Date**: 2026-02-27
**Spec**: [spec.md](../spec.md) | **Data Model**: [data-model.md](../data-model.md)

All signatures are normative — implementation MUST match exactly.
Internal helpers not listed here.

---

## `lib/src/controller/swipe_cell_handle.dart` (new, NOT exported)

```dart
/// Package-internal contract between [SwipeController] and [SwipeActionCellState].
///
/// [SwipeActionCellState] implements this interface and registers itself via
/// [SwipeController.attach]. This file is not exported from the package barrel
/// and is not part of the consumer-facing API.
abstract class SwipeCellHandle {
  /// Triggers the left-swipe completion animation and all associated
  /// post-action behaviour (action trigger, reveal, etc.), exactly as if
  /// the user had dragged past the activation threshold.
  void executeOpenLeft();

  /// Triggers the right-swipe completion animation and progressive increment,
  /// exactly as if the user had dragged past the activation threshold.
  void executeOpenRight();

  /// Triggers the snap-back animation from the current offset to the
  /// closed (origin) position.
  void executeClose();

  /// Sets the progressive value back to [RightSwipeConfig.initialValue].
  void executeResetProgress();

  /// Sets the progressive value to [value], clamped to
  /// [RightSwipeConfig.minValue]..[RightSwipeConfig.maxValue].
  void executeSetProgress(double value);
}
```

---

## `lib/src/controller/swipe_controller.dart` (replaces stub)

```dart
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
  void openLeft();

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
  void openRight();

  /// Programmatically closes the attached cell, snapping it back to the
  /// resting (origin) position.
  ///
  /// No-op (debug assertion in debug mode) when:
  /// - [currentState] is not [SwipeState.revealed] or [SwipeState.animatingToOpen].
  void close();

  /// Resets the progressive value of the attached cell to
  /// [RightSwipeConfig.initialValue].
  ///
  /// No-op (debug assertion in debug mode) when no cell is attached.
  void resetProgress();

  /// Sets the progressive value of the attached cell to [value], clamped
  /// to [[RightSwipeConfig.minValue]..[RightSwipeConfig.maxValue]].
  ///
  /// Does not fire [RightSwipeConfig.onProgressChanged] or
  /// [RightSwipeConfig.onSwipeCompleted]. Fires [ChangeNotifier] listeners
  /// when the clamped value differs from the current value.
  ///
  /// No-op (debug assertion in debug mode) when no cell is attached.
  void setProgress(double value);

  // ── Package-internal ───────────────────────────────────────────────────────

  /// Attaches a [SwipeCellHandle] from [SwipeActionCellState].
  ///
  /// Called by [SwipeActionCellState] in [State.didChangeDependencies] /
  /// [State.initState]. Asserts in debug mode if a handle is already attached
  /// (one controller ↔ one cell invariant).
  ///
  /// Not for consumer use — this method is part of the package-internal
  /// bridge protocol and is not exported from the package barrel.
  void attach(SwipeCellHandle handle);

  /// Detaches the current [SwipeCellHandle].
  ///
  /// Called by [SwipeActionCellState] in [State.dispose].
  /// No-op if [handle] does not match the currently attached handle.
  ///
  /// Not for consumer use.
  void detach(SwipeCellHandle handle);

  /// Called by [SwipeActionCellState] to push the latest state into this
  /// controller and notify listeners.
  ///
  /// Not for consumer use.
  void reportState(SwipeState state, double progress, SwipeDirection? direction);
}
```

---

## `lib/src/controller/swipe_group_controller.dart` (new)

```dart
import 'package:flutter/foundation.dart';
import 'swipe_controller.dart';
import '../core/swipe_state.dart';

/// Coordinates multiple [SwipeController] instances to enforce the accordion
/// invariant: at most one registered cell is open at any time.
///
/// **Manual usage** (explicit list management):
///
/// ```dart
/// final group = SwipeGroupController();
///
/// // Register controllers:
/// group.register(controllerA);
/// group.register(controllerB);
///
/// // Now opening A automatically closes B, and vice versa.
///
/// // Cleanup:
/// group.dispose();
/// ```
///
/// **Automatic usage** (recommended for lists):
///
/// Wrap your [ListView] in [SwipeControllerProvider] — registration and
/// deregistration are handled automatically as cells mount and unmount.
///
/// See also: [SwipeControllerProvider].
class SwipeGroupController extends ChangeNotifier {
  /// Creates a [SwipeGroupController].
  SwipeGroupController();

  /// Registers [controller] with this group.
  ///
  /// Once registered, opening this cell will close all other registered cells.
  /// No-op if [controller] is already registered.
  void register(SwipeController controller);

  /// Removes [controller] from this group.
  ///
  /// After unregistration, the controller is no longer subject to accordion
  /// behaviour. No-op if [controller] is not registered.
  void unregister(SwipeController controller);

  /// Closes every currently open registered cell.
  ///
  /// Calls [SwipeController.close] on each registered controller whose
  /// [SwipeController.isOpen] is `true`. Safe to call when no cells are open.
  void closeAll();

  /// Closes every registered cell except [controller].
  ///
  /// Calls [SwipeController.close] on each registered controller whose
  /// [SwipeController.isOpen] is `true`, excluding [controller].
  ///
  /// If [controller] is not registered in this group, the behaviour is the
  /// same as [closeAll].
  void closeAllExcept(SwipeController controller);
}
```

---

## `lib/src/controller/swipe_controller_provider.dart` (new)

```dart
import 'package:flutter/widgets.dart';
import 'swipe_group_controller.dart';

/// Provides a shared [SwipeGroupController] to all descendant
/// [SwipeActionCell] widgets, enabling automatic accordion behaviour without
/// any manual controller management.
///
/// Wrap a [ListView] (or any widget that contains [SwipeActionCell] children)
/// in [SwipeControllerProvider]:
///
/// ```dart
/// SwipeControllerProvider(
///   child: ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, index) => SwipeActionCell(
///       leftSwipeConfig: LeftSwipeConfig(
///         mode: LeftSwipeMode.reveal,
///         actions: [...],
///       ),
///       child: ListTile(title: Text(items[index].title)),
///     ),
///   ),
/// )
/// ```
///
/// When any cell opens, all other cells in the list close automatically.
/// Cells that scroll out of view are unregistered and re-registered as
/// they re-enter view — no memory leaks, no dangling references.
///
/// **Custom group**: To share a group across multiple providers, or to
/// retain programmatic group access, pass an explicit [groupController]:
///
/// ```dart
/// final group = SwipeGroupController();
///
/// SwipeControllerProvider(
///   groupController: group,
///   child: myListView,
/// )
/// ```
///
/// Dispose a custom [groupController] manually when done.
class SwipeControllerProvider extends StatefulWidget {
  /// Creates a [SwipeControllerProvider].
  const SwipeControllerProvider({
    super.key,
    this.groupController,
    required this.child,
  });

  /// An externally managed group controller.
  ///
  /// When `null` (default), [SwipeControllerProvider] creates and manages
  /// an internal [SwipeGroupController]. When non-null, the provided
  /// controller is used and its lifecycle is the consumer's responsibility.
  final SwipeGroupController? groupController;

  /// The widget subtree that will have access to the group controller.
  final Widget child;

  /// Returns the [SwipeGroupController] from the nearest
  /// [SwipeControllerProvider] ancestor, or `null` if none is present.
  ///
  /// Used by [SwipeActionCellState] to auto-register on mount.
  static SwipeGroupController? maybeGroupOf(BuildContext context);
}
```

---

## `lib/src/widget/swipe_action_cell.dart` (additions to existing)

**New fields on `SwipeActionCellState`** (do not change the public widget interface):

```dart
// Internal controller created when widget.controller == null.
SwipeController? _internalController;

// The effective controller: widget.controller ?? _internalController.
SwipeController get _effectiveController =>
    widget.controller ?? _internalController!;

// The group this cell is currently registered with (cached to enable cleanup).
SwipeGroupController? _registeredGroup;
```

**Modified hooks** (additions only — existing logic preserved):

```dart
@override
void initState() {
  // [existing code unchanged]
  // NEW: create internal controller if consumer provided none
  if (widget.controller == null) {
    _internalController = SwipeController();
  }
}

@override
void didChangeDependencies() {
  // [existing _resolveEffectiveConfigs() and _initProgressiveNotifier() unchanged]
  // NEW: attach handle and sync group registration
  _effectiveController.attach(this);  // idempotent when handle already matches
  _syncGroupRegistration();
}

@override
void didUpdateWidget(SwipeActionCell oldWidget) {
  // [existing logic unchanged]
  // NEW: handle controller change
  if (widget.controller != oldWidget.controller) {
    _registeredGroup?.unregister(_controllerFor(oldWidget));
    _controllerFor(oldWidget).detach(this);
    if (widget.controller == null && _internalController == null) {
      _internalController = SwipeController();
    } else if (widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
    }
    _effectiveController.attach(this);
    _registeredGroup?.register(_effectiveController);
  }
}

@override
void dispose() {
  // [existing controller and notifier dispose unchanged]
  // NEW: detach and unregister
  _registeredGroup?.unregister(_effectiveController);
  _effectiveController.detach(this);
  _internalController?.dispose();
  super.dispose();
}
```

**New helper** (internal):

```dart
void _syncGroupRegistration() {
  final newGroup = SwipeControllerProvider.maybeGroupOf(context);
  if (newGroup == _registeredGroup) return;
  _registeredGroup?.unregister(_effectiveController);
  _registeredGroup = newGroup;
  _registeredGroup?.register(_effectiveController);
}
```

**Modified `_updateState`** (push state to controller):

```dart
void _updateState(SwipeState newState) {
  if (_state == newState) return;
  setState(() { _state = newState; });
  widget.onStateChanged?.call(newState);
  // NEW: push to controller
  _effectiveController.reportState(
    newState,
    _progressValueNotifier?.value ?? 0.0,
    newState == SwipeState.revealed ? _lockedDirection : null,
  );
}
```

---

## `lib/swipe_action_cell.dart` (barrel additions)

```dart
// Add to existing exports:
export 'src/controller/swipe_group_controller.dart';
export 'src/controller/swipe_controller_provider.dart';
// swipe_controller.dart already exported in F6
// swipe_cell_handle.dart is NOT exported (package-internal)
```

---

## Test Files

| Test file | Coverage |
|-----------|----------|
| `test/controller/swipe_controller_test.dart` | Full API: open/close/progress/reset, state machine enforcement, ChangeNotifier, lifecycle, standalone (no group) |
| `test/controller/swipe_group_controller_test.dart` | register/unregister, accordion, closeAll, closeAllExcept, rapid register/unregister |
| `test/widget/swipe_action_cell_controller_test.dart` | Widget integration: attach/detach, programmatic open/close in widget tree, state preserved across rebuilds |
| `test/widget/swipe_controller_provider_test.dart` | Provider auto-registration, accordion via gesture, rapid ListView scroll recycling, explicit groupController |
