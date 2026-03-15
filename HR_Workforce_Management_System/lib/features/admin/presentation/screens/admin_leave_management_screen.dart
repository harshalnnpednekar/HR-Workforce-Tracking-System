import 'package:flutter/material.dart';

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

  static const _tabs = ['Pending', 'Approved', 'Rejected'];

  static const _requests = [
    _LeaveRequest(
      employeeName: 'Sarah Jenkins',
      role: 'Product Designer · UI/UX',
      type: 'ANNUAL LEAVE',
      typeBackground: Color(0xFFFFF3D8),
      typeColor: Color(0xFFB46B00),
      dateRange: 'Oct 24 - Oct 27',
      duration: '4 Days',
      reason:
          'Attending a family wedding in Chicago. I have finished all my deliverables for the sprint.',
      initials: 'SJ',
      status: 'Pending',
    ),
    _LeaveRequest(
      employeeName: 'Marcus Thompson',
      role: 'Senior Developer · Backend',
      type: 'SICK LEAVE',
      typeBackground: Color(0xFFEAF1FF),
      typeColor: Color(0xFF295BFF),
      dateRange: 'Oct 20 - Oct 21',
      duration: '1 Day',
      reason:
          'High fever and cold. Medical certificate will be uploaded once received.',
      initials: 'MT',
      status: 'Pending',
    ),
    _LeaveRequest(
      employeeName: 'Elena Rodriguez',
      role: 'Marketing Lead',
      type: 'MATERNITY',
      typeBackground: Color(0xFFF4E9FF),
      typeColor: Color(0xFF7C3AED),
      dateRange: 'Nov 01 - Jan 30',
      duration: '90 Days',
      reason:
          'Maternity leave as per company policy. Handover documents are shared with the team.',
      initials: 'ER',
      status: 'Approved',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleRequests = _requests.where((request) {
      final tab = _tabs[_selectedTab];
      return request.status == tab;
    }).toList();

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
          Row(
            children: List.generate(_tabs.length, (index) {
              final selected = index == _selectedTab;
              final count = index == 0 ? '12' : null;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = index),
                  child: Column(
                    children: [
                      Text(
                        _tabs[index],
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
                      if (count != null)
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
                            count,
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
          ),
          const SizedBox(height: 18),
          AdminSurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Viewing all ${_tabs[_selectedTab].toLowerCase()} requests',
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
                  'Filter',
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
          ...visibleRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _LeaveRequestCard(request: request),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequest {
  const _LeaveRequest({
    required this.employeeName,
    required this.role,
    required this.type,
    required this.typeBackground,
    required this.typeColor,
    required this.dateRange,
    required this.duration,
    required this.reason,
    required this.initials,
    required this.status,
  });

  final String employeeName;
  final String role;
  final String type;
  final Color typeBackground;
  final Color typeColor;
  final String dateRange;
  final String duration;
  final String reason;
  final String initials;
  final String status;
}

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({required this.request});

  final _LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == 'Pending';

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
                child: Text(
                  request.initials,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 24,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.employeeName,
                                style: const TextStyle(
                                  color: AdminColors.text,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request.role,
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
                          label: request.type,
                          backgroundColor: request.typeBackground,
                          textColor: request.typeColor,
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
                          text: request.dateRange,
                        ),
                        _MetaItem(
                          icon: Icons.timelapse_rounded,
                          text: request.duration,
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
                  request.reason,
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
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Approve',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
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
                label: request.status.toUpperCase(),
                backgroundColor: request.status == 'Approved'
                    ? const Color(0xFFE2FBE8)
                    : const Color(0xFFFFEDEE),
                textColor: request.status == 'Approved'
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFFF4D4F),
              ),
            ),
        ],
      ),
    );
  }
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
