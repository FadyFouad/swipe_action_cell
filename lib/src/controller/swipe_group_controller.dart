import 'package:flutter/foundation.dart';

import '../core/swipe_state.dart';
import 'swipe_controller.dart';

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

  final Set<SwipeController> _controllers = {};
  final Map<SwipeController, VoidCallback> _listeners = {};

  /// Registers [controller] with this group.
  ///
  /// Once registered, opening this cell will close all other registered cells.
  /// No-op if [controller] is already registered.
  void register(SwipeController controller) {
    if (_controllers.contains(controller)) return;
    _controllers.add(controller);
    void listener() {
      final s = controller.currentState;
      if (s == SwipeState.animatingToOpen || s == SwipeState.dragging) {
        closeAllExcept(controller);
      }
    }

    _listeners[controller] = listener;
    controller.addListener(listener);
  }

  /// Removes [controller] from this group.
  ///
  /// After unregistration, the controller is no longer subject to accordion
  /// behaviour. No-op if [controller] is not registered.
  void unregister(SwipeController controller) {
    if (!_controllers.contains(controller)) return;
    final listener = _listeners.remove(controller);
    if (listener != null) {
      controller.removeListener(listener);
    }
    _controllers.remove(controller);
  }

  /// Closes every currently open registered cell.
  ///
  /// Calls [SwipeController.close] on each registered controller whose
  /// [SwipeController.isOpen] is `true` or which is currently in the 
  /// [SwipeState.animatingToOpen] state.
  ///
  /// Safe to call when no cells are open.
  void closeAll() {
    for (final c in List<SwipeController>.from(_controllers)) {
      final shouldClose = c.isOpen || c.currentState == SwipeState.animatingToOpen;
      if (shouldClose) {
        c.close();
      }
    }
  }

  /// Closes every registered cell except [controller].
  ///
  /// Calls [SwipeController.close] on each registered controller whose
  /// [SwipeController.isOpen] is `true`, excluding [controller].
  ///
  /// If [controller] is not registered in this group, the behaviour is the
  /// same as [closeAll].
  void closeAllExcept(SwipeController controller) {
    for (final c in List<SwipeController>.from(_controllers)) {
      if (c == controller) continue;
      
      final shouldClose = c.isOpen || c.currentState == SwipeState.animatingToOpen;
      if (shouldClose) {
        c.close();
      }
    }
  }

  @override
  void dispose() {
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
    _controllers.clear();
    super.dispose();
  }
}
