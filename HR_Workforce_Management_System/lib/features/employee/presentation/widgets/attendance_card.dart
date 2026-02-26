import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/attendance_controller.dart';

/// A card that handles the attendance "Punch In/Out" engine.
class AttendanceCard extends ConsumerStatefulWidget {
  const AttendanceCard({super.key});

  @override
  ConsumerState<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends ConsumerState<AttendanceCard> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    _formatTime(_currentTime),
                    style: GoogleFonts.outfit(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: attendance.isCheckedIn
                                ? Colors.orange
                                : Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (attendance.isCheckedIn
                                            ? Colors.orange
                                            : Colors.greenAccent)
                                        .withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${attendance.isCheckedIn ? "Checked In" : "Checked Out"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        notifier.togglePunch();
                        final action = attendance.isCheckedIn
                            ? "Punched Out"
                            : "Punched In";
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(action),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        attendance.isCheckedIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        color: attendance.isCheckedIn
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        attendance.isCheckedIn ? 'Punch Out' : 'Punch In',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: attendance.isCheckedIn
                            ? Colors.redAccent.withOpacity(0.9)
                            : Colors.white,
                        foregroundColor: attendance.isCheckedIn
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
