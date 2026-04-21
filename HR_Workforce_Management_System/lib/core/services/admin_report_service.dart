import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AdminReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final _orangeAccent = PdfColor.fromHex('#E65100');

  // ─── Formatters ──────────────────────────────────────────────────────────

  static String formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // ─── Attendance Trend Report ─────────────────────────────────────────────

  static Future<Uint8List> generateAttendanceTrendReport(DateTime month) async {
    final pdf = pw.Document();
    final monthStr = DateFormat('yyyy-MM').format(month);
    final monthYearLabel = DateFormat('MMMM yyyy').format(month);

    // 1. Fetch all employees
    final employeesSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .get();

    final List<Map<String, dynamic>> employeeStats = [];
    int totalPresent = 0;
    int totalLate = 0;
    int totalAbsent = 0;
    int totalDaysAcrossAll = 0;

    // 2. Fetch attendance for each employee
    for (final empDoc in employeesSnap.docs) {
      final uid = empDoc.id;
      final data = empDoc.data();
      
      final attendanceSnap = await _db
          .collection('attendance')
          .doc(uid)
          .collection('records')
          .where('date', isGreaterThanOrEqualTo: '$monthStr-01')
          .where('date', isLessThanOrEqualTo: '$monthStr-31')
          .get();

      int present = 0;
      int late = 0;
      int absent = 0;
      int halfDay = 0;
      int onLeave = 0;

      for (final doc in attendanceSnap.docs) {
        final status = doc.data()['status']?.toString().toLowerCase();
        if (status == 'present') {
          present++;
        } else if (status == 'late') {
          late++;
        } else if (status == 'absent') {
          absent++;
        } else if (status == 'half-day') {
          halfDay++;
        } else if (status == 'leave') {
          onLeave++;
        }
      }

      final totalWorkingDays = attendanceSnap.docs.length;
      final attendancePct = totalWorkingDays > 0 
          ? ((present + late + (halfDay * 0.5)) / totalWorkingDays * 100)
          : 0.0;

      employeeStats.add({
        'name': data['name'] ?? 'Unknown',
        'dept': data['department'] ?? 'General',
        'present': present,
        'late': late,
        'absent': absent,
        'halfDay': halfDay,
        'onLeave': onLeave,
        'pct': attendancePct,
      });

      totalPresent += (present + late);
      totalLate += late;
      totalAbsent += absent;
      totalDaysAcrossAll += totalWorkingDays;
    }

    // Sort by attendance % descending
    employeeStats.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));

    final avgOnTime = totalDaysAcrossAll > 0 ? ((totalPresent - totalLate) / totalDaysAcrossAll * 100) : 0.0;
    final avgLate = totalDaysAcrossAll > 0 ? (totalLate / totalDaysAcrossAll * 100) : 0.0;
    final avgAbsent = totalDaysAcrossAll > 0 ? (totalAbsent / totalDaysAcrossAll * 100) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        header: (context) => _buildHeader('Attendance Trend Report', monthYearLabel),
        footer: (context) => _buildFooter(),
        build: (context) => [
          if (employeeStats.isEmpty)
            pw.Center(child: pw.Text('No records found for this period', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)))
          else ...[
            _buildSummaryCards([
              _SummaryItem('Total Days', totalDaysAcrossAll.toString(), background: PdfColor.fromInt(0xFFF8FAFC), valueColor: PdfColor.fromInt(0xFF1D2939)),
              _SummaryItem('Avg On-Time', '${avgOnTime.toStringAsFixed(1)}%', background: PdfColor.fromInt(0xFFE8F5ED), valueColor: PdfColor.fromInt(0xFF137A3B)),
              _SummaryItem('Avg Late', '${avgLate.toStringAsFixed(1)}%', background: PdfColor.fromInt(0xFFFFF1E5), valueColor: PdfColor.fromInt(0xFFED6A0C)),
              _SummaryItem('Avg Absent', '${avgAbsent.toStringAsFixed(1)}%', background: PdfColor.fromInt(0xFFFFECEC), valueColor: PdfColor.fromInt(0xFFBE1E2D)),
            ]),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'Department', 'Present', 'Late', 'Absent', 'Half-Day', 'Leave', 'Att. %'],
              data: employeeStats.map((e) => [
                e['name'],
                e['dept'],
                e['present'].toString(),
                e['late'].toString(),
                e['absent'].toString(),
                e['halfDay'].toString(),
                e['onLeave'].toString(),
                '${(e['pct'] as double).toStringAsFixed(1)}%',
              ]).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: _orangeAccent),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Leave Utilization Report ──────────────────────────────────────────

  static Future<Uint8List> generateLeaveUtilizationReport(DateTime month) async {
    final pdf = pw.Document();
    final monthYearLabel = DateFormat('MMMM yyyy').format(month);
    final monthStart = Timestamp.fromDate(DateTime(month.year, month.month, 1));
    final monthEnd = Timestamp.fromDate(DateTime(month.year, month.month + 1, 0, 23, 59, 59));

    // 1. Fetch leaves
    final leavesSnap = await _db
        .collection('leaves')
        .where('fromDate', isGreaterThanOrEqualTo: monthStart)
        .where('fromDate', isLessThanOrEqualTo: monthEnd)
        .get();

    int approved = 0;
    int rejected = 0;
    int pending = 0;

    final Map<String, Map<String, int>> deptStats = {};
    final List<List<String>> detailedRows = [];

    for (final doc in leavesSnap.docs) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase() ?? 'pending';
      final dept = data['department'] ?? 'General';

      if (status == 'approved') {
        approved++;
      } else if (status == 'rejected') {
        rejected++;
      } else {
        pending++;
      }

      // Dept stats
      deptStats.putIfAbsent(dept, () => {'total': 0, 'approved': 0, 'pending': 0, 'rejected': 0});
      deptStats[dept]!['total'] = deptStats[dept]!['total']! + 1;
      deptStats[dept]![status == 'approved' ? 'approved' : (status == 'rejected' ? 'rejected' : 'pending')] = 
          deptStats[dept]![status == 'approved' ? 'approved' : (status == 'rejected' ? 'rejected' : 'pending')]! + 1;

      detailedRows.add([
        data['employeeName'] ?? 'Unknown',
        dept,
        data['leaveType'] ?? 'Leave',
        formatDate((data['fromDate'] as Timestamp).toDate()),
        formatDate((data['toDate'] as Timestamp).toDate()),
        data['totalDays']?.toString() ?? '0',
        status.toUpperCase(),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        header: (context) => _buildHeader('Leave Utilization Report', monthYearLabel),
        footer: (context) => _buildFooter(),
        build: (context) => [
          if (leavesSnap.docs.isEmpty)
            pw.Center(child: pw.Text('No records found for this period', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)))
          else ...[
            _buildSummaryCards([
              _SummaryItem('Total Requests', leavesSnap.docs.length.toString(), background: PdfColor.fromInt(0xFFF8FAFC), valueColor: PdfColor.fromInt(0xFF1D2939)),
              _SummaryItem('Approved', approved.toString(), background: PdfColor.fromInt(0xFFE8F5ED), valueColor: PdfColor.fromInt(0xFF137A3B)),
              _SummaryItem('Pending', pending.toString(), background: PdfColor.fromInt(0xFFFFF1E5), valueColor: PdfColor.fromInt(0xFFED6A0C)),
              _SummaryItem('Rejected', rejected.toString(), background: PdfColor.fromInt(0xFFFFECEC), valueColor: PdfColor.fromInt(0xFFBE1E2D)),
            ]),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Department-wise Load', textStyle: pw.TextStyle(color: _orangeAccent)),
            pw.TableHelper.fromTextArray(
              headers: ['Department', 'Total', 'Approved', 'Pending', 'Rejected'],
              data: deptStats.entries.map((e) => [
                e.key,
                e.value['total'].toString(),
                e.value['approved'].toString(),
                e.value['pending'].toString(),
                e.value['rejected'].toString(),
              ]).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: _orangeAccent),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Detailed Requests', textStyle: pw.TextStyle(color: _orangeAccent)),
            pw.TableHelper.fromTextArray(
              headers: ['Employee', 'Dept', 'Type', 'From', 'To', 'Days', 'Status'],
              data: detailedRows,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: _orangeAccent),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Payroll Variance Report ─────────────────────────────────────────────

  static Future<Uint8List> generatePayrollVarianceReport(DateTime currentMonth) async {
    final pdf = pw.Document();
    final monthLabel = DateFormat('MMMM yyyy').format(currentMonth);

    final m0 = _getMonthDocId(currentMonth);
    final m1 = _getMonthDocId(DateTime(currentMonth.year, currentMonth.month - 1));
    final m2 = _getMonthDocId(DateTime(currentMonth.year, currentMonth.month - 2));

    final employeesSnap = await _db.collection('users').where('role', isEqualTo: 'employee').get();
    
    final List<Map<String, dynamic>> comparisonData = [];
    double totalM0 = 0;

    for (final empDoc in employeesSnap.docs) {
      final uid = empDoc.id;
      final name = empDoc.data()['name'] ?? 'Unknown';

      final p0Doc = await _db.collection('payroll').doc(uid).collection('months').doc(m0).get();
      final p1Doc = await _db.collection('payroll').doc(uid).collection('months').doc(m1).get();
      final p2Doc = await _db.collection('payroll').doc(uid).collection('months').doc(m2).get();

      if (!p0Doc.exists && !p1Doc.exists && !p2Doc.exists) continue;

      final net0 = (p0Doc.data()?['netSalary'] as num?)?.toDouble() ?? 0.0;
      final net1 = (p1Doc.data()?['netSalary'] as num?)?.toDouble() ?? 0.0;
      final net2 = (p2Doc.data()?['netSalary'] as num?)?.toDouble() ?? 0.0;

      final change = net1 > 0 ? ((net0 - net1) / net1 * 100) : 0.0;

      comparisonData.add({
        'name': name,
        'm0': net0,
        'm1': net1,
        'm2': net2,
        'change': change,
        'details': p0Doc.data() ?? {},
      });

      totalM0 += net0;
    }

    double totalM1 = comparisonData.fold(0.0, (acc, e) => acc + (e['m1'] as double));
    double avgChange = comparisonData.isEmpty ? 0.0 : comparisonData.fold(0.0, (acc, e) => acc + (e['change'] as double)) / comparisonData.length;

    pdf.addPage(
      pw.MultiPage(
        header: (context) => _buildHeader('Payroll Variance Report', monthLabel),
        footer: (context) => _buildFooter(),
        build: (context) => [
          if (comparisonData.isEmpty)
            pw.Center(child: pw.Text('No records found for this period', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)))
          else ...[
            _buildSummaryCards([
              _SummaryItem('Current Payroll', formatCurrency(totalM0), background: PdfColor.fromInt(0xFFF8FAFC), valueColor: _orangeAccent),
              _SummaryItem('Prev. Payroll', formatCurrency(totalM1), background: PdfColors.grey100, valueColor: PdfColor.fromInt(0xFF1D2939)),
              _SummaryItem('Variance %', '${avgChange.toStringAsFixed(1)}%', background: avgChange >= 0 ? PdfColor.fromInt(0xFFFFECEC) : PdfColor.fromInt(0xFFE8F5ED), valueColor: avgChange >= 0 ? PdfColor.fromInt(0xFFBE1E2D) : PdfColor.fromInt(0xFF137A3B)),
            ]),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Employee', _getMonthLabel(m2), _getMonthLabel(m1), _getMonthLabel(m0), 'Change %'],
              data: comparisonData.map((e) => [
                e['name'],
                formatCurrency(e['m2']),
                formatCurrency(e['m1']),
                formatCurrency(e['m0']),
                '${(e['change'] as double).toStringAsFixed(1)}%',
              ]).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: _orangeAccent),
              rowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.SizedBox(height: 10),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text('Total Payroll: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(formatCurrency(totalM0), style: pw.TextStyle(color: _orangeAccent, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Current Month Deductions Breakdown', textStyle: pw.TextStyle(color: _orangeAccent)),
            pw.TableHelper.fromTextArray(
              headers: ['Employee', 'Basic', 'HRA', 'Allowances', 'Deductions', 'Net Pay'],
              data: comparisonData.map((e) {
                final d = e['details'] as Map<String, dynamic>;
                return [
                  e['name'],
                  formatCurrency(d['basicSalary'] ?? 0),
                  formatCurrency(d['hra'] ?? 0),
                  formatCurrency(d['conveyance'] ?? 0),
                  formatCurrency(d['totalDeductions'] ?? 0),
                  formatCurrency(e['m0']),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: _orangeAccent),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Headcount Overview Report ──────────────────────────────────────────

  static Future<Uint8List> generateHeadcountOverviewReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final employeesSnap = await _db.collection('users').where('role', isEqualTo: 'employee').get();
    
    int active = 0, inactive = 0, newThisMonth = 0;
    final Map<String, Map<String, int>> deptStats = {};
    final List<List<String>> roster = [];

    for (final doc in employeesSnap.docs) {
      final data = doc.data();
      final isActive = data['isActive'] == true;
      final joinDate = (data['joinDate'] as String?) ?? '';
      final parsedJoinDate = DateTime.tryParse(joinDate);
      final dept = data['department'] ?? 'General';

      if (isActive) {
        active++;
      } else {
        inactive++;
      }
      if (parsedJoinDate != null && parsedJoinDate.isAfter(monthStart)) {
        newThisMonth++;
      }

      // Dept stats
      deptStats.putIfAbsent(dept, () => {'total': 0, 'active': 0, 'inactive': 0});
      deptStats[dept]!['total'] = deptStats[dept]!['total']! + 1;
      if (isActive) {
        deptStats[dept]!['active'] = deptStats[dept]!['active']! + 1;
      } else {
        deptStats[dept]!['inactive'] = deptStats[dept]!['inactive']! + 1;
      }

      roster.add([
        data['username'] ?? '---',
        data['name'] ?? 'Unknown',
        dept,
        data['designation'] ?? '---',
        joinDate.isNotEmpty && parsedJoinDate != null ? formatDate(parsedJoinDate) : '---',
        isActive ? 'ACTIVE' : 'INACTIVE',
      ]);
    }

    // Sort roster by dept then name
    roster.sort((a, b) {
      int cmp = a[2].compareTo(b[2]);
      if (cmp == 0) cmp = a[1].compareTo(b[1]);
      return cmp;
    });

    pdf.addPage(
      pw.MultiPage(
        header: (context) => _buildHeader('Headcount Overview Report', formatDate(now)),
        footer: (context) => _buildFooter(),
        build: (context) => [
          if (employeesSnap.docs.isEmpty)
            pw.Center(child: pw.Text('No records found', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)))
          else ...[
            _buildSummaryCards([
              _SummaryItem('Total Employees', employeesSnap.docs.length.toString(), background: PdfColor.fromInt(0xFFF8FAFC), valueColor: PdfColor.fromInt(0xFF1D2939)),
              _SummaryItem('Active', active.toString(), background: PdfColor.fromInt(0xFFE8F5ED), valueColor: PdfColor.fromInt(0xFF137A3B)),
              _SummaryItem('Inactive', inactive.toString(), background: PdfColor.fromInt(0xFFFFECEC), valueColor: PdfColor.fromInt(0xFFBE1E2D)),
              _SummaryItem('New This Month', newThisMonth.toString(), background: PdfColor.fromInt(0xFFFFF1E5), valueColor: PdfColor.fromInt(0xFFED6A0C)),
            ]),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Department-wise Headcount', textStyle: pw.TextStyle(color: _orangeAccent)),
            pw.TableHelper.fromTextArray(
              headers: ['Department', 'Total', 'Active', 'Inactive', '% Workforce'],
              data: deptStats.entries.map((e) => [
                e.key,
                e.value['total'].toString(),
                e.value['active'].toString(),
                e.value['inactive'].toString(),
                '${(e.value['total']! / employeesSnap.docs.length * 100).toStringAsFixed(1)}%',
              ]).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: _orangeAccent),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Employee Roster', textStyle: pw.TextStyle(color: _orangeAccent)),
            pw.TableHelper.fromTextArray(
              headers: ['Emp ID', 'Name', 'Department', 'Designation', 'Join Date', 'Status'],
              data: roster,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: _orangeAccent),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Shared Layout Components ──────────────────────────────────────────

  static pw.Widget _buildHeader(String title, String subtitle) {
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
                    color: _orangeAccent,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  title.toUpperCase(),
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
                  'Equitec Technologies',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1D2939),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Report Period: $subtitle',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.5, color: _orangeAccent),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated by EqHR Admin — Equitec Technologies', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCards(List<_SummaryItem> items) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: items.map((item) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 4),
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: item.background ?? PdfColors.white,
            border: pw.Border.all(color: item.background != null ? item.background! : _orangeAccent),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              pw.Text(item.label.toUpperCase(), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(item.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: item.valueColor ?? _orangeAccent)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  static String _getMonthDocId(DateTime date) {
    final months = ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];
    return '${months[date.month - 1]}-${date.year}';
  }

  static String _getMonthLabel(String docId) {
    final parts = docId.split('-');
    if (parts.length != 2) return docId;
    return '${parts[0][0].toUpperCase()}${parts[0].substring(1)} ${parts[1]}';
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final PdfColor? background;
  final PdfColor? valueColor;
  _SummaryItem(this.label, this.value, {this.background, this.valueColor});
}
