import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _months(String uid) {
    return _db.collection('payroll').doc(uid).collection('months');
  }

  static String monthDocId(DateTime date) {
    final month = _monthNames[date.month - 1].toLowerCase();
    return '$month-${date.year}';
  }

  static Future<Map<String, dynamic>?> getPayrollForMonth(
    String uid,
    DateTime month,
  ) async {
    final doc = await _months(uid).doc(monthDocId(month)).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  static Future<Map<String, dynamic>?> getCurrentMonthPayroll(String uid) {
    return getPayrollForMonth(uid, DateTime.now());
  }

  static Stream<List<Map<String, dynamic>>> streamPreviousMonths(
    String uid, {
    int limit = 6,
  }) {
    return _months(uid)
        .orderBy('creditedOn', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        });
  }

  static const _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
