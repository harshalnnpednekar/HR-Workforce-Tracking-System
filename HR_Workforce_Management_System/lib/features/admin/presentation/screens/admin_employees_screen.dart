import 'package:flutter/material.dart';

import '../widgets/admin_ui_kit.dart';

class AdminEmployeesScreen extends StatelessWidget {
  const AdminEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const employees = [
      _EmployeeEntry(
        name: 'Marcus Chambers',
        code: 'EMP-2045',
        role: 'Product Designer',
        email: 'm.zharrah@myhr.com',
        status: 'ACTIVE',
        initials: 'MC',
      ),
      _EmployeeEntry(
        name: 'Elena Rodriguez',
        code: 'EMP-2102',
        role: 'Engineering Lead',
        email: 'e.rodr@myhr.com',
        status: 'ACTIVE',
        initials: 'ER',
      ),
      _EmployeeEntry(
        name: 'Julian Vale',
        code: 'EMP-1988',
        role: 'Marketing Ops',
        email: 'j.vale@myhr.com',
        status: 'INACTIVE',
        initials: 'JV',
      ),
      _EmployeeEntry(
        name: 'Sarah Jenkins',
        code: 'EMP-2144',
        role: 'QA Engineer',
        email: 's.jenkins@myhr.com',
        status: 'ACTIVE',
        initials: 'SJ',
      ),
      _EmployeeEntry(
        name: 'Amara Okeke',
        code: 'EMP-2201',
        role: 'HR Specialist',
        email: 'a.okeke@myhr.com',
        status: 'ACTIVE',
        initials: 'AO',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employees',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 16),
          AdminSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: const [
                Icon(Icons.search_rounded, color: Color(0xFFB2BED2)),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, ID or role',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FilterChip(label: 'All Departments', active: true),
              _FilterChip(label: 'Active'),
              _FilterChip(label: 'Designation'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'ALL MEMBERS (124)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...employees.map(_EmployeeCard.new),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: active ? AdminColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AdminColors.primary : AdminColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF566C8D),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: active ? Colors.white : const Color(0xFF566C8D),
          ),
        ],
      ),
    );
  }
}

class _EmployeeEntry {
  const _EmployeeEntry({
    required this.name,
    required this.code,
    required this.role,
    required this.email,
    required this.status,
    required this.initials,
  });

  final String name;
  final String code;
  final String role;
  final String email;
  final String status;
  final String initials;
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard(this.employee);

  final _EmployeeEntry employee;

  @override
  Widget build(BuildContext context) {
    final isActive = employee.status == 'ACTIVE';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AdminSurfaceCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFFEDE3)
                    : const Color(0xFFEAF0F7),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                employee.initials,
                style: TextStyle(
                  color: isActive
                      ? AdminColors.primary
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: const TextStyle(
                            color: AdminColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      AdminStatusPill(
                        label: employee.status,
                        backgroundColor: isActive
                            ? const Color(0xFFE2FBE8)
                            : const Color(0xFFF0F3F8),
                        textColor: isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee.code} · ${employee.role}',
                    style: const TextStyle(
                      color: Color(0xFF7B8CA8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    employee.email,
                    style: const TextStyle(
                      color: Color(0xFFA0AEC0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA8BE)),
          ],
        ),
      ),
    );
  }
}
