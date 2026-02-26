import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/task_controller.dart';
import '../../domain/models/task_model.dart';

/// A row of modern filter chips to filter tasks by status.
class TaskFilterRow extends ConsumerWidget {
  const TaskFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(taskFilterProvider);

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ModernChip(
            label: 'All',
            isSelected: selectedFilter == null,
            onTap: () => ref.read(taskFilterProvider.notifier).state = null,
          ),
          _ModernChip(
            label: 'To Do',
            isSelected: selectedFilter == TaskStatus.todo,
            onTap: () =>
                ref.read(taskFilterProvider.notifier).state = TaskStatus.todo,
          ),
          _ModernChip(
            label: 'In Progress',
            isSelected: selectedFilter == TaskStatus.inProgress,
            onTap: () => ref.read(taskFilterProvider.notifier).state =
                TaskStatus.inProgress,
          ),
          _ModernChip(
            label: 'Completed',
            isSelected: selectedFilter == TaskStatus.completed,
            onTap: () => ref.read(taskFilterProvider.notifier).state =
                TaskStatus.completed,
          ),
        ],
      ),
    );
  }
}

class _ModernChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8, top: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: isSelected
                ? LinearGradient(colors: [primary, primary.withOpacity(0.8)])
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.6),
            border: Border.all(
              color: isSelected ? primary : Colors.white,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
