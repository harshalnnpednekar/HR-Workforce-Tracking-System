import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PayslipPdfService {
  static final _db = FirebaseFirestore.instance;

  static Future<String?> generateAndSharePayslip({
    required String uid,
    required Map<String, dynamic> payrollData,
  }) async {
    final month = (payrollData['month'] as String?) ?? 'Month';
    final year = (payrollData['year'] as num?)?.toInt() ?? DateTime.now().year;
    final monthYear =
        (payrollData['monthYear'] as String?) ?? _monthYearId(month, year);

    final employeeName =
        (payrollData['employeeName'] as String?)?.trim().isNotEmpty == true
        ? (payrollData['employeeName'] as String).trim()
        : 'Employee';
    final employeeId = (payrollData['employeeId'] as String?) ?? '';
    final designation = (payrollData['designation'] as String?) ?? '';
    final department = (payrollData['department'] as String?) ?? '';
    final bankLast4 = (payrollData['bankLast4'] as String?) ?? '';
    final joiningDate = (payrollData['joiningDate'] as String?) ?? '';
    final payPeriod = (payrollData['payPeriod'] as String?) ?? '01 - Last Day';

    // Attendance data
    final totalDays = (payrollData['totalDays'] as num?)?.toInt() ?? 0;
    final presentDays = (payrollData['presentDays'] as num?)?.toInt() ?? 0;
    final lateDays = (payrollData['lateDays'] as num?)?.toInt() ?? 0;
    final absentDays = (payrollData['absentDays'] as num?)?.toInt() ?? 0;
    final leaveDays = (payrollData['leaveDays'] as num?)?.toInt() ?? 0;

    final basic = (payrollData['basicSalary'] as num?)?.toDouble() ?? 0;
    final hra = (payrollData['hra'] as num?)?.toDouble() ?? 0;
    final conveyance = (payrollData['conveyance'] as num?)?.toDouble() ?? 0;
    final gross =
        (payrollData['grossSalary'] as num?)?.toDouble() ??
        (basic + hra + conveyance);

    final late = (payrollData['lateDeduction'] as num?)?.toDouble() ?? 0;
    final leave = (payrollData['leaveDeduction'] as num?)?.toDouble() ?? 0;
    final pf = (payrollData['pf'] as num?)?.toDouble() ?? 0;
    final tax = (payrollData['professionalTax'] as num?)?.toDouble() ?? 0;
    final totalDeduction =
        (payrollData['totalDeductions'] as num?)?.toDouble() ??
        (late + leave + pf + tax);
    final net =
        (payrollData['netSalary'] as num?)?.toDouble() ??
        (gross - totalDeduction);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Company Name and Title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EQUITEC TECHNOLOGIES',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '12th Floor, Tech Park Towers, Business District, Mumbai - 400001',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        'contact@equitec-tech.com | +91 22 4567 8900',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SALARY SLIP',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        month.toUpperCase(),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        year.toString(),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              // Employee Details Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _detailColumn('Employee Name', employeeName),
                  _detailColumn('Designation', designation),
                  _detailColumn('Senior Software Engineer', ''),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _detailColumn('Employee ID', employeeId),
                  _detailColumn('Department', department),
                  _detailColumn('Product Development', ''),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _detailColumn('Joining Date', joiningDate),
                  _detailColumn(
                    'Bank Account',
                    'XXXX XXXX ${bankLast4.isNotEmpty ? bankLast4 : '5678'}',
                  ),
                  _detailColumn('', ''),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _detailColumn('Pay Period', payPeriod),
                  _detailColumn('Payment Date', '${_getCurrentDayAndDate()}'),
                  _detailColumn('', ''),
                ],
              ),
              pw.SizedBox(height: 14),

              // Attendance Summary
              pw.Text(
                'ATTENDANCE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(width: 0.5)),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'TOTAL DAYS',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              totalDays.toString(),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(width: 0.5)),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'PRESENT',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              presentDays.toString(),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(width: 0.5)),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'LATE',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              lateDays.toString(),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(width: 0.5)),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'ABSENT',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              absentDays.toString(),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'LEAVES',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              leaveDays.toString(),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Earnings and Deductions Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EARNINGS',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        _earningRow('Basic Salary', basic),
                        _earningRow('House Rent Allowance (HRA)', hra),
                        _earningRow('Conveyance Allowance', conveyance),
                        pw.Divider(thickness: 1),
                        _earningRow('Gross Earnings', gross, bold: true),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Deductions
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DEDUCTIONS',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        _earningRow('Provident Fund (PF)', pf),
                        _earningRow('Professional Tax', tax),
                        _earningRow('Late Deduction', late),
                        pw.Divider(thickness: 1),
                        _earningRow(
                          'Total Deductions',
                          totalDeduction,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Net Payable Amount Box
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF48300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'NET PAYABLE AMOUNT',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromInt(0xFFFFEED6),
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _formatInr(net),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Signature Section
              pw.Text(
                'This is a computer-generated document and does not require a physical signature for digital retention.',
                style: const pw.TextStyle(fontSize: 7, height: 1.2),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 80,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)),
                        ),
                      ),
                      pw.Text(
                        'Employee Signature',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        employeeName,
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 80,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)),
                        ),
                      ),
                      pw.Text(
                        'Authorized Signatory',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        'HR Department',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/payslip_${monthYear}_$uid.pdf');
    await file.writeAsBytes(bytes, flush: true);

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Payslip_${employeeName}_${month}_${year}.pdf',
    );

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'payslips/$uid/$monthYear.pdf',
      );
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await _db
          .collection('payroll')
          .doc(uid)
          .collection('months')
          .doc(monthYear)
          .set({'pdfSlipUrl': downloadUrl}, SetOptions(merge: true));

      return downloadUrl;
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _detailColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7,
            color: PdfColor.fromInt(0xFF666666),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _earningRow(
    String label,
    double amount, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          ),
          pw.Text(
            _formatInr(amount),
            style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }

  static String _getCurrentDayAndDate() {
    final now = DateTime.now();
    return '${now.day} ${_getMonthName(now.month)} ${now.year}';
  }

  static String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  static String _monthYearId(String month, int year) {
    return '${month.toLowerCase()}-$year';
  }

  static String _formatInr(double amount) {
    final s = amount.toStringAsFixed(0);
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    final remaining = s.substring(0, s.length - 3);
    final groups = <String>[];
    var rem = remaining;
    while (rem.length > 2) {
      groups.insert(0, rem.substring(rem.length - 2));
      rem = rem.substring(0, rem.length - 2);
    }
    if (rem.isNotEmpty) {
      groups.insert(0, rem);
    }
    return '₹${groups.join(',')},$last3';
  }
}
