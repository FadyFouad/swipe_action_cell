import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Demonstrates the simplest possible left + right swipe configuration.
///
/// - Left swipe: [LeftSwipeMode.autoTrigger] fires the delete callback
///   immediately after the activation threshold is crossed.
/// - Right swipe: [RightSwipeConfig] increments a counter shown in the subtitle.
class BasicScreen extends StatefulWidget {
  /// Creates the basic demo screen.
  const BasicScreen({super.key});

  @override
  State<BasicScreen> createState() => _BasicScreenState();
}

class _BasicScreenState extends State<BasicScreen> {
  // Tracks the number of successful right swipes.
  int _rightCount = 0;
  // Tracks whether the item has been deleted.
  bool _deleted = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Swipe Demo',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Right swipe → increments counter  |  Left swipe → delete with undo',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (_deleted)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Item deleted'),
                subtitle: Text('Swipe was committed after undo window expired'),
              ),
            )
          else
            // SwipeActionCell wraps any child widget.
            SwipeActionCell(
              // rightSwipeConfig enables progressive right-swipe semantics.
              // stepValue: 1.0 (default) increments _rightCount by 1 per swipe.
              rightSwipeConfig: RightSwipeConfig(
                enableHaptic: true,
                onSwipeCompleted: (newValue) {
                  setState(() => _rightCount = newValue.toInt());
                },
              ),
              // leftSwipeConfig: autoTrigger fires after crossing threshold.
              // postActionBehavior: animateOut slides the cell off-screen,
              // then fires onDeleted after the undo window expires.
              leftSwipeConfig: const LeftSwipeConfig(
                mode: LeftSwipeMode.autoTrigger,
                postActionBehavior: PostActionBehavior.animateOut,
                enableHaptic: true,
              ),
              undoConfig: SwipeUndoConfig(
                onUndoExpired: () => setState(() => _deleted = true),
              ),
              // visualConfig: sets background colors for each swipe direction.
              visualConfig: SwipeVisualConfig(
                rightBackground: (context, progress) => ColoredBox(
                  color: Colors.blue.shade400,
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                leftBackground: (context, progress) => ColoredBox(
                  color: Colors.red.shade400,
                  child: const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete_outline,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.inbox),
                  title: const Text('Swipeable item'),
                  subtitle: Text('Right swipes: $_rightCount'),
                  trailing: const Icon(Icons.drag_handle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
