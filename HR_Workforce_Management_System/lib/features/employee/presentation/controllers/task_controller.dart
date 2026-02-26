import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/task_model.dart';

/// Provider for the currently selected task filter.
final taskFilterProvider = StateProvider<TaskStatus?>((ref) => null);

/// Controller to manage the list of employee tasks.
class EmployeeTaskController extends StateNotifier<List<TaskModel>> {
  EmployeeTaskController() : super(_mockTasks);

  static final List<TaskModel> _mockTasks = [
    TaskModel(
      id: '1',
      title: 'Update Q3 Report',
      description:
          'Finalize the financial projections for the upcoming quarterly review.',
      deadline: DateTime.now().add(const Duration(days: 2)),
      status: TaskStatus.todo,
    ),
    TaskModel(
      id: '2',
      title: 'Fix Login Bug',
      description:
          'Investigate and resolve the intermittent timeout issue on the login screen.',
      deadline: DateTime.now().subtract(const Duration(hours: 5)),
      status: TaskStatus.inProgress,
    ),
    TaskModel(
      id: '3',
      title: 'Client Presentation',
      description:
          'Prepare the deck for the new project proposal for Acme Corp.',
      deadline: DateTime.now().add(const Duration(days: 5)),
      status: TaskStatus.todo,
    ),
    TaskModel(
      id: '4',
      title: 'Code Review',
      description:
          'Review the recent PRs for the authentication module refactoring.',
      deadline: DateTime.now().add(const Duration(hours: 12)),
      status: TaskStatus.completed,
    ),
    TaskModel(
      id: '5',
      title: 'Inventory Audit',
      description: 'Perform a full audit of the warehouse stock levels.',
      deadline: DateTime.now().subtract(const Duration(days: 1)),
      status: TaskStatus.todo,
    ),
    TaskModel(
      id: '6',
      title: 'Team Sync',
      description: 'Weekly sync to discuss blockers and project milestones.',
      deadline: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.inProgress,
    ),
  ];

  /// Updates the status of a specific task.
  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    state = [
      for (final task in state)
        if (task.id == taskId) task.copyWith(status: newStatus) else task,
    ];
  }
}

/// Provider for EmployeeTaskController.
final employeeTaskControllerProvider =
    StateNotifierProvider<EmployeeTaskController, List<TaskModel>>((ref) {
      return EmployeeTaskController();
    });

/// Provider for filtered tasks based on the current filter.
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(employeeTaskControllerProvider);
  final filter = ref.watch(taskFilterProvider);

  if (filter == null) return tasks;
  return tasks.where((task) => task.status == filter).toList();
});
