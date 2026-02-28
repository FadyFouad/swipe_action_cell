import 'package:flutter/widgets.dart';
import 'task_repository.dart';

/// A simple [InheritedWidget] to provide the [TaskRepository] down the tree.
class TaskScope extends InheritedWidget {
  final TaskRepository repository;

  const TaskScope({
    super.key,
    required this.repository,
    required super.child,
  });

  static TaskRepository of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<TaskScope>();
    assert(result != null, 'No TaskScope found in context');
    return result!.repository;
  }

  @override
  bool updateShouldNotify(TaskScope oldWidget) =>
      repository != oldWidget.repository;
}
