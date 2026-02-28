import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import '../providers/task_scope.dart';
import '../models/task.dart';
import 'task_item.dart';
import 'completed_task_item.dart';
import 'empty_state.dart';

class TaskList extends StatelessWidget {
  final bool showCompleted;

  const TaskList({super.key, this.showCompleted = false});

  @override
  Widget build(BuildContext context) {
    final taskRepository = TaskScope.of(context);

    // Using ValueListenableBuilder to rebuild only when the task list changes.
    // This is a native Flutter way to handle state without external packages.
    return ValueListenableBuilder<List<Task>>(
      valueListenable: taskRepository,
      builder: (context, allTasks, _) {
        final tasks = showCompleted 
            ? taskRepository.completedTasks 
            : taskRepository.activeTasks;

        if (taskRepository.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tasks.isEmpty) {
          return EmptyState(
            title: showCompleted ? 'No completed tasks' : 'All caught up!',
            message: showCompleted
                ? 'Complete some tasks to see them here.'
                : 'Swipe right on a task to change priority, or left for actions.',
            icon: showCompleted ? Icons.check_circle_outline : Icons.task_alt,
          );
        }

        // Using SwipeControllerProvider to group all cells in this list.
        // This enables the "Accordion" behavior where opening one cell
        // automatically closes any other open cell in the same group.
        return SwipeControllerProvider(
          groupController: SwipeGroupController(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              if (showCompleted) {
                return CompletedTaskItem(key: ValueKey(task.id), task: task);
              }
              return TaskItem(key: ValueKey(task.id), task: task);
            },
          ),
        );
      },
    );
  }
}
