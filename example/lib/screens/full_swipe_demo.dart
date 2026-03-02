import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Showcase for the Full-Swipe Auto-Trigger feature (F016).
///
/// This screen demonstrates various ways to configure the "release-to-trigger"
/// behavior for both intentional (left) and progressive (right) swipes.
class FullSwipeDemo extends StatefulWidget {
  const FullSwipeDemo({super.key});

  @override
  State<FullSwipeDemo> createState() => _FullSwipeDemoState();
}

class _FullSwipeDemoState extends State<FullSwipeDemo> {
  final Map<String, double> _progressiveValues = {};

  void _showTriggered(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Full-swipe triggered: $action'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader('Intentional Full-Swipe (Left)'),
        _buildItem(
          title: 'Full-swipe to Delete',
          subtitle: 'iOS Mail style: drag far left to delete immediately.',
          leftConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            actions: [
              SwipeAction(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: 'Delete',
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Delete'),
              ),
            ],
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              threshold: 0.7,
              action: SwipeAction(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: 'Delete',
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Delete (Full)'),
              ),
            ),
          ),
        ),
        _buildItem(
          title: 'Full-swipe to Archive',
          subtitle: 'Different color and action on full drag.',
          leftConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            actions: [
              SwipeAction(
                icon: const Icon(Icons.archive, color: Colors.white),
                label: 'Archive',
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Archive'),
              ),
            ],
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              threshold: 0.7,
              action: SwipeAction(
                icon: const Icon(Icons.archive, color: Colors.white),
                label: 'Archive',
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Archive (Full)'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildHeader('Progressive Full-Swipe (Right)'),
        _buildItem(
          title: 'Full-swipe to Max Out',
          subtitle: 'Drag far right to set value to 100 instantly.',
          rightConfig: RightSwipeConfig(
            maxValue: 100,
            onSwipeCompleted: (val) {
              setState(() => _progressiveValues['max'] = val);
              if (val >= 100) _showTriggered('Max Out');
            },
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              threshold: 0.75,
              fullSwipeProgressBehavior: FullSwipeProgressBehavior.setToMax,
              action: SwipeAction(
                icon: const Icon(Icons.speed, color: Colors.white),
                label: 'Max Out',
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                onTap: () {}, // Not used for setToMax
              ),
            ),
          ),
          trailing: Text('${_progressiveValues['max']?.toInt() ?? 0}%'),
        ),
        _buildItem(
          title: 'Full-swipe Custom Action',
          subtitle: 'Progressive drag that triggers a special action.',
          rightConfig: RightSwipeConfig(
            onSwipeCompleted: (val) {
              setState(() => _progressiveValues['custom'] = val);
            },
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              threshold: 0.75,
              fullSwipeProgressBehavior: FullSwipeProgressBehavior.customAction,
              action: SwipeAction(
                icon: const Icon(Icons.star, color: Colors.white),
                label: 'Feature',
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Featured!'),
              ),
            ),
          ),
          trailing: Text('Count: ${_progressiveValues['custom']?.toInt() ?? 0}'),
        ),
        const SizedBox(height: 24),
        _buildHeader('Advanced Configurations'),
        _buildItem(
          title: 'Bidirectional Full-Swipe',
          subtitle: 'Delete (left) or Star (right) with full drag.',
          leftConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            actions: [
              SwipeAction(
                icon: const Icon(Icons.delete, color: Colors.white),
                onTap: () => _showTriggered('Delete'),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ],
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              action: SwipeAction(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: 'Delete',
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Delete (Full)'),
              ),
            ),
          ),
          rightConfig: RightSwipeConfig(
            onSwipeCompleted: (_) {},
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              action: SwipeAction(
                icon: const Icon(Icons.star, color: Colors.white),
                label: 'Star',
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Star (Full)'),
              ),
            ),
          ),
        ),
        _buildItem(
          title: 'Full-swipe with Undo',
          subtitle: 'Triggered action can be reverted.',
          leftConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.autoTrigger,
            postActionBehavior: PostActionBehavior.animateOut,
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              action: SwipeAction(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: 'Delete',
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Delete (Full)'),
              ),
            ),
          ),
          undoConfig: SwipeUndoConfig(
            onUndoTriggered: () => _showTriggered('Undo!'),
            onUndoExpired: () => _showTriggered('Committed'),
          ),
        ),
        _buildItem(
          title: 'Zones + Full-Swipe',
          subtitle: 'Multi-threshold zones with a final full-swipe trigger.',
          leftConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            zones: [
              SwipeZone(
                threshold: 0.3,
                color: Colors.blue.withOpacity(0.5),
                semanticLabel: 'Zone 1',
                onActivated: () => _showTriggered('Zone 1'),
              ),
              SwipeZone(
                threshold: 0.5,
                color: Colors.blue,
                semanticLabel: 'Zone 2',
                onActivated: () => _showTriggered('Zone 2'),
              ),
            ],
            fullSwipeConfig: FullSwipeConfig(
              enabled: true,
              threshold: 0.8,
              action: SwipeAction(
                icon: const Icon(Icons.bolt, color: Colors.white),
                label: 'Super Action',
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('Super Full Swipe!'),
              ),
            ),
            actions: [
              SwipeAction(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                label: 'More',
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                onTap: () => _showTriggered('More'),
              ),
            ],
          ),
        ),
        _buildItem(
          title: 'Full-swipe Disabled',
          subtitle: 'Compare with standard reveal behavior.',
          leftConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            actions: [
              SwipeAction(
                icon: const Icon(Icons.settings, color: Colors.white),
                label: 'Setup',
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                onTap: _noOp, // Required parameter
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _noOp() {}

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required String subtitle,
    LeftSwipeConfig? leftConfig,
    RightSwipeConfig? rightConfig,
    SwipeUndoConfig? undoConfig,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwipeActionCell(
        leftSwipeConfig: leftConfig,
        rightSwipeConfig: rightConfig,
        undoConfig: undoConfig,
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(title),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: trailing ?? const Icon(Icons.chevron_left, color: Colors.grey, size: 16),
          ),
        ),
      ),
    );
  }
}
