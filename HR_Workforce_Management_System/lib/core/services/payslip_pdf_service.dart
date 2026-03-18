import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
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
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Equitec Payslip',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Month: $month $year'),
              pw.SizedBox(height: 12),
              pw.Text('Employee: $employeeName'),
              pw.Text('Employee ID: $employeeId'),
              pw.Text('Designation: $designation'),
              pw.SizedBox(height: 16),
              pw.Text(
                'Earnings',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              _line('Basic Salary', basic),
              _line('HRA', hra),
              _line('Conveyance', conveyance),
              _line('Gross Salary', gross, bold: true),
              pw.SizedBox(height: 16),
              pw.Text(
                'Deductions',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              _line('Late Deduction', late),
              _line('Leave Deduction', leave),
              _line('Provident Fund', pf),
              _line('Professional Tax', tax),
              _line('Total Deductions', totalDeduction, bold: true),
              pw.Divider(),
              _line('Net Salary', net, bold: true),
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
      filename: 'Equitec_Payslip_${month}_${year}.pdf',
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

  static pw.Widget _line(String label, double amount, {bool bold = false}) {
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

  static String _monthYearId(String month, int year) {
    return '${month.toLowerCase()}-$year';
  }

  static String _formatInr(double amount) {
    final s = amount.toStringAsFixed(0);
    if (s.length <= 3) return 'Rs$s';
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
    return 'Rs${groups.join(',')},$last3';
  }
}
