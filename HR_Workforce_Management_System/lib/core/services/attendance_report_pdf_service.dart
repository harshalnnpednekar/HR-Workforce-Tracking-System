import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'attendance_service.dart';

class AttendanceReportPdfService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> generateAndShareMonthlyReport({
    required String uid,
    DateTime? month,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final monthKey =
        '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}';

    final userDoc = await _db.collection('users').doc(uid).get();
    final user = userDoc.data() ?? const <String, dynamic>{};

    final employeeName =
        ((user['name'] as String?) ?? 'Employee').trim().isEmpty
        ? 'Employee'
        : ((user['name'] as String?) ?? 'Employee').trim();
    final employeeId = (user['employeeId'] as String?) ?? '';

    final records = await AttendanceService.getMonthlyAttendance(uid, monthKey);

    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    int leaveCount = 0;

    for (final row in records) {
      final status = ((row['status'] as String?) ?? '').toLowerCase();
      if (status == 'present') presentCount++;
      if (status == 'late') lateCount++;
      if (status == 'absent') absentCount++;
      if (status == 'leave' || status == 'on_leave') leaveCount++;
    }

    final workingDays = presentCount + lateCount + absentCount + leaveCount;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 24),
        build: (context) => [
          _buildHeader(
            employeeName: employeeName,
            employeeId: employeeId,
            period: _monthLabel(targetMonth),
          ),
          pw.SizedBox(height: 14),
          _buildSummary(
            workingDays: workingDays,
            presentCount: presentCount,
            lateCount: lateCount,
            absentCount: absentCount,
            leaveCount: leaveCount,
          ),
          pw.SizedBox(height: 16),
          _buildDailyLogTable(records),
          pw.SizedBox(height: 36),
          _buildFooter(),
        ],
      ),
    );

    final bytes = await doc.save();
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/attendance_report_${monthKey}_$uid.pdf');
    await file.writeAsBytes(bytes, flush: true);

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'Attendance_Report_${employeeName}_${_monthFile(targetMonth)}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required String employeeName,
    required String employeeId,
    required String period,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EQUITEC',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFFF56D2A),
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'ATTENDANCE REPORT',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF475467),
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
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
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1D2939),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Employee ID: $employeeId',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Report Period: $period',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.5, color: PdfColor.fromInt(0xFFF56D2A)),
      ],
    );
  }

  static pw.Widget _buildSummary({
    required int workingDays,
    required int presentCount,
    required int lateCount,
    required int absentCount,
    required int leaveCount,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD7DCE4), width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          _summaryTile(
            'WORKING DAYS',
            '$workingDays',
            PdfColor.fromInt(0xFFF8FAFC),
            PdfColor.fromInt(0xFF1D2939),
          ),
          _summaryTile(
            'PRESENT',
            '$presentCount',
            PdfColor.fromInt(0xFFE8F5ED),
            PdfColor.fromInt(0xFF137A3B),
          ),
          _summaryTile(
            'LATE',
            '$lateCount',
            PdfColor.fromInt(0xFFFFF1E5),
            PdfColor.fromInt(0xFFED6A0C),
          ),
          _summaryTile(
            'ABSENT',
            '$absentCount',
            PdfColor.fromInt(0xFFFFECEC),
            PdfColor.fromInt(0xFFBE1E2D),
          ),
          _summaryTile(
            'LEAVES',
            '$leaveCount',
            PdfColor.fromInt(0xFFEAF1FF),
            PdfColor.fromInt(0xFF2D5BDB),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryTile(
    String label,
    String value,
    PdfColor background,
    PdfColor valueColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        color: background,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDailyLogTable(List<Map<String, dynamic>> records) {
    final sorted = [...records]
      ..sort((a, b) {
        final ad = (a['date'] as String?) ?? '';
        final bd = (b['date'] as String?) ?? '';
        return ad.compareTo(bd);
      });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 3,
              height: 16,
              color: PdfColor.fromInt(0xFFF56D2A),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'Daily Log Breakdown',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColor.fromInt(0xFFE1E6ED),
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F5F8)),
              children: [
                _th('DATE'),
                _th('DAY'),
                _th('CLOCK IN'),
                _th('CLOCK OUT'),
                _th('TOTAL HOURS'),
                _th('STATUS'),
              ],
            ),
            ...sorted.map((row) {
              final dateText = (row['date'] as String?) ?? '--';
              final dayText = _dayName(dateText);
              final inTime = _fmtTime(row['clockIn']);
              final outTime = _fmtTime(row['clockOut']);
              final hours = _fmtHours(
                (row['totalHours'] as num?)?.toDouble() ?? 0,
              );
              final status = ((row['status'] as String?) ?? '--').toUpperCase();
              final statusBg = _statusBg(status);
              final statusFg = _statusFg(status);

              return pw.TableRow(
                children: [
                  _td(_fmtDate(dateText)),
                  _td(dayText),
                  _td(inTime),
                  _td(outTime),
                  _td(hours, bold: true),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: statusBg,
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
                          status == 'LEAVE' ? 'ON LEAVE' : status,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: statusFg,
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
    final now = DateTime.now();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 180,
              height: 1,
              color: PdfColor.fromInt(0xFFBFC8D4),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'REPORTING MANAGER',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'System Generated Report',
              style: const pw.TextStyle(fontSize: 7),
            ),
            pw.Text(
              'Generated on: ${_fmtDateTime(now)}',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
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
          color: PdfColor.fromInt(0xFF344054),
        ),
      ),
    );
  }

  static pw.Widget _td(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromInt(0xFF1D2939),
        ),
      ),
    );
  }

  static PdfColor _statusBg(String status) {
    switch (status) {
      case 'PRESENT':
        return PdfColor.fromInt(0xFFE5F6EA);
      case 'LATE':
        return PdfColor.fromInt(0xFFFFF0E4);
      case 'ABSENT':
        return PdfColor.fromInt(0xFFFFEBED);
      case 'LEAVE':
      case 'ON LEAVE':
        return PdfColor.fromInt(0xFFEAF1FF);
      default:
        return PdfColor.fromInt(0xFFF2F4F7);
    }
  }

  static PdfColor _statusFg(String status) {
    switch (status) {
      case 'PRESENT':
        return PdfColor.fromInt(0xFF1F8D4E);
      case 'LATE':
        return PdfColor.fromInt(0xFFD45B00);
      case 'ABSENT':
        return PdfColor.fromInt(0xFFBE1E2D);
      case 'LEAVE':
      case 'ON LEAVE':
        return PdfColor.fromInt(0xFF2D5BDB);
      default:
        return PdfColor.fromInt(0xFF475467);
    }
  }

  static String _fmtTime(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate();
      final h24 = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = h24 >= 12 ? 'PM' : 'AM';
      final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
      return '${h12.toString().padLeft(2, '0')}:$minute $period';
    }
    return '--:--';
  }

  static String _fmtHours(double hours) {
    final totalMinutes = (hours * 60).round();
    final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final mm = (totalMinutes % 60).toString().padLeft(2, '0');
    return '${hh}h ${mm}m';
  }

  static String _fmtDate(String ymd) {
    final dt = DateTime.tryParse(ymd);
    if (dt == null) return ymd;
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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _dayName(String ymd) {
    final dt = DateTime.tryParse(ymd);
    if (dt == null) return '--';
    const days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dt.weekday - 1];
  }

  static String _monthLabel(DateTime month) {
    const months = <String>[
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
    return '${months[month.month - 1]} ${month.year}';
  }

  static String _monthFile(DateTime month) {
    return '${month.year}_${month.month.toString().padLeft(2, '0')}';
  }

  static String _fmtDateTime(DateTime dt) {
    return '${_fmtDate(dt.toIso8601String().split('T').first)} ${_fmtTime(Timestamp.fromDate(dt))}';
  }
}
