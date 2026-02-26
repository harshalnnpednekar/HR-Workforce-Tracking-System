import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/task_model.dart';
import '../controllers/task_controller.dart';

/// A card representing a single task.
class TaskCard extends ConsumerWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue =
        task.deadline.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;
    final dateColor = isOverdue ? Colors.redAccent : Colors.grey.shade600;
    final statusColor = _getStatusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status bar glow
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          _StatusChip(
                            status: task.status,
                            label: _statusLabel(task.status),
                            color: statusColor,
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                ref
                                    .read(
                                      employeeTaskControllerProvider.notifier,
                                    )
                                    .updateTaskStatus(task.id, newStatus);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: dateColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: dateColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy').format(task.deadline),
                            style: GoogleFonts.outfit(
                              color: dateColor,
                              fontSize: 13,
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '• OVERDUE',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final TaskStatus status;
  final String label;
  final Color color;
  final ValueChanged<TaskStatus?> onChanged;

  const _StatusChip({
    required this.status,
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskStatus>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => TaskStatus.values.map((s) {
        return PopupMenuItem(value: s, child: Text(s.name.toUpperCase()));
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}
