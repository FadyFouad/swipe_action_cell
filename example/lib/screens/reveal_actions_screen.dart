import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Demonstrates [LeftSwipeMode.reveal] — a panel of tappable action buttons
/// slides in from the right edge when the user swipes left far enough.
///
/// Contrast with [LeftSwipeMode.autoTrigger], which fires immediately on
/// threshold crossing. In reveal mode the panel stays open until the user
/// taps an action or taps elsewhere to close it.
class RevealActionsScreen extends StatefulWidget {
  /// Creates the reveal actions demo screen.
  const RevealActionsScreen({super.key});

  @override
  State<RevealActionsScreen> createState() => _RevealActionsScreenState();
}

class _RevealActionsScreenState extends State<RevealActionsScreen> {
  String _lastAction = 'None';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reveal Actions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Left swipe to reveal Archive and Delete buttons.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text('Last action: $_lastAction',
              style: const TextStyle(fontSize: 12, color: Colors.blue)),
          const SizedBox(height: 16),
          SwipeActionCell(
            // LeftSwipeMode.reveal shows the action panel without triggering
            // anything automatically. The user must tap an action button.
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.reveal,
              enableHaptic: true,

              // actions: list of SwipeAction buttons shown in the reveal panel.
              // Each SwipeAction has an icon, label, background color,
              // and an onTap callback.
              actions: [
                SwipeAction(
                  // icon must be a Widget, not IconData.
                  icon: const Icon(Icons.archive_outlined),
                  label: 'Archive',
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: const Color(0xFFFFFFFF),
                  onTap: () {
                    setState(() => _lastAction = 'Archive');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Archived!')),
                    );
                  },
                ),
                SwipeAction(
                  icon: const Icon(Icons.delete_outline),
                  label: 'Delete',
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: const Color(0xFFFFFFFF),
                  onTap: () {
                    setState(() => _lastAction = 'Delete');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deleted!')),
                    );
                  },
                ),
              ],
              fullSwipeConfig: FullSwipeConfig(
                enabled: true,

                threshold: .5,
                action: SwipeAction(
                  icon: const Icon(Icons.delete_outline),
                  label: 'Delete',
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: const Color(0xFFFFFFFF),
                  onTap: () {
                    setState(() => _lastAction = 'Delete');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deleted (Full Swipe)!')),
                    );
                  },
                ),
              ),
            ),
            child: const Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('Email from Alice'),
                subtitle: Text('Swipe left to reveal Archive or Delete'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
