import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

/// Firestore structure:
///   payroll/{uid}/months/{monthYear}
///   e.g. payroll/abc123/months/october-2023
class PayrollService {
  static final _db = FirebaseFirestore.instance;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _months(String uid) {
    return _db.collection('payroll').doc(uid).collection('months');
  }

  /// Converts a DateTime → "october-2023" style doc ID.
  static String monthDocId(DateTime date) {
    final month = _monthNames[date.month - 1].toLowerCase();
    return '$month-${date.year}';
  }

  /// Converts a "october-2023" doc ID → display label "October 2023".
  static String monthDocIdToLabel(String docId) {
    final parts = docId.split('-');
    if (parts.length != 2) return docId;
    final month = parts[0];
    final year = parts[1];
    return '${month[0].toUpperCase()}${month.substring(1)} $year';
  }

  // ─── Employee-facing ──────────────────────────────────────────────────────

  /// Fetches a single month's payroll document for one employee.
  static Future<Map<String, dynamic>?> getPayrollForMonth(
    String uid,
    DateTime month,
  ) async {
    final doc = await _months(uid).doc(monthDocId(month)).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Convenience: current month payroll.
  static Future<Map<String, dynamic>?> getCurrentMonthPayroll(String uid) {
    return getPayrollForMonth(uid, DateTime.now());
  }

  /// Streams the last [limit] months of payroll for one employee.
  static Stream<List<Map<String, dynamic>>> streamPreviousMonths(
    String uid, {
    int limit = 6,
  }) {
    return _months(uid)
        .orderBy('processedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        });
  }

  // ─── Admin-facing: queries ────────────────────────────────────────────────

  /// Streams ALL employee payroll records for [monthYear] (e.g. "october-2023").
  /// Uses a collectionGroup query so one query covers every uid.
  static Stream<List<Map<String, dynamic>>> streamAllPayrollForMonth(
    String monthYear,
  ) {
    return _db
        .collectionGroup('months')
        .where('monthYear', isEqualTo: monthYear)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {'id': d.id, 'uid': d.reference.parent.parent!.id, ...d.data()}).toList(),
        );
  }

  /// Streams the total net salary and pending count for a given [monthYear].
  static Stream<PayrollSummary> streamPayrollSummary(String monthYear) {
    return streamAllPayrollForMonth(monthYear).map((docs) {
      double totalNet = 0;
      int pendingCount = 0;
      for (final doc in docs) {
        totalNet += (doc['netSalary'] as num?)?.toDouble() ?? 0;
        if ((doc['status'] as String?) == 'pending') pendingCount++;
      }
      return PayrollSummary(totalNetSalary: totalNet, pendingCount: pendingCount);
    });
  }

  // ─── Admin-facing: mutations ──────────────────────────────────────────────

  /// Creates or updates a payroll record for [uid] for [monthYear].
  static Future<void> upsertPayroll({
    required String uid,
    required String monthYear,
    required Map<String, dynamic> data,
  }) async {
    await _months(uid).doc(monthYear).set({
      ...data,
      'monthYear': monthYear,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Marks a single employee's payroll as paid.
  static Future<void> markAsPaid({
    required String uid,
    required String monthYear,
    required String adminUid,
  }) async {
    final ref = _months(uid).doc(monthYear);
    await ref.update({
      'status': 'paid',
      'processedBy': adminUid,
      'processedAt': FieldValue.serverTimestamp(),
    });

    // Notify the employee
    final doc = await ref.get();
    final data = doc.data();
    if (data != null) {
      final net = (data['netSalary'] as num?)?.toDouble() ?? 0;
      final label = monthDocIdToLabel(monthYear);
      await NotificationService.send(
        userId: uid,
        title: 'Salary Credited for $label',
        message: '₹${_fmt(net)} has been processed.',
        type: 'payroll',
        relatedId: monthYear,
      );
    }
  }

  /// Processes all pending payroll in bulk using a Firestore WriteBatch.
  /// Returns the number of records updated.
  static Future<int> processBulkPayments({
    required String monthYear,
    required String adminUid,
  }) async {
    // Fetch pending docs once (not via stream) for batch write
    final snap = await _db
        .collectionGroup('months')
        .where('monthYear', isEqualTo: monthYear)
        .where('status', isEqualTo: 'pending')
        .get();

    if (snap.docs.isEmpty) return 0;

    final batch = _db.batch();
    final now = Timestamp.now();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': 'paid',
        'processedBy': adminUid,
        'processedAt': now,
      });
    }

    await batch.commit();

    // Log activity
    await _db.collection('activityLog').add({
      'type': 'payroll',
      'message': 'Bulk payroll processed for $monthYear · ${snap.docs.length} employees paid',
      'processedBy': adminUid,
      'monthYear': monthYear,
      'count': snap.docs.length,
      'timestamp': now,
    });

    // Notify each employee
    final label = monthDocIdToLabel(monthYear);
    final futures = snap.docs.map((doc) async {
      final employeeUid =
          doc.reference.parent.parent?.id ?? '';
      if (employeeUid.isEmpty) return;
      final net = (doc.data()['netSalary'] as num?)?.toDouble() ?? 0;
      await NotificationService.send(
        userId: employeeUid,
        title: 'Salary Credited for $label',
        message: '₹${_fmt(net)} has been processed.',
        type: 'payroll',
        relatedId: monthYear,
      );
    });

    await Future.wait(futures);

    return snap.docs.length;
  }

  // ─── Formatting helpers ───────────────────────────────────────────────────

  static String formatCurrency(num amount) => '₹${_fmt(amount.toDouble())}';

  static String _fmt(double amount) {
    // Simple Indian number formatting e.g. 1,23,456
    final s = amount.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final remaining = s.substring(0, s.length - 3);
    final groups = <String>[];
    String rem = remaining;
    while (rem.length > 2) {
      groups.insert(0, rem.substring(rem.length - 2));
      rem = rem.substring(0, rem.length - 2);
    }
    if (rem.isNotEmpty) groups.insert(0, rem);
    return '${groups.join(',')},${last3}';
  }

  // ─── Available months ─────────────────────────────────────────────────────

  /// Returns the last [count] month doc-IDs ending at (and including) today.
  static List<String> recentMonthDocIds({int count = 3}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return monthDocId(d);
    });
  }

  static const _monthNames = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}

// ─── Value objects ───────────────────────────────────────────────────────────

class PayrollSummary {
  const PayrollSummary({
    required this.totalNetSalary,
    required this.pendingCount,
  });

  final double totalNetSalary;
  final int pendingCount;
}
