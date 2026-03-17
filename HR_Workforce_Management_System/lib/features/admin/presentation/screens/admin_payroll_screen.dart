import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/payroll_service.dart';
import '../widgets/admin_ui_kit.dart';

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});

  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  late List<String> _monthDocIds;
  int _selectedMonthIndex = 0;

  @override
  void initState() {
    super.initState();
    _monthDocIds = PayrollService.recentMonthDocIds(count: 3).reversed.toList();
  }

  String get _selectedMonthDocId => _monthDocIds[_selectedMonthIndex];

  String _monthLabel(String docId) => PayrollService.monthDocIdToLabel(docId);

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
          // ── Month Selector ────────────────────────────────────────────────
          Row(
            children: List.generate(_monthDocIds.length, (index) {
              final selected = index == _selectedMonthIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMonthIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.only(right: index == _monthDocIds.length - 1 ? 0 : 12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AdminColors.primary : Colors.transparent,
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
                      _monthLabel(_monthDocIds[index]).split(' ').first,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF64748B),
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
          // ── Summary Cards (live) ──────────────────────────────────────────
          StreamBuilder<PayrollSummary>(
            stream: PayrollService.streamPayrollSummary(_selectedMonthDocId),
            builder: (context, snapshot) {
              final summary = snapshot.data;
              final totalNet = summary?.totalNetSalary ?? 0;
              final pending = summary?.pendingCount ?? 0;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.08,
                children: [
                  _PayrollSummaryCard(
                    title: 'Total Payroll',
                    value: PayrollService.formatCurrency(totalNet),
                    footer: snapshot.connectionState == ConnectionState.waiting
                        ? 'Loading…'
                        : '${snapshot.data != null ? "Live" : "–"} data',
                    footerColor: const Color(0xFF16A34A),
                    loading: !snapshot.hasData,
                  ),
                  _PayrollSummaryCard(
                    title: 'Pending',
                    value: '$pending',
                    footer: pending == 1 ? 'In review' : 'In review',
                    footerColor: AdminColors.primary,
                    loading: !snapshot.hasData,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          // ── Employee Salary List (live) ────────────────────────────────────
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: PayrollService.streamAllPayrollForMonth(_selectedMonthDocId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _InlineError(
                  message: 'Failed to load payroll data.\n${snapshot.error}',
                );
              }

              final records = snapshot.data ?? const [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionHeader(
                    title: 'Employee Salaries',
                    actionLabel: records.isEmpty ? null : '${records.length} employees',
                  ),
                  const SizedBox(height: 14),
                  if (!snapshot.hasData)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (records.isEmpty)
                    const _EmptyPayroll()
                  else
                    ...records.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _PayrollCard(
                          record: record,
                          onTap: () => _openPayrollDetail(context, record),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          // ── Process Bulk Payments ─────────────────────────────────────────
          _BulkPayButton(
            monthDocId: _selectedMonthDocId,
            monthLabel: _monthLabel(_selectedMonthDocId),
          ),
        ],
      ),
    );
  }

  void _openPayrollDetail(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PayrollDetailScreen(
          record: record,
          monthDocId: _selectedMonthDocId,
        ),
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _PayrollSummaryCard extends StatelessWidget {
  const _PayrollSummaryCard({
    required this.title,
    required this.value,
    required this.footer,
    required this.footerColor,
    this.loading = false,
  });

  final String title;
  final String value;
  final String footer;
  final Color footerColor;
  final bool loading;

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
          loading
              ? const SizedBox(
                  height: 28,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          const SizedBox(height: 12),
          Text(
            footer,
            style: TextStyle(
              color: footerColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Employee Payroll Card ─────────────────────────────────────────────────────

class _PayrollCard extends StatelessWidget {
  const _PayrollCard({required this.record, this.onTap});

  final Map<String, dynamic> record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = (record['employeeName'] as String?) ?? 'Unknown';
    final role = (record['designation'] as String?) ?? '—';
    final gross = (record['grossSalary'] as num?)?.toDouble() ?? 0;
    final deductions = (record['totalDeductions'] as num?)?.toDouble() ?? 0;
    final netSalary = (record['netSalary'] as num?)?.toDouble() ?? 0;
    final status = (record['status'] as String?) ?? 'pending';
    final isPaid = status == 'paid';

    return AdminSurfaceCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              _EmployeeAvatar(name: name, photoUrl: record['photoUrl'] as String?),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
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
                label: isPaid ? 'PAID' : 'PENDING',
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
                  value: PayrollService.formatCurrency(gross),
                  valueColor: AdminColors.text,
                ),
              ),
              Expanded(
                child: _SalaryMetric(
                  label: 'DEDUCTIONS',
                  value: '-${PayrollService.formatCurrency(deductions)}',
                  valueColor: AdminColors.red,
                ),
              ),
              Expanded(
                child: _SalaryMetric(
                  label: 'NET',
                  value: PayrollService.formatCurrency(netSalary),
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

// ─── Avatar Widget ────────────────────────────────────────────────────────────

class _EmployeeAvatar extends StatelessWidget {
  const _EmployeeAvatar({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          photoUrl!,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Fallback(name: name),
        ),
      );
    }
    return _Fallback(name: name);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: const TextStyle(
          color: AdminColors.text,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
      ),
    );
  }
}

// ─── Salary Metric ────────────────────────────────────────────────────────────

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
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Bulk Pay Button ──────────────────────────────────────────────────────────

class _BulkPayButton extends StatefulWidget {
  const _BulkPayButton({
    required this.monthDocId,
    required this.monthLabel,
  });

  final String monthDocId;
  final String monthLabel;

  @override
  State<_BulkPayButton> createState() => _BulkPayButtonState();
}

class _BulkPayButtonState extends State<_BulkPayButton> {
  bool _loading = false;

  Future<void> _process() async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (adminUid.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Process Bulk Payments?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'All pending payroll for ${widget.monthLabel} will be marked as paid. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final count = await PayrollService.processBulkPayments(
        monthYear: widget.monthDocId,
        adminUid: adminUid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? '$count employee salaries processed for ${widget.monthLabel}.'
                : 'No pending payroll to process.',
          ),
          backgroundColor: AdminColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AdminColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _loading ? null : _process,
      style: FilledButton.styleFrom(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 62),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: _loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Icon(Icons.payments_outlined),
      label: Text(
        _loading ? 'Processing…' : 'Process Bulk Payments',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyPayroll extends StatelessWidget {
  const _EmptyPayroll();

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AdminColors.softOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AdminColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No payroll records',
            style: TextStyle(
              color: AdminColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No payroll has been created for this month yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Inline Error ─────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Payroll Detail Screen
// ═══════════════════════════════════════════════════════════════════════════════

class PayrollDetailScreen extends StatefulWidget {
  const PayrollDetailScreen({
    super.key,
    required this.record,
    required this.monthDocId,
  });

  final Map<String, dynamic> record;
  final String monthDocId;

  @override
  State<PayrollDetailScreen> createState() => _PayrollDetailScreenState();
}

class _PayrollDetailScreenState extends State<PayrollDetailScreen> {
  late Map<String, dynamic> _record;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _record = Map.from(widget.record);
  }

  bool get _isPaid => (_record['status'] as String?) == 'paid';
  String get _uid => (_record['uid'] as String?) ?? '';

  Future<void> _markAsPaid() async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (adminUid.isEmpty || _uid.isEmpty) return;

    setState(() => _marking = true);
    try {
      await PayrollService.markAsPaid(
        uid: _uid,
        monthYear: widget.monthDocId,
        adminUid: adminUid,
      );
      if (!mounted) return;
      setState(() {
        _record['status'] = 'paid';
        _record['processedBy'] = adminUid;
        _record['processedAt'] = Timestamp.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Marked as paid successfully!'),
          backgroundColor: AdminColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AdminColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (_record['employeeName'] as String?) ?? 'Employee';
    final role = (_record['designation'] as String?) ?? '—';
    final monthLabel = PayrollService.monthDocIdToLabel(widget.monthDocId);

    // Earnings
    final basic = (_record['basicSalary'] as num?)?.toDouble() ?? 0;
    final hra = (_record['hra'] as num?)?.toDouble() ?? 0;
    final conveyance = (_record['conveyance'] as num?)?.toDouble() ?? 0;
    final gross = (_record['grossSalary'] as num?)?.toDouble() ?? 0;

    // Deductions
    final lateDeduction = (_record['lateDeduction'] as num?)?.toDouble() ?? 0;
    final leaveDeduction = (_record['leaveDeduction'] as num?)?.toDouble() ?? 0;
    final pf = (_record['pf'] as num?)?.toDouble() ?? 0;
    final profTax = (_record['professionalTax'] as num?)?.toDouble() ?? 0;
    final totalDeductions = (_record['totalDeductions'] as num?)?.toDouble() ?? 0;

    final netSalary = (_record['netSalary'] as num?)?.toDouble() ?? 0;

    // Processed info
    final processedAt = _record['processedAt'];
    final processedAtStr = processedAt is Timestamp
        ? DateFormat('dd MMM yyyy, hh:mm a').format(processedAt.toDate())
        : null;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.text,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Payroll Detail',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AdminColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee header card
            AdminSurfaceCard(
              child: Row(
                children: [
                  _EmployeeAvatar(
                    name: name,
                    photoUrl: _record['photoUrl'] as String?,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AdminColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role,
                          style: const TextStyle(
                            color: Color(0xFF74849F),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminStatusPill(
                    label: _isPaid ? 'PAID' : 'PENDING',
                    backgroundColor: _isPaid
                        ? const Color(0xFFE2FBE8)
                        : const Color(0xFFFFF0E0),
                    textColor: _isPaid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFCC6D00),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Earnings ────────────────────────────────────────────────────
            _DetailSection(
              title: 'Earnings',
              iconData: Icons.trending_up_rounded,
              iconColor: AdminColors.green,
              iconBg: AdminColors.softGreen,
              rows: [
                _DetailRow(label: 'Basic Salary', value: PayrollService.formatCurrency(basic)),
                _DetailRow(label: 'HRA', value: PayrollService.formatCurrency(hra)),
                _DetailRow(label: 'Conveyance', value: PayrollService.formatCurrency(conveyance)),
              ],
              total: _DetailRow(
                label: 'Gross Salary',
                value: PayrollService.formatCurrency(gross),
                isTotal: true,
                totalColor: AdminColors.green,
              ),
            ),
            const SizedBox(height: 16),
            // ── Deductions ──────────────────────────────────────────────────
            _DetailSection(
              title: 'Deductions',
              iconData: Icons.trending_down_rounded,
              iconColor: AdminColors.red,
              iconBg: AdminColors.softRed,
              rows: [
                _DetailRow(label: 'Late Marks', value: '-${PayrollService.formatCurrency(lateDeduction)}'),
                _DetailRow(label: 'Leave Deduction', value: '-${PayrollService.formatCurrency(leaveDeduction)}'),
                _DetailRow(label: 'Provident Fund', value: '-${PayrollService.formatCurrency(pf)}'),
                _DetailRow(label: 'Professional Tax', value: '-${PayrollService.formatCurrency(profTax)}'),
              ],
              total: _DetailRow(
                label: 'Total Deductions',
                value: '-${PayrollService.formatCurrency(totalDeductions)}',
                isTotal: true,
                totalColor: AdminColors.red,
              ),
            ),
            const SizedBox(height: 20),
            // ── Net Salary ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5B0A), Color(0xFFFF8C42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF5B0A),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET SALARY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Take Home Amount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    PayrollService.formatCurrency(netSalary),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (processedAtStr != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Processed on $processedAtStr',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            // ── Actions ─────────────────────────────────────────────────────
            if (!_isPaid)
              FilledButton.icon(
                onPressed: _marking ? null : _markAsPaid,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _marking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _marking ? 'Marking as Paid…' : 'Mark as Paid',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Section ───────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.rows,
    required this.total,
  });

  final String title;
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final List<_DetailRow> rows;
  final _DetailRow total;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminIconBadge(
                icon: iconData,
                iconColor: iconColor,
                backgroundColor: iconBg,
                size: 40,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AdminColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRow(row),
              )),
          const Divider(color: AdminColors.border, height: 20),
          _buildRow(total),
        ],
      ),
    );
  }

  Widget _buildRow(_DetailRow row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          row.label,
          style: TextStyle(
            color: row.isTotal ? AdminColors.text : const Color(0xFF64748B),
            fontWeight: row.isTotal ? FontWeight.w800 : FontWeight.w500,
            fontSize: row.isTotal ? 15 : 14,
          ),
        ),
        Text(
          row.value,
          style: TextStyle(
            color: row.isTotal ? (row.totalColor ?? AdminColors.text) : AdminColors.text,
            fontWeight: row.isTotal ? FontWeight.w800 : FontWeight.w600,
            fontSize: row.isTotal ? 15 : 14,
          ),
        ),
      ],
    );
  }
}

class _DetailRow {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.totalColor,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? totalColor;
}
