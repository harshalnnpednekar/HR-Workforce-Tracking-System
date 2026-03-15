import 'package:flutter/material.dart';

import '../widgets/admin_ui_kit.dart';

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});

  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  int _selectedMonth = 1;

  static const _months = ['September', 'October', 'November'];

  static const _payrollPeople = [
    _PayrollPerson(
      name: 'Alex Thompson',
      role: 'Senior Designer',
      gross: '\$8,500',
      deductions: '-\$1,200',
      netSalary: '\$7,300',
      status: 'PAID',
    ),
    _PayrollPerson(
      name: 'Sarah Jenkins',
      role: 'Product Manager',
      gross: '\$9,200',
      deductions: '-\$1,450',
      netSalary: '\$7,750',
      status: 'PENDING',
    ),
    _PayrollPerson(
      name: 'Michael Ross',
      role: 'Fullstack Developer',
      gross: '\$7,800',
      deductions: '-\$900',
      netSalary: '\$6,900',
      status: 'PAID',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payroll Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(_months.length, (index) {
              final selected = index == _selectedMonth;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMonth = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AdminColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: Color(0x33FF5B0A),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _months[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.08,
            children: const [
              _PayrollSummaryCard(
                title: 'Total Payroll',
                value: '\$245,000',
                footer: '+2.4%',
                footerColor: Color(0xFF16A34A),
              ),
              _PayrollSummaryCard(
                title: 'Pending',
                value: '12',
                footer: 'In review',
                footerColor: AdminColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const AdminSectionHeader(
            title: 'Employee Salaries',
            actionLabel: 'See all',
          ),
          const SizedBox(height: 14),
          ..._payrollPeople.map(
            (person) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _PayrollCard(person: person),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 62),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.payments_outlined),
            label: const Text(
              'Process Bulk Payments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollSummaryCard extends StatelessWidget {
  const _PayrollSummaryCard({
    required this.title,
    required this.value,
    required this.footer,
    required this.footerColor,
  });

  final String title;
  final String value;
  final String footer;
  final Color footerColor;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF667B9A),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            footer,
            style: TextStyle(
              color: footerColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollPerson {
  const _PayrollPerson({
    required this.name,
    required this.role,
    required this.gross,
    required this.deductions,
    required this.netSalary,
    required this.status,
  });

  final String name;
  final String role;
  final String gross;
  final String deductions;
  final String netSalary;
  final String status;
}

class _PayrollCard extends StatelessWidget {
  const _PayrollCard({required this.person});

  final _PayrollPerson person;

  @override
  Widget build(BuildContext context) {
    final isPaid = person.status == 'PAID';

    return AdminSurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD1FAE5), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  person.name.characters.first,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      person.role,
                      style: const TextStyle(
                        color: Color(0xFF74849F),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusPill(
                label: person.status,
                backgroundColor: isPaid
                    ? const Color(0xFFE2FBE8)
                    : const Color(0xFFFFF0E0),
                textColor: isPaid
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFCC6D00),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AdminColors.border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SalaryMetric(
                  label: 'GROSS',
                  value: person.gross,
                  valueColor: AdminColors.text,
                ),
              ),
              Expanded(
                child: _SalaryMetric(
                  label: 'DEDUCTIONS',
                  value: person.deductions,
                  valueColor: Colors.red,
                ),
              ),
              Expanded(
                child: _SalaryMetric(
                  label: 'NET SALARY',
                  value: person.netSalary,
                  valueColor: AdminColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalaryMetric extends StatelessWidget {
  const _SalaryMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA1AEC0),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
