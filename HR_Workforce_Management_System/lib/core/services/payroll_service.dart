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
        .snapshots()
        .map(
          (snap) => snap.docs
              .where(
                (d) =>
                    ((d.data()['monthYear'] as String?) ?? '').toLowerCase() ==
                    monthYear.toLowerCase(),
              )
              .map(
                (d) => {
                  'id': d.id,
                  'uid': d.reference.parent.parent!.id,
                  ...d.data(),
                },
              )
              .toList(),
        );
  }

  /// Streams all payroll records across all months and employees.
  static Stream<List<Map<String, dynamic>>> streamAllPayrollRecords() {
    return _db.collectionGroup('months').snapshots().map((snap) {
      final rows = snap.docs
          .map(
            (d) => {
              'id': d.id,
              'uid': d.reference.parent.parent?.id ?? '',
              ...d.data(),
            },
          )
          .toList(growable: false);

      rows.sort((a, b) {
        final aMonth = ((a['monthYear'] as String?) ?? '').toLowerCase();
        final bMonth = ((b['monthYear'] as String?) ?? '').toLowerCase();
        final aDate = monthDocIdToDate(aMonth);
        final bDate = monthDocIdToDate(bMonth);
        if (aDate != null && bDate != null) {
          return bDate.compareTo(aDate);
        }
        return bMonth.compareTo(aMonth);
      });

      return rows;
    });
  }

  /// Streams the total net salary and pending count for a given [monthYear].
  static Stream<PayrollSummary> streamPayrollSummary(String monthYear) {
    return streamAllPayrollForMonth(monthYear).asyncMap((docs) async {
      double totalNet = 0;
      int pendingCount = 0;
      for (final doc in docs) {
        totalNet += (doc['netSalary'] as num?)?.toDouble() ?? 0;
        if ((doc['status'] as String?) == 'pending') pendingCount++;
      }

      final previousMonthDoc = previousMonthDocId(monthYear);
      final prevSnap = await _db.collectionGroup('months').get();
      double previousTotal = 0;
      for (final doc in prevSnap.docs) {
        final docMonth = ((doc.data()['monthYear'] as String?) ?? '')
            .toLowerCase();
        if (docMonth != previousMonthDoc.toLowerCase()) continue;
        previousTotal += (doc.data()['netSalary'] as num?)?.toDouble() ?? 0;
      }

      double percentChange = 0;
      if (previousTotal > 0) {
        percentChange = ((totalNet - previousTotal) / previousTotal) * 100;
      }

      return PayrollSummary(
        totalNetSalary: totalNet,
        pendingCount: pendingCount,
        previousMonthTotal: previousTotal,
        percentChangeFromPreviousMonth: percentChange,
      );
    });
  }

  // ─── Admin-facing: mutations ──────────────────────────────────────────────

  /// Creates or updates a payroll record for [uid] for [monthYear].
  static Future<void> upsertPayroll({
    required String uid,
    required String monthYear,
    required Map<String, dynamic> data,
  }) async {
    final existing = await _months(uid).doc(monthYear).get();
    final status = (existing.data()?['status'] as String?)?.toLowerCase() ?? '';
    if (status == 'paid') {
      // Paid payroll is immutable in app logic.
      return;
    }

    await _months(uid).doc(monthYear).set({
      ...data,
      'monthYear': monthYear,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Ensures month payroll exists for all active employees.
  /// Returns number of newly created payroll documents.
  static Future<int> ensurePayrollForMonth({
    required String monthYear,
    required String adminUid,
  }) async {
    final monthDate = monthDocIdToDate(monthYear);
    if (monthDate == null) return 0;

    QuerySnapshot<Map<String, dynamic>> employees;
    try {
      employees = await _db
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .where('isActive', isEqualTo: true)
          .get();
    } catch (_) {
      employees = await _db
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .where('status', isEqualTo: 'active')
          .get();
    }

    if (employees.docs.isEmpty) return 0;

    final existingSnap = await _db.collectionGroup('months').get();
    final existingByUid = <String>{
      for (final doc in existingSnap.docs)
        if ((((doc.data())['monthYear'] as String?) ?? '').toLowerCase() ==
            monthYear.toLowerCase())
          if (doc.reference.parent.parent?.id != null)
            doc.reference.parent.parent!.id,
    };

    final toCreate = employees.docs
        .where((e) => !existingByUid.contains(e.id))
        .toList(growable: false);
    if (toCreate.isEmpty) return 0;

    int created = 0;
    WriteBatch batch = _db.batch();
    var opCount = 0;

    for (final employee in toCreate) {
      final uid = employee.id;
      final calc = await calculateSalary(
        uid: uid,
        month: monthDate.month,
        year: monthDate.year,
      );

      final ref = _months(uid).doc(monthYear);
      batch.set(ref, {
        ...calc,
        'status': 'pending',
        'processedBy': '',
        'creditedOn': null,
        'processedAt': null,
        'pdfSlipUrl': '',
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      opCount++;
      created++;

      if (opCount >= 400) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }

    if (created > 0) {
      await _db.collection('activityLog').add({
        'type': 'payroll',
        'message': 'Payroll initialized for $monthYear · $created employees',
        'processedBy': adminUid,
        'monthYear': monthYear,
        'count': created,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    return created;
  }

  /// Calculates one employee salary for a selected month/year.
  static Future<Map<String, dynamic>> calculateSalary({
    required String uid,
    required int month,
    required int year,
  }) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final user = userDoc.data() ?? <String, dynamic>{};

    final baseSalary =
        (user['baseSalary'] as num?)?.toDouble() ??
        (user['basicSalary'] as num?)?.toDouble() ??
        0;

    final rulesDoc = await _db.collection('hr_rules').doc('equitec').get();
    final rules = rulesDoc.data() ?? const <String, dynamic>{};

    final hraPercent = (rules['hraPercentage'] as num?)?.toDouble() ?? 40;
    final hra = double.parse(
      (baseSalary * (hraPercent / 100)).toStringAsFixed(2),
    );
    final conveyance =
        (rules['conveyanceFixed'] as num?)?.toDouble() ??
        (user['conveyance'] as num?)?.toDouble() ??
        9000;
    final grossSalary = baseSalary + hra + conveyance;

    final lateDeductionPerMark =
        (rules['lateDeductionPerMark'] as num?)?.toDouble() ?? 500;
    final maxAllowedLateMarks =
        (rules['maxLateMarksAllowed'] as num?)?.toInt() ?? 3;
    final pfPercentage =
        ((rules['pfPercentage'] as num?)?.toDouble() ?? 12) / 100;
    final professionalTax =
        (rules['professionalTax'] as num?)?.toDouble() ?? 200;
    final absentDeductionPerDay =
        (rules['absentDeductionPerDay'] as num?)?.toDouble() ?? 2000;

    final prefix = '${year.toString()}-${month.toString().padLeft(2, '0')}';
    final monthStart = '$prefix-01';
    final monthEnd = '$prefix-31';

    final lateRecords = await _db
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .where('status', isEqualTo: 'late')
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThanOrEqualTo: monthEnd)
        .get();

    final absentRecords = await _db
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .where('status', isEqualTo: 'absent')
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThanOrEqualTo: monthEnd)
        .get();

    final presentRecords = await _db
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .where('status', isEqualTo: 'present')
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThanOrEqualTo: monthEnd)
        .get();

    final leaveRecords = await _db
        .collection('attendance')
        .doc(uid)
        .collection('records')
        .where('status', isEqualTo: 'leave')
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThanOrEqualTo: monthEnd)
        .get();

    final lateMarks = lateRecords.docs.length;
    final deductibleLateMarks = (lateMarks - maxAllowedLateMarks).clamp(0, 999);
    final lateDeduction = deductibleLateMarks * lateDeductionPerMark;

    final absentDays = absentRecords.docs.length;
    final presentDays = presentRecords.docs.length;
    final leaveDays = leaveRecords.docs.length;
    final totalDays = presentDays + lateMarks + absentDays + leaveDays;

    final leaveDeduction = absentDays * absentDeductionPerDay;

    final pf = baseSalary * pfPercentage;
    final totalDeductions =
        lateDeduction + leaveDeduction + pf + professionalTax;
    final netSalary = grossSalary - totalDeductions;

    final monthDate = DateTime(year, month, 1);
    final monthYear = monthDocId(monthDate);

    return {
      'employeeId': (user['employeeId'] as String?) ?? '',
      'employeeName': (user['name'] as String?) ?? 'Employee',
      'designation': (user['designation'] as String?) ?? 'Employee',
      'department': (user['department'] as String?) ?? '',
      'photoUrl': (user['photoUrl'] as String?) ?? '',
      'bankLast4': (user['bankLast4'] as String?) ?? '----',
      'joiningDate': (user['joiningDate'] as String?) ?? '',
      'month': _monthNames[month - 1],
      'year': year,
      'monthYear': monthYear,
      'payPeriod': '01 - 30',
      // Attendance Summary
      'totalDays': totalDays,
      'presentDays': presentDays,
      'lateDays': lateMarks,
      'absentDays': absentDays,
      'leaveDays': leaveDays,
      // Earnings
      'basicSalary': baseSalary,
      'baseSalary': baseSalary,
      'hra': hra,
      'conveyance': conveyance,
      'grossSalary': grossSalary,
      // Deductions
      'lateDeduction': lateDeduction,
      'leaveDeduction': leaveDeduction,
      'lateMarks': lateMarks,
      'deductibleLateMarks': deductibleLateMarks,
      'pf': pf,
      'professionalTax': professionalTax,
      'totalDeductions': totalDeductions,
      'netSalary': netSalary,
      'status': 'pending',
      'processedBy': '',
      'creditedOn': null,
      'pdfSlipUrl': '',
    };
  }

  /// Marks a single employee's payroll as paid.
  static Future<void> markAsPaid({
    required String uid,
    required String monthYear,
    required String adminUid,
  }) async {
    final ref = _months(uid).doc(monthYear);
    final snap = await ref.get();
    final currentStatus = (snap.data()?['status'] as String?)?.toLowerCase();
    if (currentStatus == 'paid') return;

    await ref.update({
      'status': 'paid',
      'processedBy': adminUid,
      'processedAt': FieldValue.serverTimestamp(),
      'creditedOn': FieldValue.serverTimestamp(),
    });

    // Notify the employee
    final data = (await ref.get()).data();
    if (data != null) {
      final net = (data['netSalary'] as num?)?.toDouble() ?? 0;
      final label = monthDocIdToLabel(monthYear);
      try {
        await NotificationService.send(
          userId: uid,
          title: 'Salary Credited',
          message: 'Your $label salary has been credited',
          subtitle: 'Rs. ${_fmt(net)}',
          type: NotificationService.typePayroll,
          relatedId: monthYear,
        );
      } catch (_) {
        // Mark-paid succeeds even if notification write fails.
      }

      await _db.collection('activityLog').add({
        'type': 'payroll',
        'message':
            'Payroll $monthYear processed for ${data['employeeName'] ?? 'Employee'}',
        'employeeName': data['employeeName'] ?? 'Employee',
        'uid': uid,
        'processedBy': adminUid,
        'monthYear': monthYear,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Edits a pending payroll document and recalculates salary totals.
  /// Throws when the payroll is already paid or missing.
  static Future<void> editPendingPayroll({
    required String uid,
    required String monthYear,
    required String adminUid,
    required double basicSalary,
    required double hra,
    required double conveyance,
    required double lateDeduction,
    required double leaveDeduction,
    required double pf,
    required double professionalTax,
    required bool isHraAuto,
  }) async {
    final ref = _months(uid).doc(monthYear);
    final snap = await ref.get();
    if (!snap.exists) {
      throw Exception('Payroll record not found.');
    }

    final existing = snap.data() ?? const <String, dynamic>{};
    final status = (existing['status'] as String?)?.toLowerCase() ?? '';
    if (status == 'paid') {
      throw Exception('Paid payroll cannot be edited.');
    }

    double n2(double value) => double.parse(value.toStringAsFixed(2));

    final safeBasic = n2(basicSalary < 0 ? 0 : basicSalary);
    final safeHra = n2(hra < 0 ? 0 : hra);
    final safeConveyance = n2(conveyance < 0 ? 0 : conveyance);
    final safeLateDeduction = n2(lateDeduction < 0 ? 0 : lateDeduction);
    final safeLeaveDeduction = n2(leaveDeduction < 0 ? 0 : leaveDeduction);
    final safePf = n2(pf < 0 ? 0 : pf);
    final safeProfessionalTax = n2(professionalTax < 0 ? 0 : professionalTax);

    final grossSalary = n2(safeBasic + safeHra + safeConveyance);
    final totalDeductions = n2(
      safeLateDeduction + safeLeaveDeduction + safePf + safeProfessionalTax,
    );
    final netSalary = n2(grossSalary - totalDeductions);

    final previousNet =
        (existing['netSalary'] as num?)?.toDouble() ?? netSalary;

    await ref.update({
      'basicSalary': safeBasic,
      'baseSalary': safeBasic,
      'hra': safeHra,
      'conveyance': safeConveyance,
      'grossSalary': grossSalary,
      'lateDeduction': safeLateDeduction,
      'leaveDeduction': safeLeaveDeduction,
      'pf': safePf,
      'professionalTax': safeProfessionalTax,
      'totalDeductions': totalDeductions,
      'netSalary': netSalary,
      'status': 'pending',
      'isEdited': true,
      'editedBy': adminUid,
      'editedAt': FieldValue.serverTimestamp(),
      'originalNetSalary': previousNet,
      'updatedAt': FieldValue.serverTimestamp(),
      'isHraAuto': isHraAuto,
    });

    await _db.collection('activityLog').add({
      'type': 'payroll-edit',
      'message':
          'Payroll $monthYear updated for ${existing['employeeName'] ?? 'Employee'}',
      'employeeName': existing['employeeName'] ?? 'Employee',
      'uid': uid,
      'processedBy': adminUid,
      'monthYear': monthYear,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Processes all pending payroll in bulk using a Firestore WriteBatch.
  /// Returns the number of records updated.
  static Future<int> processBulkPayments({
    required String monthYear,
    required String adminUid,
  }) async {
    // Fetch pending docs once (not via stream) for batch write
    final allMonths = await _db.collectionGroup('months').get();
    final pendingDocs = allMonths.docs
        .where((doc) {
          final data = doc.data();
          final docMonth = ((data['monthYear'] as String?) ?? '').toLowerCase();
          final status = ((data['status'] as String?) ?? '').toLowerCase();
          return docMonth == monthYear.toLowerCase() && status == 'pending';
        })
        .toList(growable: false);

    if (pendingDocs.isEmpty) return 0;

    final batch = _db.batch();
    final now = Timestamp.now();

    for (final doc in pendingDocs) {
      batch.update(doc.reference, {
        'status': 'paid',
        'processedBy': adminUid,
        'processedAt': now,
        'creditedOn': now,
      });
    }

    await batch.commit();

    // Log activity
    await _db.collection('activityLog').add({
      'type': 'payroll',
      'message':
          'Bulk payroll processed for $monthYear · ${pendingDocs.length} employees paid',
      'processedBy': adminUid,
      'monthYear': monthYear,
      'count': pendingDocs.length,
      'timestamp': now,
    });

    // Notify each employee
    final label = monthDocIdToLabel(monthYear);
    final futures = pendingDocs.map((doc) async {
      final employeeUid = doc.reference.parent.parent?.id ?? '';
      if (employeeUid.isEmpty) return;
      final net = (doc.data()['netSalary'] as num?)?.toDouble() ?? 0;
      try {
        await NotificationService.send(
          userId: employeeUid,
          title: 'Salary Credited',
          message: 'Your $label salary has been credited',
          subtitle: 'Rs. ${_fmt(net)}',
          type: NotificationService.typePayroll,
          relatedId: monthYear,
        );
      } catch (_) {
        // Bulk payroll updates should not fail because one notification failed.
      }
    });

    await Future.wait(futures);

    return pendingDocs.length;
  }

  /// Sends payroll reminder to admin in last 3 days of month when pending exists.
  static Future<void> checkPayrollReminderForAdmin(String adminUid) async {
    if (adminUid.trim().isEmpty) return;

    final now = DateTime.now();
    if (now.day < 28) return;

    final monthYear = monthDocId(DateTime(now.year, now.month, 1));
    final allMonths = await _db.collectionGroup('months').get();
    final pendingDocs = allMonths.docs
        .where((doc) {
          final data = doc.data();
          final docMonth = ((data['monthYear'] as String?) ?? '').toLowerCase();
          final status = ((data['status'] as String?) ?? '').toLowerCase();
          return docMonth == monthYear.toLowerCase() && status == 'pending';
        })
        .toList(growable: false);

    if (pendingDocs.isEmpty) return;

    final reminderDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final existing = await _db
        .collection('notifications')
        .doc(adminUid)
        .collection('items')
        .where('type', isEqualTo: NotificationService.typePayrollReminder)
        .where('relatedId', isEqualTo: monthYear)
        .where('reminderDate', isEqualTo: reminderDate)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final monthLabel = monthDocIdToLabel(monthYear);
    await NotificationService.send(
      userId: adminUid,
      title: 'Payroll Reminder',
      message: '${pendingDocs.length} employees pending payroll',
      subtitle: monthLabel,
      type: NotificationService.typePayrollReminder,
      relatedId: monthYear,
      extra: {'reminderDate': reminderDate},
    );
  }

  // ─── Formatting helpers ───────────────────────────────────────────────────

  static String formatCurrency(num amount) => 'Rs. ${_fmt(amount.toDouble())}';

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
    return '${groups.join(',')},$last3';
  }

  // ─── Available months ─────────────────────────────────────────────────────

  /// Returns the last [count] month doc-IDs ending at (and including) today.
  static List<String> recentMonthDocIds({int count = 6}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return monthDocId(d);
    });
  }

  static String previousMonthDocId(String monthYear) {
    final dt = monthDocIdToDate(monthYear);
    if (dt == null) return monthYear;
    final prev = DateTime(dt.year, dt.month - 1, 1);
    return monthDocId(prev);
  }

  static DateTime? monthDocIdToDate(String docId) {
    final parts = docId.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[1]);
    final monthIdx = _monthNames.indexWhere(
      (m) => m.toLowerCase() == parts[0].toLowerCase(),
    );
    if (year == null || monthIdx < 0) return null;
    return DateTime(year, monthIdx + 1, 1);
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

// ─── Value objects ───────────────────────────────────────────────────────────

class PayrollSummary {
  const PayrollSummary({
    required this.totalNetSalary,
    required this.pendingCount,
    required this.previousMonthTotal,
    required this.percentChangeFromPreviousMonth,
  });

  final double totalNetSalary;
  final int pendingCount;
  final double previousMonthTotal;
  final double percentChangeFromPreviousMonth;
}
