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

    final totalEmployeesFuture = _db
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .count()
        .get();

    final attendanceTodayFuture = _db
        .collectionGroup('records')
        .where('date', isEqualTo: dateKey)
        .get();

    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final onLeaveTodayFuture = _db
        .collection('leaves')
        .where('status', isEqualTo: 'approved')
        .where('fromDate', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .where('toDate', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .count()
        .get();

    final totalEmployeesSnapshot = await totalEmployeesFuture;
    final attendanceTodaySnapshot = await attendanceTodayFuture;
    final onLeaveTodaySnapshot = await onLeaveTodayFuture;

    var presentToday = 0;
    var lateToday = 0;

    for (final doc in attendanceTodaySnapshot.docs) {
      final status = (doc.data()['status'] as String?)?.toLowerCase() ?? '';
      if (status == 'present' || status == 'late' || status == 'done') {
        presentToday += 1;
      }
      if (status == 'late') {
        lateToday += 1;
      }
    }

    return AdminDashboardMetrics(
      totalEmployees: totalEmployeesSnapshot.count ?? 0,
      presentToday: presentToday,
      onLeaveToday: onLeaveTodaySnapshot.count ?? 0,
      lateToday: lateToday,
    );
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
