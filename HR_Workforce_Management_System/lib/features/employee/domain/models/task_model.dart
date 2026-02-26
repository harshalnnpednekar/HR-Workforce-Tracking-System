/// Enum representing the status of a task.
enum TaskStatus { todo, inProgress, completed }

/// Domain model for a Task with strict null-safety.
class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final TaskStatus status;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
  });

  /// Creates a copy of this [TaskModel] but with the given fields replaced with the new values.
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskStatus? status,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
    );
  }
}
