import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/task_controller.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_row.dart';

/// The view that displays the list of tasks for an employee.
class MyTasksView extends ConsumerWidget {
  const MyTasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(filteredTasksProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        children: [
          const TaskFilterRow(),
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(key: ValueKey(task.id), task: task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No tasks in this category.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Great job!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
