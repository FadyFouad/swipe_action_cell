enum TaskStatus {
  active,
  completed,
  archived,
}

enum TaskPriority {
  none(0),
  low(1),
  medium(2),
  high(3),
  urgent(4);

  final int level;
  const TaskPriority(this.level);

  static TaskPriority fromLevel(int level) {
    return TaskPriority.values.firstWhere(
      (p) => p.level == (level.clamp(0, 4)),
      orElse: () => TaskPriority.none,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.status = TaskStatus.active,
    this.priority = TaskPriority.none,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
    );
  }
}
