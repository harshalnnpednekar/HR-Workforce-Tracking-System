import 'package:flutter/material.dart';

enum AdminSection { dashboard, employees, leaves, payroll, hrPolicy, reports }

extension AdminSectionX on AdminSection {
  String get label => switch (this) {
    AdminSection.dashboard => 'Dashboard',
    AdminSection.employees => 'Employees',
    AdminSection.leaves => 'Leaves',
    AdminSection.payroll => 'Payroll',
    AdminSection.hrPolicy => 'HR Rules & Policy',
    AdminSection.reports => 'Reports',
  };

  IconData get icon => switch (this) {
    AdminSection.dashboard => Icons.dashboard_rounded,
    AdminSection.employees => Icons.groups_rounded,
    AdminSection.leaves => Icons.event_note_rounded,
    AdminSection.payroll => Icons.account_balance_wallet_rounded,
    AdminSection.hrPolicy => Icons.description_rounded,
    AdminSection.reports => Icons.insert_chart_rounded,
  };
}

const List<AdminSection> bottomAdminSections = [
  AdminSection.dashboard,
  AdminSection.employees,
  AdminSection.leaves,
  AdminSection.payroll,
];
