import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for Attendance.
class AttendanceState {
  final bool isCheckedIn;
  final Duration hoursWorked;

  AttendanceState({
    required this.isCheckedIn,
    this.hoursWorked = Duration.zero,
  });

  AttendanceState copyWith({bool? isCheckedIn, Duration? hoursWorked}) {
    return AttendanceState(
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      hoursWorked: hoursWorked ?? this.hoursWorked,
    );
  }
}

/// Controller to handle Attendance logic.
class AttendanceController extends StateNotifier<AttendanceState> {
  AttendanceController() : super(AttendanceState(isCheckedIn: false));

  void togglePunch() {
    state = state.copyWith(isCheckedIn: !state.isCheckedIn);
  }
}

/// Provider for AttendanceController.
final attendanceProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>((ref) {
      return AttendanceController();
    });
