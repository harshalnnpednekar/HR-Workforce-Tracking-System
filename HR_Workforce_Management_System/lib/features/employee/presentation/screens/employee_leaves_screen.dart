import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeLeavesPage extends StatelessWidget {
  const EmployeeLeavesPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 136),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          InnerPageHeader(title: 'Leave Management'),
          SizedBox(height: 20),
          _LeaveBalanceSection(),
          SizedBox(height: 20),
          _LeaveRequestCard(),
          SizedBox(height: 24),
          _LeaveHistorySection(),
        ],
      ),
    );
  }
}

class _LeaveBalanceSection extends StatelessWidget {
  const _LeaveBalanceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'YOUR BALANCES',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              'View Details',
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 124,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _LeaveBalanceCard(
                title: 'Casual Leave',
                ratio: '4/12',
                icon: Icons.event_note_rounded,
              ),
              SizedBox(width: 12),
              _LeaveBalanceCard(
                title: 'Sick Leave',
                ratio: '2/10',
                icon: Icons.medical_services_rounded,
              ),
              SizedBox(width: 12),
              _LeaveBalanceCard(
                title: 'Earned Leave',
                ratio: '15/20',
                icon: Icons.flight_takeoff_rounded,
                soft: true,
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: soft ? const Color(0xFFF2F5FA) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3DCC0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFD8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            ratio,
            style: GoogleFonts.outfit(
              color: AppColors.title,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard();

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
          FormFieldBox(
            hintText: 'Select leave type',
            readOnly: true,
            onTap: () =>
                showActionMessage(context, 'Leave type picker coming next.'),
            trailing: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8A9AB3),
            ),
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
                child: FormFieldBox(
                  hintText: 'mm/dd/yyyy',
                  readOnly: true,
                  onTap: () => showActionMessage(
                    context,
                    'From date picker coming next.',
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FormFieldBox(
                  hintText: 'mm/dd/yyyy',
                  readOnly: true,
                  onTap: () =>
                      showActionMessage(context, 'To date picker coming next.'),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const FieldLabel(text: 'Reason'),
          const SizedBox(height: 8),
          const FormFieldBox(
            hintText: 'Briefly explain the reason...',
            height: 96,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => showActionMessage(
                context,
                'Leave request submitted (UI demo).',
              ),
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
              child: const Text('Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveHistorySection extends StatelessWidget {
  const _LeaveHistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Leave History',
              style: GoogleFonts.outfit(
                color: AppColors.title,
                fontWeight: FontWeight.w700,
                fontSize: 26,
              ),
            ),
            const Spacer(),
            const Text(
              'Filter',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.filter_list_rounded, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        const _LeaveHistoryItem(
          title: 'Sick Leave',
          date: 'Oct 12 - Oct 14 • 3 Days',
          status: 'APPROVED',
          statusBg: Color(0xFFDEF5E7),
          statusText: Color(0xFF1A9A61),
          icon: Icons.check_rounded,
          iconColor: Color(0xFF1A9A61),
          iconBg: Color(0xFFE8F7EE),
        ),
        const SizedBox(height: 10),
        const _LeaveHistoryItem(
          title: 'Casual Leave',
          date: 'Nov 05 - Nov 05 • 1 Day',
          status: 'PENDING',
          statusBg: Color(0xFFFFF1DA),
          statusText: Color(0xFFBD7507),
          icon: Icons.more_horiz_rounded,
          iconColor: Color(0xFFBD7507),
          iconBg: Color(0xFFFFF5E3),
        ),
        const SizedBox(height: 10),
        const _LeaveHistoryItem(
          title: 'Earned Leave',
          date: 'Sep 20 - Sep 25 • 5 Days',
          status: 'REJECTED',
          statusBg: Color(0xFFFCE4EA),
          statusText: Color(0xFFD5264A),
          icon: Icons.close_rounded,
          iconColor: Color(0xFFD5264A),
          iconBg: Color(0xFFFEEFF2),
        ),
      ],
    );
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
