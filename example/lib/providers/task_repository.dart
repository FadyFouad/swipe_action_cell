import 'package:flutter/foundation.dart';
import '../models/task.dart';

/// A simple, dependency-free state management solution using [ValueNotifier].
///
/// This repository manages the task list and notifies listeners of any changes.
/// In a real-world app, this could be backed by a local database or remote API.
class TaskRepository extends ValueNotifier<List<Task>> {
  TaskRepository() : super(_initialTasks);

  static final List<Task> _initialTasks = [
    Task(
      id: '1',
      title: 'Review PR for Swipe UI',
      description: 'Check the animation performance on low-end devices.',
      priority: TaskPriority.high,
    ),
    Task(
      id: '2',
      title: 'Update Documentation',
      description: 'Add examples for the new progressive swipe feature.',
      priority: TaskPriority.medium,
    ),
    Task(
      id: '3',
      title: 'Sprint Planning',
      description: 'Prepare the board for the next cycle.',
      priority: TaskPriority.urgent,
    ),
    Task(
      id: '4',
      title: 'Grocery Shopping',
      description: 'Buy milk, eggs, and bread.',
      priority: TaskPriority.low,
    ),
    Task(
      id: '5',
      title: 'Fix Gesture Conflicts',
      description: 'Investigate reports of horizontal scroll issues.',
      priority: TaskPriority.none,
    ),
  ];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Task> get activeTasks =>
      value.where((t) => t.status == TaskStatus.active).toList();

  List<Task> get completedTasks =>
      value.where((t) => t.status == TaskStatus.completed).toList();

  Future<void> refreshTasks() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    notifyListeners();
  }

  void updateTaskPriority(String id, TaskPriority priority) {
    final updatedList = List<Task>.from(value);
    final index = updatedList.indexWhere((t) => t.id == id);
    if (index != -1) {
      updatedList[index] = updatedList[index].copyWith(priority: priority);
      value = updatedList;
    }
  }

  void completeTask(String id) {
    final updatedList = List<Task>.from(value);
    final index = updatedList.indexWhere((t) => t.id == id);
    if (index != -1) {
      updatedList[index] =
          updatedList[index].copyWith(status: TaskStatus.completed);
      value = updatedList;
    }
  }

  void archiveTask(String id) {
    final updatedList = List<Task>.from(value);
    final index = updatedList.indexWhere((t) => t.id == id);
    if (index != -1) {
      updatedList[index] =
          updatedList[index].copyWith(status: TaskStatus.archived);
      value = updatedList;
    }
  }

  void deleteTask(String id) {
    final updatedList = List<Task>.from(value);
    updatedList.removeWhere((t) => t.id == id);
    value = updatedList;
  }

  void restoreTask(String id) {
    final updatedList = List<Task>.from(value);
    final index = updatedList.indexWhere((t) => t.id == id);
    if (index != -1) {
      updatedList[index] =
          updatedList[index].copyWith(status: TaskStatus.active);
      value = updatedList;
    }
  }
}
