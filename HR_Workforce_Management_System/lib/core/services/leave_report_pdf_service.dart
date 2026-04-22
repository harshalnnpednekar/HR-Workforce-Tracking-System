import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'leave_service.dart';
import 'pdf_open_service.dart';

class LeaveReportPdfService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> generateAndShareLeaveSummary({
    required String uid,
  }) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final user = userDoc.data() ?? const <String, dynamic>{};

    final employeeName =
        ((user['name'] as String?) ?? 'Employee').trim().isEmpty
        ? 'Employee'
        : ((user['name'] as String?) ?? 'Employee').trim();
    final employeeId = (user['employeeId'] as String?) ?? '';
    final designation = (user['designation'] as String?) ?? '';
    final department = (user['department'] as String?) ?? '';

    final balances = await LeaveService.getUserLeaveBalances(uid);
    const casualEntitlement = 12;
    const sickEntitlement = 10;
    const earnedEntitlement = 20;

    final casualRemaining = balances['casual'] ?? casualEntitlement;
    final sickRemaining = balances['sick'] ?? sickEntitlement;
    final earnedRemaining = balances['earned'] ?? earnedEntitlement;

    final casualUsed = casualEntitlement - casualRemaining;
    final sickUsed = sickEntitlement - sickRemaining;
    final earnedUsed = earnedEntitlement - earnedRemaining;

    final leavesSnap = await _db.collection('leaves').get();
    final history = leavesSnap.docs.map((d) => {'id': d.id, ...d.data()}).where(
      (row) {
        final rowUid = (row['uid'] as String?)?.trim();
        final rowUserId = (row['userId'] as String?)?.trim();
        return rowUid == uid || rowUserId == uid;
      },
    ).toList();

    history.sort((a, b) {
      final ad =
          _asDate(a['appliedOn']) ?? _asDate(a['fromDate']) ?? DateTime(2000);
      final bd =
          _asDate(b['appliedOn']) ?? _asDate(b['fromDate']) ?? DateTime(2000);
      return bd.compareTo(ad);
    });

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 24),
        build: (context) => [
          _buildHeader(
            employeeName: employeeName,
            employeeId: employeeId,
            designation: designation,
            department: department,
          ),
          pw.SizedBox(height: 14),
          _buildLeaveOverview(
            casualEntitlement: casualEntitlement,
            casualUsed: casualUsed,
            casualRemaining: casualRemaining,
            sickEntitlement: sickEntitlement,
            sickUsed: sickUsed,
            sickRemaining: sickRemaining,
            earnedEntitlement: earnedEntitlement,
            earnedUsed: earnedUsed,
            earnedRemaining: earnedRemaining,
          ),
          pw.SizedBox(height: 18),
          _buildHistory(history),
          pw.SizedBox(height: 26),
          _buildFooter(),
        ],
      ),
    );

    final bytes = await doc.save();

    await PdfOpenService.openPdfBytes(
      bytes,
      fileName: 'Leave_Summary_${employeeName}_${DateTime.now().year}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required String employeeName,
    required String employeeId,
    required String designation,
    required String department,
  }) {
    final now = DateTime.now();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 24,
                  height: 24,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF56D2A),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Text(
                    'E',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'EQUITEC',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  employeeName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(designation, style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                  'Employee ID: $employeeId',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  'Department: $department',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'LEAVE SUMMARY REPORT',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF1D2939),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on: ${_fmtDate(now)}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.5, color: PdfColor.fromInt(0xFFF56D2A)),
      ],
    );
  }

  static pw.Widget _buildLeaveOverview({
    required int casualEntitlement,
    required int casualUsed,
    required int casualRemaining,
    required int sickEntitlement,
    required int sickUsed,
    required int sickRemaining,
    required int earnedEntitlement,
    required int earnedUsed,
    required int earnedRemaining,
  }) {
    final totalRemaining = casualRemaining + sickRemaining + earnedRemaining;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Leave Balance Overview'),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _summaryTile(
              'CASUAL',
              '$casualRemaining',
              PdfColor.fromInt(0xFFF8FAFC),
              PdfColor.fromInt(0xFF1D2939),
              sub: 'of $casualEntitlement',
            ),
            pw.SizedBox(width: 8),
            _summaryTile(
              'SICK',
              '$sickRemaining',
              PdfColor.fromInt(0xFFFFF1E5),
              PdfColor.fromInt(0xFFED6A0C),
              sub: 'of $sickEntitlement',
            ),
            pw.SizedBox(width: 8),
            _summaryTile(
              'EARNED',
              '$earnedRemaining',
              PdfColor.fromInt(0xFFEAF1FF),
              PdfColor.fromInt(0xFF2D5BDB),
              sub: 'of $earnedEntitlement',
            ),
            pw.SizedBox(width: 8),
            _summaryTile(
              'TOTAL BAL',
              '$totalRemaining',
              PdfColor.fromInt(0xFFE8F5ED),
              PdfColor.fromInt(0xFF137A3B),
              sub: 'Rem. days',
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryTile(
    String label,
    String value,
    PdfColor background,
    PdfColor valueColor, {
    String? sub,
  }) {
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: background,
          border: pw.Border.all(
            color: PdfColor.fromInt(0xFFD7DCE4),
            width: 0.5,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: pw.Column(
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7,
                color: PdfColor.fromInt(0xFF667085),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                color: valueColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (sub != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                sub,
                style: const pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHistory(List<Map<String, dynamic>> history) {
    final rows = history.take(8).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Detailed Leave History'),
        pw.SizedBox(height: 10),
        if (rows.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFE1E6ED),
                width: 0.8,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'No leave records available.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromInt(0xFFE1E6ED),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.1),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(0.8),
              3: const pw.FlexColumnWidth(1.9),
              4: const pw.FlexColumnWidth(1.1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF3F5F8),
                ),
                children: [
                  _th('TYPE'),
                  _th('DATE RANGE'),
                  _th('DAYS'),
                  _th('REASON'),
                  _th('STATUS'),
                ],
              ),
              ...rows.map((row) {
                final type =
                    ((row['leaveType'] ?? row['leaveTypeName']) as String? ??
                            '--')
                        .trim();
                final from = _asDate(row['fromDate']);
                final to = _asDate(row['toDate']);
                final range = _dateRange(from, to);
                final days = ((row['totalDays'] as num?)?.toDouble() ?? 0)
                    .toStringAsFixed(1);
                final reason = ((row['reason'] as String?) ?? '--').trim();
                final status = ((row['status'] as String?) ?? 'pending')
                    .toUpperCase();

                return pw.TableRow(
                  children: [
                    _td(type),
                    _td(range),
                    _td(days),
                    _td(reason.isEmpty ? '--' : reason, italic: true),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 7,
                      ),
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: _statusBg(status),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            status,
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: _statusFg(status),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 220,
              height: 1,
              color: PdfColor.fromInt(0xFFD0D5DD),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Employee Signature',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 220,
              height: 1,
              color: PdfColor.fromInt(0xFFD0D5DD),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Manager/HR Approval',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 16, color: PdfColor.fromInt(0xFFF56D2A)),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF344054),
          ),
        ),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF475467),
        ),
      ),
    );
  }

  static pw.Widget _td(String text, {bool bold = false, bool italic = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          color: PdfColor.fromInt(0xFF1D2939),
        ),
      ),
    );
  }

  static DateTime? _asDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static String _dateRange(DateTime? from, DateTime? to) {
    if (from == null && to == null) return '--';
    if (from != null && to != null) {
      final a = _fmtDateShort(from);
      final b = _fmtDateShort(to);
      if (a == b) return a;
      return '$a - $b';
    }
    if (from != null) return _fmtDateShort(from);
    return _fmtDateShort(to!);
  }

  static String _fmtDateShort(DateTime dt) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  static String _fmtDate(DateTime dt) => _fmtDateShort(dt);

  static PdfColor _statusBg(String status) {
    switch (status) {
      case 'APPROVED':
        return PdfColor.fromInt(0xFFE7F5EB);
      case 'REJECTED':
        return PdfColor.fromInt(0xFFFFEAEC);
      case 'PENDING':
      default:
        return PdfColor.fromInt(0xFFFFF2E5);
    }
  }

  static PdfColor _statusFg(String status) {
    switch (status) {
      case 'APPROVED':
        return PdfColor.fromInt(0xFF1F8D4E);
      case 'REJECTED':
        return PdfColor.fromInt(0xFFC62828);
      case 'PENDING':
      default:
        return PdfColor.fromInt(0xFFB86D00);
    }
  }
}
