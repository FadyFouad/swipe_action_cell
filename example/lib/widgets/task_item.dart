import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import '../models/task.dart';
import '../providers/task_scope.dart';

class TaskItem extends StatelessWidget {
  final Task task;

  const TaskItem({super.key, required this.task});

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.none:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskRepository = TaskScope.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: SwipeActionCell(
        // 1. Right Swipe (Forward): Progressive Priority Increment
        // This demonstrates the "Progressive" feature where repeated swipes
        // increment a value (priority level in this case).
        rightSwipeConfig: RightSwipeConfig(
          initialValue: task.priority.level.toDouble(),
          minValue: 0,
          maxValue: 4,
          stepValue: 1,
          overflowBehavior: OverflowBehavior.wrap, // Wraps back to 0 after 4
          enableHaptic: true,
          showProgressIndicator: true,
          progressIndicatorConfig: ProgressIndicatorConfig(
            color: _getPriorityColor(task.priority),
            width: 6,
          ),
          onSwipeCompleted: (value) {
            final newPriority = TaskPriority.fromLevel(value.toInt());
            taskRepository.updateTaskPriority(task.id, newPriority);
          },
        ),

        // 2. Left Swipe (Backward): Reveal Action Panel
        // This demonstrates the "Intentional" feature where swiping reveals
        // a set of buttons for specific actions.
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          enableHaptic: true,
          actions: [
            SwipeAction(
              icon: const Icon(Icons.archive_outlined),
              label: 'Archive',
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              onTap: () => taskRepository.archiveTask(task.id),
            ),
            SwipeAction(
              icon: const Icon(Icons.delete_outline),
              label: 'Delete',
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              onTap: () => taskRepository.deleteTask(task.id),
            ),
          ],
        ),

        // Visual configuration for the cell
        visualConfig: SwipeVisualConfig(
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          // Custom backgrounds for swipe states
          rightBackground: (context, progress) {
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              color: _getPriorityColor(
                TaskPriority.fromLevel(
                  ((task.priority.level + 1) % 5),
                ),
              ).withOpacity(0.2),
              child: const Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Change Priority',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
          leftBackground: (context, progress) {
            return Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.grey.shade200,
              child: const Icon(Icons.more_horiz, color: Colors.black54),
            );
          },
        ),

        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _PriorityIndicator(priority: task.priority),
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityIndicator({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (priority) {
      case TaskPriority.urgent:
        color = Colors.red;
        label = '!!';
        break;
      case TaskPriority.high:
        color = Colors.orange;
        label = '!';
        break;
      case TaskPriority.medium:
        color = Colors.blue;
        label = 'M';
        break;
      case TaskPriority.low:
        color = Colors.green;
        label = 'L';
        break;
      case TaskPriority.none:
        color = Colors.grey;
        label = '-';
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
