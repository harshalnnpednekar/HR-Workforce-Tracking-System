import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/admin_leave_management_service.dart';
import '../widgets/admin_ui_kit.dart';

class AdminLeaveManagementScreen extends StatefulWidget {
  const AdminLeaveManagementScreen({super.key});

  @override
  State<AdminLeaveManagementScreen> createState() =>
      _AdminLeaveManagementScreenState();
}

class _AdminLeaveManagementScreenState
    extends State<AdminLeaveManagementScreen> {
  int _selectedTab = 0;
  final Set<String> _busyIds = <String>{};

  static const _tabs = ['pending', 'approved', 'rejected'];

  Future<void> _handleApprove(Map<String, dynamic> leave) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null || adminUid.isEmpty) {
      return;
    }

    final leaveId = leave['id'] as String?;
    if (leaveId == null || leaveId.isEmpty) {
      return;
    }

    final employeeUid = (leave['uid'] as String?) ?? '';
    if (employeeUid.isEmpty) {
      return;
    }

    final totalDays = (leave['totalDays'] as num?)?.toInt() ?? 0;
    final leaveType = (leave['leaveType'] as String?) ?? 'leave';
    final employeeName = (leave['employeeName'] as String?) ?? 'Employee';

    setState(() => _busyIds.add(leaveId));
    try {
      await AdminLeaveManagementService.approveLeave(
        leaveId: leaveId,
        adminUid: adminUid,
        employeeUid: employeeUid,
        employeeName: employeeName,
        leaveType: leaveType,
        totalDays: totalDays,
        dateRangeLabel: _dateRange(leave),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave approved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to approve leave.')));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(leaveId));
      }
    }
  }

  Future<void> _handleReject(Map<String, dynamic> leave) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null || adminUid.isEmpty) {
      return;
    }

    final leaveId = leave['id'] as String?;
    if (leaveId == null || leaveId.isEmpty) {
      return;
    }

    final employeeUid = (leave['uid'] as String?) ?? '';
    if (employeeUid.isEmpty) {
      return;
    }

    final employeeName = (leave['employeeName'] as String?) ?? 'Employee';
    final leaveType = (leave['leaveType'] as String?) ?? 'leave';

    setState(() => _busyIds.add(leaveId));
    try {
      await AdminLeaveManagementService.rejectLeave(
        leaveId: leaveId,
        adminUid: adminUid,
        employeeUid: employeeUid,
        employeeName: employeeName,
        leaveType: leaveType,
        dateRangeLabel: _dateRange(leave),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave rejected.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to reject leave.')));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(leaveId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatus = _tabs[_selectedTab];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<int>(
            stream: AdminLeaveManagementService.streamPendingCount(),
            builder: (context, pendingSnapshot) {
              final pendingCount = pendingSnapshot.data ?? 0;
              return Row(
                children: List.generate(_tabs.length, (index) {
                  final tab = _tabs[index];
                  final selected = index == _selectedTab;
                  final isPending = tab == 'pending';
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Column(
                        children: [
                          Text(
                            _titleCase(tab),
                            style: TextStyle(
                              color: selected
                                  ? AdminColors.primary
                                  : const Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFE7DA)
                                    : const Color(0xFFF3F5F8),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                pendingCount.toString(),
                                style: TextStyle(
                                  color: selected
                                      ? AdminColors.primary
                                      : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 22),
                          const SizedBox(height: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 3,
                            color: selected
                                ? AdminColors.primary
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 18),
          AdminSurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Viewing all ${_titleCase(selectedStatus).toLowerCase()} requests',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.filter_alt_outlined,
                  color: AdminColors.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Live',
                  style: TextStyle(
                    color: AdminColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminLeaveManagementService.streamLeavesByStatus(
              selectedStatus,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const AdminSurfaceCard(
                  child: Text(
                    'Failed to load leave requests.',
                    style: TextStyle(color: Color(0xFF991B1B)),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const AdminSurfaceCard(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final requests = snapshot.data ?? const [];
              if (requests.isEmpty) {
                return AdminSurfaceCard(
                  child: Text(
                    'No ${_titleCase(selectedStatus).toLowerCase()} requests.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return Column(
                children: requests
                    .map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _LeaveRequestCard(
                          request: request,
                          busy: _busyIds.contains(request['id']),
                          onApprove: () => _handleApprove(request),
                          onReject: () => _handleReject(request),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  String _dateRange(Map<String, dynamic> leave) {
    final from = (leave['fromDate'] as Timestamp?)?.toDate();
    final to = (leave['toDate'] as Timestamp?)?.toDate();
    if (from == null || to == null) {
      return '-';
    }
    final fmt = DateFormat('MMM dd');
    return '${fmt.format(from)} - ${fmt.format(to)}';
  }
}

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = ((request['status'] as String?) ?? 'pending').toLowerCase();
    final isPending = status == 'pending';

    final leaveType = (request['leaveType'] as String?) ?? 'casual';
    final leaveTypeMeta = _leaveTypeMeta(leaveType);

    final name = (request['employeeName'] as String?) ?? 'Employee';
    final designation = (request['designation'] as String?) ?? 'Employee';
    final department = (request['department'] as String?) ?? '';
    final photoUrl = (request['photoUrl'] as String?) ?? '';
    final fromDate = (request['fromDate'] as Timestamp?)?.toDate();
    final toDate = (request['toDate'] as Timestamp?)?.toDate();
    final reason = (request['reason'] as String?) ?? '-';
    final totalDays = (request['totalDays'] as num?)?.toInt() ?? 0;

    final dateFmt = DateFormat('MMM dd');
    final dateRange = (fromDate != null && toDate != null)
        ? '${dateFmt.format(fromDate)} - ${dateFmt.format(toDate)}'
        : '-';

    final initials = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return AdminSurfaceCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: photoUrl.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: AdminColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          photoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            initials,
                            style: const TextStyle(
                              color: AdminColors.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AdminColors.text,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                department.isEmpty
                                    ? designation
                                    : '$designation · $department',
                                style: const TextStyle(
                                  color: Color(0xFF73839E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AdminStatusPill(
                          label: leaveType.toUpperCase(),
                          backgroundColor: leaveTypeMeta.background,
                          textColor: leaveTypeMeta.text,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _MetaItem(
                          icon: Icons.calendar_today_rounded,
                          text: dateRange,
                        ),
                        _MetaItem(
                          icon: Icons.timelapse_rounded,
                          text: '$totalDays Days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REASON',
                  style: TextStyle(
                    color: Color(0xFF9AA9C0),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reason,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Approve',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onReject,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE9EEF5),
                      foregroundColor: const Color(0xFF475569),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: AdminStatusPill(
                label: status.toUpperCase(),
                backgroundColor: status == 'approved'
                    ? const Color(0xFFE2FBE8)
                    : const Color(0xFFFFEDEE),
                textColor: status == 'approved'
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFFF4D4F),
              ),
            ),
        ],
      ),
    );
  }

  _LeaveTypeMeta _leaveTypeMeta(String leaveType) {
    switch (leaveType.trim().toLowerCase()) {
      case 'annual':
        return const _LeaveTypeMeta(
          background: Color(0xFFFFF3D8),
          text: Color(0xFFB46B00),
        );
      case 'sick':
        return const _LeaveTypeMeta(
          background: Color(0xFFEAF1FF),
          text: Color(0xFF295BFF),
        );
      case 'maternity':
        return const _LeaveTypeMeta(
          background: Color(0xFFF4E9FF),
          text: Color(0xFF7C3AED),
        );
      case 'casual':
      default:
        return const _LeaveTypeMeta(
          background: Color(0xFFE2FBE8),
          text: Color(0xFF15803D),
        );
    }
  }
}

class _LeaveTypeMeta {
  const _LeaveTypeMeta({required this.background, required this.text});

  final Color background;
  final Color text;
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
