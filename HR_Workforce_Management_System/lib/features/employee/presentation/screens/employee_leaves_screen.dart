import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/leave_service.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeLeavesPage extends StatefulWidget {
  const EmployeeLeavesPage({super.key, required this.userId});

  final String userId;

  @override
  State<EmployeeLeavesPage> createState() => _EmployeeLeavesPageState();
}

class _EmployeeLeavesPageState extends State<EmployeeLeavesPage> {
  late Future<Map<String, int>> _balancesFuture;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  @override
  void didUpdateWidget(covariant EmployeeLeavesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadBalances();
    }
  }

  void _loadBalances() {
    if (widget.userId.isEmpty) {
      _balancesFuture = Future.value({'casual': 0, 'sick': 0, 'earned': 0});
      return;
    }
    _balancesFuture = LeaveService.getUserLeaveBalances(widget.userId);
  }

  void _onSubmitted() {
    setState(_loadBalances);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 136),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InnerPageHeader(title: 'Leave Management'),
          const SizedBox(height: 20),
          _LeaveBalanceSection(balancesFuture: _balancesFuture),
          const SizedBox(height: 20),
          _LeaveRequestCard(
            userId: widget.userId,
            balancesFuture: _balancesFuture,
            onSubmitted: _onSubmitted,
          ),
          const SizedBox(height: 24),
          _LeaveHistorySection(userId: widget.userId),
        ],
      ),
    );
  }
}

class _LeaveBalanceSection extends StatelessWidget {
  const _LeaveBalanceSection({required this.balancesFuture});

  final Future<Map<String, int>> balancesFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'YOUR BALANCES',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  'View Details',
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<Map<String, int>>(
          future: balancesFuture,
          builder: (context, snapshot) {
            final balances =
                snapshot.data ?? {'casual': 0, 'sick': 0, 'earned': 0};

            const casualTotal = 12;
            const sickTotal = 10;
            const earnedTotal = 20;

            final casualUsed = (casualTotal - (balances['casual'] ?? 0)).clamp(
              0,
              casualTotal,
            );
            final sickUsed = (sickTotal - (balances['sick'] ?? 0)).clamp(
              0,
              sickTotal,
            );
            final earnedUsed = (earnedTotal - (balances['earned'] ?? 0)).clamp(
              0,
              earnedTotal,
            );

            return SizedBox(
              height: 132,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _LeaveBalanceCard(
                    title: 'Casual Leave',
                    ratio: '$casualUsed/$casualTotal',
                    icon: Icons.event_note_rounded,
                  ),
                  const SizedBox(width: 12),
                  _LeaveBalanceCard(
                    title: 'Sick Leave',
                    ratio: '$sickUsed/$sickTotal',
                    icon: Icons.medical_services_rounded,
                  ),
                  const SizedBox(width: 12),
                  _LeaveBalanceCard(
                    title: 'Earned Leave',
                    ratio: '$earnedUsed/$earnedTotal',
                    icon: Icons.flight_takeoff_rounded,
                    soft: true,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({
    required this.title,
    required this.ratio,
    required this.icon,
    this.soft = false,
  });

  final String title;
  final String ratio;
  final IconData icon;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: soft ? const Color(0xFFF2F5FA) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3DCC0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFD8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            ratio,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: AppColors.title,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends StatefulWidget {
  const _LeaveRequestCard({
    required this.userId,
    required this.balancesFuture,
    required this.onSubmitted,
  });

  final String userId;
  final Future<Map<String, int>> balancesFuture;
  final VoidCallback onSubmitted;

  @override
  State<_LeaveRequestCard> createState() => _LeaveRequestCardState();
}

class _LeaveRequestCardState extends State<_LeaveRequestCard> {
  final _reasonController = TextEditingController();
  String? _leaveType;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = DateTime(now.year + 2, 12, 31);
    final initialDate = isFrom
        ? (_fromDate ?? now)
        : (_toDate ?? _fromDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (widget.userId.isEmpty) {
      showActionMessage(
        context,
        'User session unavailable. Please login again.',
      );
      return;
    }

    if (_leaveType == null || _fromDate == null || _toDate == null) {
      showActionMessage(context, 'Please complete leave type and dates.');
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      showActionMessage(context, 'To date must be after from date.');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      showActionMessage(context, 'Please enter a reason.');
      return;
    }

    try {
      final totalDays = _toDate!.difference(_fromDate!).inDays + 1;
      final balances = await widget.balancesFuture;
      if (!mounted) return;
      final available = balances[_leaveType!] ?? 0;

      if (totalDays > available) {
        showActionMessage(context, 'Insufficient $_leaveType leave balance.');
        return;
      }

      setState(() {
        _submitting = true;
      });

      await LeaveService.submitLeave(
        uid: widget.userId,
        leaveType: _leaveType!,
        fromDate: _fromDate!,
        toDate: _toDate!,
        totalDays: totalDays,
        reason: reason,
      );

      if (!mounted) return;
      showActionMessage(context, 'Leave request submitted');
      setState(() {
        _leaveType = null;
        _fromDate = null;
        _toDate = null;
        _reasonController.clear();
      });
      widget.onSubmitted();
    } on Exception catch (e) {
      if (!mounted) return;
      showActionMessage(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Leave',
            style: GoogleFonts.outfit(
              color: AppColors.title,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 16),
          const FieldLabel(text: 'Leave Type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _leaveType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
            hint: const Text('Select leave type'),
            items: const [
              DropdownMenuItem(value: 'casual', child: Text('Casual')),
              DropdownMenuItem(value: 'sick', child: Text('Sick')),
              DropdownMenuItem(value: 'earned', child: Text('Earned')),
            ],
            onChanged: (value) => setState(() => _leaveType = value),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: FieldLabel(text: 'From Date')),
              SizedBox(width: 12),
              Expanded(child: FieldLabel(text: 'To Date')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateBox(
                  label: _fromDate == null
                      ? 'mm/dd/yyyy'
                      : DateFormat('MM/dd/yyyy').format(_fromDate!),
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateBox(
                  label: _toDate == null
                      ? 'mm/dd/yyyy'
                      : DateFormat('MM/dd/yyyy').format(_toDate!),
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const FieldLabel(text: 'Reason'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Briefly explain the reason...',
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF7F8EA7), fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.calendar_today_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LeaveHistorySection extends StatelessWidget {
  const _LeaveHistorySection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Leave History',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Filter',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.filter_list_rounded, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        if (userId.isEmpty)
          const _EmptyLeaveHistory()
        else
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: LeaveService.streamMyLeaves(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const BaseCard(
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.muted),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Unable to load leave history. Please refresh.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final items = snapshot.data ?? const <Map<String, dynamic>>[];
              if (items.isEmpty) {
                return const _EmptyLeaveHistory();
              }

              return Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final status = ((item['status'] as String?) ?? 'pending')
                      .toLowerCase();
                  final leaveType = ((item['leaveType'] as String?) ?? 'Leave')
                      .trim();
                  final fromDate = _readDate(item['fromDate']);
                  final toDate = _readDate(item['toDate']);
                  final totalDays = (item['totalDays'] as num?)?.toInt() ?? 0;

                  final dateLabel = fromDate == null || toDate == null
                      ? '$totalDays day(s)'
                      : '${DateFormat('MMM dd').format(fromDate)} - ${DateFormat('MMM dd').format(toDate)} • $totalDays Day${totalDays == 1 ? '' : 's'}';

                  final colors = _statusColors(status);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 10,
                    ),
                    child: _LeaveHistoryItem(
                      title: _titleCase(leaveType),
                      date: dateLabel,
                      status: status.toUpperCase(),
                      statusBg: colors.$1,
                      statusText: colors.$2,
                      icon: colors.$3,
                      iconColor: colors.$2,
                      iconBg: colors.$4,
                    ),
                  );
                }),
              );
            },
          ),
      ],
    );
  }

  static DateTime? _readDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    return null;
  }

  static (Color, Color, IconData, Color) _statusColors(String status) {
    switch (status) {
      case 'approved':
        return (
          const Color(0xFFDEF5E7),
          const Color(0xFF1A9A61),
          Icons.check_rounded,
          const Color(0xFFE8F7EE),
        );
      case 'rejected':
        return (
          const Color(0xFFFCE4EA),
          const Color(0xFFD5264A),
          Icons.close_rounded,
          const Color(0xFFFEEFF2),
        );
      default:
        return (
          const Color(0xFFFFF1DA),
          const Color(0xFFBD7507),
          Icons.more_horiz_rounded,
          const Color(0xFFFFF5E3),
        );
    }
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class _LeaveHistoryItem extends StatelessWidget {
  const _LeaveHistoryItem({
    required this.title,
    required this.date,
    required this.status,
    required this.statusBg,
    required this.statusText,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final String date;
  final String status;
  final Color statusBg;
  final Color statusText;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaveHistory extends StatelessWidget {
  const _EmptyLeaveHistory();

  @override
  Widget build(BuildContext context) {
    return const BaseCard(
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: AppColors.muted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No leave requests yet.',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
