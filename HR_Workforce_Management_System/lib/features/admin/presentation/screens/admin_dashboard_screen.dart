import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/admin_navigation.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/admin_ui_kit.dart';
import 'admin_profile_screen.dart';
import 'admin_employees_screen.dart';
import 'admin_home_screen.dart';
import 'admin_hr_policy_screen.dart';
import 'admin_leave_management_screen.dart';
import 'admin_payroll_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AdminSection _currentSection = AdminSection.dashboard;

  void _selectSection(AdminSection section) {
    setState(() {
      _currentSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).user;
    final userName = currentUser?.name.trim().isNotEmpty == true
        ? currentUser!.name.trim()
        : 'HR Admin';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminColors.background,
      drawer: AdminNavigationDrawer(
        currentSection: _currentSection,
        onSectionSelected: _selectSection,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _AdminTopBar(
              userName: userName,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onProfileTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                );
              },
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_currentSection),
                  child: _buildCurrentPage(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AdminBottomBar(
        currentSection: _currentSection,
        onSectionSelected: _selectSection,
      ),
    );
  }

  Widget _buildCurrentPage() {
    return switch (_currentSection) {
      AdminSection.dashboard => AdminHomeScreen(
        onSectionSelected: _selectSection,
      ),
      AdminSection.employees => const AdminEmployeesScreen(),
      AdminSection.leaves => const AdminLeaveManagementScreen(),
      AdminSection.payroll => const AdminPayrollScreen(),
      AdminSection.hrPolicy => const AdminHrPolicyScreen(),
      AdminSection.reports => const AdminReportsScreen(),
    };
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.userName,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  final String userName;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final initials = userName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(
              Icons.menu_rounded,
              color: AdminColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'myHR Admin',
              style: TextStyle(
                color: AdminColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFF334155),
                  size: 24,
                ),
              ),
              Positioned(
                top: 4,
                right: 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D1A),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6D9),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                initials.isEmpty ? 'HR' : initials,
                style: const TextStyle(
                  color: AdminColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  const _AdminBottomBar({
    required this.currentSection,
    required this.onSectionSelected,
  });

  final AdminSection currentSection;
  final ValueChanged<AdminSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 82,
          child: Row(
            children: bottomAdminSections.map((section) {
              final selected = section == currentSection;
              return Expanded(
                child: InkWell(
                  onTap: () => onSectionSelected(section),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        section.icon,
                        size: 27,
                        color: selected
                            ? AdminColors.primary
                            : const Color(0xFF9AA8BE),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.label.toUpperCase(),
                        style: TextStyle(
                          color: selected
                              ? AdminColors.primary
                              : const Color(0xFF9AA8BE),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
