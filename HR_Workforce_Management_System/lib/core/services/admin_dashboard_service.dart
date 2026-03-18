import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalEmployees,
    required this.presentToday,
    required this.onLeaveToday,
    required this.lateToday,
  });

  final int totalEmployees;
  final int presentToday;
  final int onLeaveToday;
  final int lateToday;
}

class AdminDashboardService {
  static final _db = FirebaseFirestore.instance;

  static Future<AdminDashboardMetrics> getDashboardMetrics() async {
    final today = DateTime.now();
    final dateKey = _dateKey(today);
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    var totalEmployees = 0;
    var presentToday = 0;
    var lateToday = 0;
    var onLeaveToday = 0;

    try {
      final totalEmployeesSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
      totalEmployees = totalEmployeesSnapshot.docs.length;
    } catch (_) {
      // Keep dashboard usable even if this query fails.
    }

    try {
      final userSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();

      final futures = userSnap.docs.map((userDoc) {
        return _db
            .collection('attendance')
            .doc(userDoc.id)
            .collection('records')
            .doc(dateKey)
            .get();
      });

      final dailyRecords = await Future.wait(futures);
      for (final rec in dailyRecords) {
        if (!rec.exists) continue;
        final status = (rec.data()?['status'] as String?)?.toLowerCase() ?? '';
        if (status == 'present' || status == 'late' || status == 'done') {
          presentToday += 1;
        }
        if (status == 'late') {
          lateToday += 1;
        }
      }
    } catch (_) {
      // Keep dashboard usable even if this query fails.
    }

    try {
      // Avoid index-sensitive range query combinations and filter overlap locally.
      final approvedLeavesSnapshot = await _db
          .collection('leaves')
          .where('status', isEqualTo: 'approved')
          .get();

      for (final doc in approvedLeavesSnapshot.docs) {
        final data = doc.data();
        final fromDate = _asDateTime(data['fromDate']);
        final toDate = _asDateTime(data['toDate']);
        if (fromDate == null || toDate == null) continue;
        if (fromDate.isBefore(dayEnd) && toDate.isAfter(dayStart)) {
          onLeaveToday += 1;
        }
      }
    } catch (_) {
      // Keep dashboard usable even if this query fails.
    }

    return AdminDashboardMetrics(
      totalEmployees: totalEmployees,
      presentToday: presentToday,
      onLeaveToday: onLeaveToday,
      lateToday: lateToday,
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Stream<int> streamPendingLeaveCount() {
    return _db
        .collection('leaves')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Stream<List<Map<String, dynamic>>> streamRecentActivity({
    int limit = 10,
  }) {
    return _db
        .collection('activityLog')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
