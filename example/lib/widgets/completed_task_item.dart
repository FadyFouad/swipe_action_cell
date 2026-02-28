import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import '../models/task.dart';
import '../providers/task_scope.dart';

class CompletedTaskItem extends StatelessWidget {
  final Task task;

  const CompletedTaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskRepository = TaskScope.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: SwipeActionCell(
        // Demonstrating auto-trigger mode. Swiping far enough to the left
        // will automatically trigger the delete action.
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.animateOut,
          requireConfirmation:
              true, // Requires a second swipe or a tap to confirm
          enableHaptic: true,
          onActionTriggered: () {
            taskRepository.deleteTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${task.title} deleted')),
            );
          },
        ),

        // Demonstrating right-to-left recovery (restore to active)
        rightSwipeConfig: RightSwipeConfig(
          maxValue: 1,
          stepValue: 1,
          onSwipeCompleted: (_) => taskRepository.restoreTask(task.id),
        ),

        visualConfig: SwipeVisualConfig(
          borderRadius: BorderRadius.circular(12),
          leftBackground: (context, progress) {
            return Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: progress.isActivated ? Colors.red : Colors.red.shade200,
              child: const Icon(Icons.delete_forever, color: Colors.white),
            );
          },
          rightBackground: (context, progress) {
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              color: Colors.green.shade200,
              child: const Icon(Icons.restore, color: Colors.white),
            );
          },
        ),

        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              task.title,
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              ),
            ),
            subtitle: const Text('Swipe left to delete permanently'),
          ),
        ),
      ),
    );
  }
}
