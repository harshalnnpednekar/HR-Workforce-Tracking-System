import 'package:intl/intl.dart';

enum EqBotRole { user, assistant }

class EqBotChatMessage {
  EqBotChatMessage({
    required this.role,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final EqBotRole role;
  final String text;
  final DateTime createdAt;
}

class EqBotUserContext {
  const EqBotUserContext({
    required this.employeeName,
    required this.department,
    required this.role,
    required this.leaveCasual,
    required this.leaveSick,
    required this.leaveAnnual,
    required this.currentMonthSalary,
    required this.salaryStatus,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.workingHours,
    required this.lateThresholdText,
    required this.lateDeduction,
    required this.pfPercent,
    required this.professionalTax,
    required this.monthLabel,
  });

  final String employeeName;
  final String department;
  final String role;

  final int leaveCasual;
  final int leaveSick;
  final int leaveAnnual;

  final double? currentMonthSalary;
  final String salaryStatus;

  final int presentCount;
  final int lateCount;
  final int absentCount;

  final String workingHours;
  final String lateThresholdText;
  final double lateDeduction;
  final double pfPercent;
  final double professionalTax;

  final String monthLabel;

  String get systemPrompt {
    final salaryText = currentMonthSalary == null
        ? 'Not available'
        : _formatRupees(currentMonthSalary!);

    return '''
You are EqBot, the HR assistant for Equitec Technologies.

Employee: $employeeName | Dept: $department | Role: $role
Leave Balance: Casual: $leaveCasual, Sick: $leaveSick, Annual: $leaveAnnual
Current Month Salary ($monthLabel): $salaryText | Status: $salaryStatus
Attendance This Month: $presentCount present, $lateCount late, $absentCount absent

HR Rules:
- Working hours: $workingHours
- Late threshold: $lateThresholdText
- Late deduction: ${_formatRupees(lateDeduction)} per late mark
- PF: ${_trimTrailingZeros(pfPercent)}% of basic, PT: ${_formatRupees(professionalTax)}/month

Answer only HR, payroll, attendance, leave, and company policy questions for this organization.
If asked something outside this scope, politely decline in one sentence.
Keep answers concise, practical, and easy for employees to understand.
''';
  }

  String _formatRupees(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');
    return formatter.format(amount);
  }

  String _trimTrailingZeros(double value) {
    final text = value.toStringAsFixed(2);
    if (!text.contains('.')) {
      return text;
    }
    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
