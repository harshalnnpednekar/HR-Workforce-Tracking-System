import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/attendance_service.dart';
import '../../../../core/services/leave_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/task_service.dart';
import '../../../../core/services/user_service.dart';
import 'shared/employee_dashboard_constants.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({
    super.key,
    required this.userId,
    required this.fullName,
    required this.onLogoutRequested,
    this.onOpenPayroll,
  });

  final String userId;
  final String fullName;
  final VoidCallback onLogoutRequested;
  final VoidCallback? onOpenPayroll;

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  late Future<_ProfileVm> _profileFuture;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EmployeeProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _load();
    }
  }

  void _load() {
    _profileFuture = _buildVm();
  }

  Future<_ProfileVm> _buildVm() async {
    if (widget.userId.isEmpty) {
      return _ProfileVm.empty(widget.fullName);
    }

    final now = DateTime.now();
    final month = DateFormat('yyyy-MM').format(now);

    final user =
        await UserService.getUser(widget.userId) ?? <String, dynamic>{};
    final tasksDone = await TaskService.getCompletedTaskCount(widget.userId);
    final monthlyAttendance = await AttendanceService.getMonthlyAttendance(
      widget.userId,
      month,
    );
    final approvedLeaves = await LeaveService.getApprovedLeaveCountForMonth(
      widget.userId,
      now,
    );
    final unread = await NotificationService.getUnreadCount(widget.userId);

    int present = 0;
    int late = 0;
    int absent = 0;
    double monthHours = 0;

    for (final row in monthlyAttendance) {
      final status = ((row['status'] as String?) ?? '').toLowerCase();
      if (status == 'present' || status == 'done') present++;
      if (status == 'late') late++;
      if (status == 'absent') absent++;

      final h = row['totalHours'];
      if (h is num) monthHours += h.toDouble();
    }

    return _ProfileVm(
      user: user,
      tasksDone: tasksDone,
      monthHours: monthHours,
      present: present,
      late: late,
      absent: absent,
      approvedLeaves: approvedLeaves,
      unreadNotifications: unread,
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    if (widget.userId.isEmpty || _uploadingPhoto) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _uploadingPhoto = true;
    });

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profilePhotos')
          .child('${widget.userId}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await UserService.updateProfile(widget.userId, {'photoUrl': url});
      if (!mounted) return;
      setState(_load);
      showActionMessage(context, 'Profile photo updated');
    } on Exception catch (e) {
      if (!mounted) return;
      showActionMessage(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (email.isEmpty) {
      showActionMessage(context, 'Email not available for password reset.');
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    showActionMessage(context, 'Password reset email sent.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileVm>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final vm = snapshot.data ?? _ProfileVm.empty(widget.fullName);
        final fullName = (vm.user['name'] as String?)?.trim().isNotEmpty == true
            ? (vm.user['name'] as String).trim()
            : widget.fullName;
        final designation =
            (vm.user['designation'] as String?) ??
            (vm.user['designationId'] as String?) ??
            'Software Developer';
        final empId = (vm.user['employeeId'] as String?) ?? 'EQT102';
        final email = (vm.user['email'] as String?) ?? '';
        final phone = (vm.user['phone'] as String?) ?? '--';
        final photoUrl = (vm.user['photoUrl'] as String?) ?? '';
        final joining = _formatDate(vm.user['joiningDate']);
        final manager = (vm.user['manager'] as String?) ?? 'Not available';
        final location = (vm.user['location'] as String?) ?? 'Not available';
        final employmentType =
            ((vm.user['employmentType'] as String?) ?? 'full-time')
                .toUpperCase();
        final casualLeft =
            (vm.user['casualLeaveBalance'] as num?)?.toInt() ??
            (vm.user['casualLeave'] as num?)?.toInt() ??
            0;
        final sickLeft =
            (vm.user['sickLeaveBalance'] as num?)?.toInt() ??
            (vm.user['sickLeave'] as num?)?.toInt() ??
            0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeaderBar(unreadNotifications: vm.unreadNotifications),
              const SizedBox(height: 16),
              _ProfileAvatar(
                fullName: fullName,
                photoUrl: photoUrl,
                uploading: _uploadingPhoto,
                onEditTap: _pickAndUploadPhoto,
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  fullName,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.title,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${designation.toUpperCase()} | $empId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    _ContactRow(icon: Icons.email_rounded, value: email),
                    const SizedBox(height: 6),
                    _ContactRow(icon: Icons.phone_rounded, value: phone),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _ProfileStatCardTasks(done: vm.tasksDone)),
                  const SizedBox(width: 14),
                  Expanded(child: _ProfileStatCardHours(hours: vm.monthHours)),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSummarySection(
                present: vm.present,
                late: vm.late,
                absent: vm.absent,
                approvedLeaves: vm.approvedLeaves,
                casualLeft: casualLeft,
                sickLeft: sickLeft,
              ),
              const SizedBox(height: 16),
              _WorkInfoCard(
                joiningDate: joining,
                manager: manager,
                location: location,
                employmentType: employmentType,
              ),
              const SizedBox(height: 16),
              _DocumentsPayrollActions(onOpenPayroll: widget.onOpenPayroll),
              const SizedBox(height: 16),
              _SettingsList(
                onLogoutTap: widget.onLogoutRequested,
                onChangePasswordTap: () => _sendPasswordReset(email),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(Object? value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM y').format(value.toDate());
    }
    return '--';
  }
}

class _ProfileVm {
  const _ProfileVm({
    required this.user,
    required this.tasksDone,
    required this.monthHours,
    required this.present,
    required this.late,
    required this.absent,
    required this.approvedLeaves,
    required this.unreadNotifications,
  });

  final Map<String, dynamic> user;
  final int tasksDone;
  final double monthHours;
  final int present;
  final int late;
  final int absent;
  final int approvedLeaves;
  final int unreadNotifications;

  factory _ProfileVm.empty(String fullName) {
    return _ProfileVm(
      user: {'name': fullName},
      tasksDone: 0,
      monthHours: 0,
      present: 0,
      late: 0,
      absent: 0,
      approvedLeaves: 0,
      unreadNotifications: 0,
    );
  }
}

class _ProfileHeaderBar extends StatelessWidget {
  const _ProfileHeaderBar({required this.unreadNotifications});

  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_rounded, color: AppColors.title, size: 35),
        const Spacer(),
        Text(
          'My Profile',
          style: GoogleFonts.outfit(
            color: AppColors.title,
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: AppColors.primary,
              ),
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: -4,
                top: -4,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFE94C4C),
                  child: Text(
                    unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.fullName,
    required this.photoUrl,
    required this.uploading,
    required this.onEditTap,
  });

  final String fullName;
  final String photoUrl;
  final bool uploading;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final initial = fullName.trim().isEmpty
        ? 'A'
        : fullName.trim()[0].toUpperCase();

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 72,
            backgroundColor: const Color(0xFFE6D6BE),
            child: ClipOval(
              child: photoUrl.isEmpty
                  ? Text(
                      initial,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppColors.title,
                        fontSize: 28,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: photoUrl,
                      width: 144,
                      height: 144,
                      fit: BoxFit.cover,
                      placeholder: (context, _) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, _, err) => Text(
                        initial,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: AppColors.title,
                          fontSize: 28,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 8,
            child: InkWell(
              onTap: uploading ? null : onEditTap,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: uploading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF7E8EA7), size: 22),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatCardTasks extends StatelessWidget {
  const _ProfileStatCardTasks({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final progress = (done / 30).clamp(0, 1).toDouble();
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'TASKS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$done',
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const TextSpan(
                  text: ' Done',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8EDF5),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% Completion Rate',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCardHours extends StatelessWidget {
  const _ProfileStatCardHours({required this.hours});

  final double hours;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.watch_later_rounded, color: Color(0xFF3A7CE3)),
              SizedBox(width: 8),
              Text(
                'HOURS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${hours.round()}',
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const TextSpan(
                  text: ' Hrs',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "This Month's Total",
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummarySection extends StatelessWidget {
  const _ProfileSummarySection({
    required this.present,
    required this.late,
    required this.absent,
    required this.approvedLeaves,
    required this.casualLeft,
    required this.sickLeft,
  });

  final int present;
  final int late;
  final int absent;
  final int approvedLeaves;
  final int casualLeft;
  final int sickLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUMMARY',
          style: TextStyle(
            color: AppColors.muted,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryChip(
                value: '$present',
                label: 'PRESENT',
                color: const Color(0xFF18A55E),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                value: '$late',
                label: 'LATE',
                color: const Color(0xFFF59A00),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                value: '$absent',
                label: 'ABSENT',
                color: const Color(0xFFE43A46),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                value: '$approvedLeaves',
                label: 'LEAVES',
                color: AppColors.primary,
                highlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmallLeavePill(
                title: 'CASUAL',
                value: '$casualLeft Left',
                icon: Icons.calendar_today_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallLeavePill(
                title: 'SICK',
                value: '$sickLeft Left',
                icon: Icons.medical_services_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.value,
    required this.label,
    required this.color,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF3E5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallLeavePill extends StatelessWidget {
  const _SmallLeavePill({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFFB8C3D6)),
        ],
      ),
    );
  }
}

class _WorkInfoCard extends StatelessWidget {
  const _WorkInfoCard({
    required this.joiningDate,
    required this.manager,
    required this.location,
    required this.employmentType,
  });

  final String joiningDate;
  final String manager;
  final String location;
  final String employmentType;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Work Information',
                style: GoogleFonts.outfit(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WorkLine(
            label: 'Joining Date',
            value: joiningDate,
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 10),
          _WorkLine(
            label: 'Manager',
            value: manager,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 10),
          _WorkLine(
            label: 'Location',
            value: location,
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: _WorkLine(
                  label: 'Type',
                  value: '',
                  icon: Icons.badge_rounded,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF6E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  employmentType,
                  style: const TextStyle(
                    color: Color(0xFF1A9B66),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkLine extends StatelessWidget {
  const _WorkLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9AABC1), size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 18),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              color: AppColors.title,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _DocumentsPayrollActions extends StatelessWidget {
  const _DocumentsPayrollActions({this.onOpenPayroll});

  final VoidCallback? onOpenPayroll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DOCUMENTS & PAYROLL',
          style: TextStyle(
            color: AppColors.muted,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenPayroll,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.visibility_rounded,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Salary Slip',
                  style: TextStyle(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onOpenPayroll,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text(
                  'Payslip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.onLogoutTap,
    required this.onChangePasswordTap,
  });

  final VoidCallback onLogoutTap;
  final VoidCallback onChangePasswordTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SETTINGS',
          style: TextStyle(
            color: AppColors.muted,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        BaseCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.lock_rounded,
                label: 'Change Password',
                onTap: onChangePasswordTap,
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              const _SettingRow(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              _SettingRow(
                icon: Icons.logout_rounded,
                label: 'Logout',
                danger: true,
                onTap: onLogoutTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => showActionMessage(context, '$label tapped.'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFFEEF0)
                    : const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: danger
                    ? const Color(0xFFE5394F)
                    : const Color(0xFF798CA8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: danger ? const Color(0xFFE5394F) : AppColors.title,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!danger)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFA2AFC2)),
          ],
        ),
      ),
    );
  }
}
