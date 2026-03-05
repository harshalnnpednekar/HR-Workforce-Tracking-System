import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: `attendance`
///
/// Document fields:
///   userId, date (YYYY-MM-DD), punchIn (Timestamp), punchOut (Timestamp?),
///   totalHours (double), isLate (bool), lateMinutes (int),
///   isHalfDay (bool), status ('present'|'absent'|'half-day')
class AttendanceService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'attendance';

  /// Punch-in for today. Returns the new document ID.
  static Future<String> punchIn(String userId) async {
    final today = _today();
    // Prevent duplicate punch-in
    final existing = await _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Already punched in today.');
    }

    final ref = await _db.collection(_col).add({
      'userId': userId,
      'date': today,
      'punchIn': FieldValue.serverTimestamp(),
      'punchOut': null,
      'totalHours': 0.0,
      'isLate': false,
      'lateMinutes': 0,
      'isHalfDay': false,
      'status': 'present',
    });
    return ref.id;
  }

  /// Punch-out for today, calculates total hours and applies late/half-day rules.
  static Future<void> punchOut(String userId) async {
    final today = _today();
    final snap = await _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('No punch-in found for today.');

    final doc = snap.docs.first;
    final punchIn = (doc['punchIn'] as Timestamp).toDate();
    final punchOut = DateTime.now();
    final totalHours = punchOut.difference(punchIn).inMinutes / 60.0;

    // Fetch HR rules for half-day threshold
    final rulesSnap = await _db
        .collection('hrRules')
        .doc('halfday_threshold_hours')
        .get();
    final halfDayThreshold =
        double.tryParse(rulesSnap.data()?['value'] ?? '4') ?? 4.0;

    final isHalfDay = totalHours < halfDayThreshold;
    final status = isHalfDay ? 'half-day' : 'present';

    await doc.reference.update({
      'punchOut': FieldValue.serverTimestamp(),
      'totalHours': double.parse(totalHours.toStringAsFixed(2)),
      'isHalfDay': isHalfDay,
      'status': status,
    });
  }

  /// Returns today's attendance record for [userId], or null if not punched in.
  static Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    final snap = await _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: _today())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  /// Returns attendance records for [userId] in a given [month] (YYYY-MM).
  static Future<List<Map<String, dynamic>>> getMonthlyAttendance(
    String userId,
    String month,
  ) async {
    final snap = await _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: '$month-01')
        .where('date', isLessThanOrEqualTo: '$month-31')
        .orderBy('date')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Admin: returns all attendance for a given date.
  static Future<List<Map<String, dynamic>>> getAttendanceByDate(
    String date,
  ) async {
    final snap = await _db
        .collection(_col)
        .where('date', isEqualTo: date)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
