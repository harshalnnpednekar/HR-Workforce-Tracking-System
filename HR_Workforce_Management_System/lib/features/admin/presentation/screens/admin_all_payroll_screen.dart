import 'package:flutter/material.dart';

import '../../../../core/services/payroll_service.dart';
import '../widgets/admin_ui_kit.dart';

class AdminAllPayrollScreen extends StatefulWidget {
  const AdminAllPayrollScreen({super.key});

  @override
  State<AdminAllPayrollScreen> createState() => _AdminAllPayrollScreenState();
}

class _AdminAllPayrollScreenState extends State<AdminAllPayrollScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  String? _monthFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.text,
        title: const Text(
          'All Payroll Records',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: PayrollService.streamAllPayrollRecords(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load payroll records.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          final monthOptions =
              rows
                  .map((e) => ((e['monthYear'] as String?) ?? '').trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort((a, b) {
                  final aDate = PayrollService.monthDocIdToDate(
                    a.toLowerCase(),
                  );
                  final bDate = PayrollService.monthDocIdToDate(
                    b.toLowerCase(),
                  );
                  if (aDate != null && bDate != null) {
                    return bDate.compareTo(aDate);
                  }
                  return b.compareTo(a);
                });

          final term = _searchCtrl.text.trim().toLowerCase();
          final filtered = rows
              .where((row) {
                final status = ((row['status'] as String?) ?? 'pending')
                    .toLowerCase();
                if (_statusFilter != 'all' && status != _statusFilter) {
                  return false;
                }

                final monthYear = ((row['monthYear'] as String?) ?? '').trim();
                if (_monthFilter != null &&
                    _monthFilter!.isNotEmpty &&
                    monthYear != _monthFilter) {
                  return false;
                }

                if (term.isEmpty) return true;
                final name = ((row['employeeName'] as String?) ?? '')
                    .toLowerCase();
                final empId = ((row['employeeId'] as String?) ?? '')
                    .toLowerCase();
                final designation = ((row['designation'] as String?) ?? '')
                    .toLowerCase();
                return name.contains(term) ||
                    empId.contains(term) ||
                    designation.contains(term);
              })
              .toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name, employee ID, designation',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AdminColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AdminColors.border,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'paid',
                                child: Text('Paid'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _statusFilter = value ?? 'all');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _monthFilter,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Months'),
                              ),
                              ...monthOptions.map(
                                (m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(
                                    PayrollService.monthDocIdToLabel(m),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _monthFilter = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filtered.length} record(s)',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No payroll records found.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final row = filtered[index];
                          final name =
                              (row['employeeName'] as String?) ?? 'Employee';
                          final employeeId =
                              (row['employeeId'] as String?) ?? '-';
                          final monthYear =
                              (row['monthYear'] as String?) ?? '-';
                          final status =
                              ((row['status'] as String?) ?? 'pending')
                                  .toLowerCase();
                          final netSalary =
                              (row['netSalary'] as num?)?.toDouble() ?? 0;
                          final isEdited = row['isEdited'] == true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AdminSurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: AdminColors.text,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      AdminStatusPill(
                                        label: status == 'paid'
                                            ? 'PAID'
                                            : 'PENDING',
                                        backgroundColor: status == 'paid'
                                            ? const Color(0xFFE2FBE8)
                                            : const Color(0xFFFFF0E0),
                                        textColor: status == 'paid'
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFCC6D00),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$employeeId · ${PayrollService.monthDocIdToLabel(monthYear)}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Net: ${PayrollService.formatCurrency(netSalary)}',
                                        style: const TextStyle(
                                          color: AdminColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (isEdited) ...[
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Color(0xFFCC6D00),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Edited',
                                          style: TextStyle(
                                            color: Color(0xFFCC6D00),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
