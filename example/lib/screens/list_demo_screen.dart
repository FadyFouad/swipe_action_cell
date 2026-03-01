import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Demonstrates [SwipeGroupController] for accordion behavior in a long list.
///
/// [SwipeGroupController] ensures at most one cell is open at a time:
/// opening a new cell automatically closes any previously open cell.
///
/// Each item gets its own [SwipeController] via [SwipeGroupController.register].
/// The group controller wires them together so only one cell stays open.
class ListDemoScreen extends StatefulWidget {
  /// Creates the list demo screen.
  const ListDemoScreen({super.key});

  @override
  State<ListDemoScreen> createState() => _ListDemoScreenState();
}

class _ListDemoScreenState extends State<ListDemoScreen> {
  // 50 list items.
  final List<String> _items = List.generate(50, (i) => 'Item ${i + 1}');

  // SwipeGroupController coordinates all per-row controllers.
  // Dispose it in dispose() to avoid leaks.
  final SwipeGroupController _group = SwipeGroupController();

  // Per-item controllers stored by index so they survive rebuilds.
  final Map<int, SwipeController> _controllers = {};

  SwipeController _controllerFor(int index) {
    return _controllers.putIfAbsent(index, () {
      final c = SwipeController();
      // Register each controller with the group so accordion behavior applies.
      _group.register(c);
      return c;
    });
  }

  @override
  void dispose() {
    // Always dispose the group controller (removes listeners from all members).
    _group.dispose();
    // Dispose individual controllers.
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final label = _items[index];

        // SwipeActionCell.delete factory wraps the cell with a 5-second undo
        // strip. onDeleted fires after the window expires.
        return SwipeActionCell.delete(
          // controller: ties this cell to the group for accordion behavior.
          controller: _controllerFor(index),
          onDeleted: () {
            setState(() {
              _items.removeAt(index);
              // Remove and dispose the controller for the deleted item.
              final removed = _controllers.remove(index);
              _group.unregister(removed!);
              removed.dispose();
            });
          },
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(label),
            subtitle: const Text('Left swipe to delete (with undo)'),
          ),
        );
      },
    );
  }
}
