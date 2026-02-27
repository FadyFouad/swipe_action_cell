import 'package:flutter/widgets.dart';

import 'swipe_group_controller.dart';

// ---------------------------------------------------------------------------
// _SwipeControllerScope — package-internal InheritedWidget
// ---------------------------------------------------------------------------

/// Package-internal [InheritedWidget] that makes a [SwipeGroupController]
/// accessible to descendant [SwipeActionCell] widgets.
///
/// Uses a **non-reactive** lookup so cells do NOT rebuild when the group
/// controller reference changes — they only need the reference at mount/unmount
/// time, not reactively.
class _SwipeControllerScope extends InheritedWidget {
  const _SwipeControllerScope({
    required this.controller,
    required super.child,
  });

  /// The group controller provided to descendant cells.
  final SwipeGroupController controller;

  /// Returns the [SwipeGroupController] from the nearest
  /// [_SwipeControllerScope] ancestor, or `null` if none is present.
  ///
  /// Uses [BuildContext.getElementForInheritedWidgetOfExactType] (non-reactive)
  /// so the calling widget does NOT subscribe to rebuild notifications.
  static SwipeGroupController? maybeOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_SwipeControllerScope>();
    return (element?.widget as _SwipeControllerScope?)?.controller;
  }

  @override
  bool updateShouldNotify(_SwipeControllerScope oldWidget) =>
      controller != oldWidget.controller;
}

// ---------------------------------------------------------------------------
// SwipeControllerProvider — public StatefulWidget
// ---------------------------------------------------------------------------

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
  static SwipeGroupController? maybeGroupOf(BuildContext context) =>
      _SwipeControllerScope.maybeOf(context);

  @override
  State<SwipeControllerProvider> createState() =>
      _SwipeControllerProviderState();
}

class _SwipeControllerProviderState extends State<SwipeControllerProvider> {
  late final SwipeGroupController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = SwipeGroupController();
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SwipeControllerScope(
      controller: widget.groupController ?? _internalController,
      child: widget.child,
    );
  }
}
