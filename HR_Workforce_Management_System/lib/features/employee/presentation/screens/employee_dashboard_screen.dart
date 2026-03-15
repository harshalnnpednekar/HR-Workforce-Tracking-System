import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import 'employee_attendance_screen.dart';
import 'employee_home_screen.dart';
import 'employee_leaves_screen.dart';
import 'employee_payroll_screen.dart';
import 'employee_profile_screen.dart';
import 'shared/employee_dashboard_constants.dart';

/// EmployeeDashboardScreen serves as the dashboard for employee tasks.
class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState
    extends ConsumerState<EmployeeDashboardScreen> {
  int _selectedIndex = 0;

  static const List<_NavItemData> _navItems = [
    _NavItemData(label: 'Home', icon: Icons.home_rounded),
    _NavItemData(label: 'Attendance', icon: Icons.fact_check_rounded),
    _NavItemData(label: 'Leaves', icon: Icons.calendar_today_rounded),
    _NavItemData(label: 'Payroll', icon: Icons.account_balance_wallet_rounded),
    _NavItemData(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).user;
    final userName = currentUser?.name ?? 'Alex';
    final trimmedUserName = userName.trim();
    final firstName = trimmedUserName.isEmpty
        ? 'Alex'
        : trimmedUserName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            EmployeeHomePage(name: firstName),
            const EmployeeAttendancePage(),
            const EmployeeLeavesPage(),
            const EmployeePayrollPage(),
            EmployeeProfilePage(
              fullName: trimmedUserName.isEmpty ? 'Alex' : trimmedUserName,
              onLogoutRequested: _handleLogout,
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () => showActionMessage(
                context,
                'Create leave request coming next.',
              ),
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 34),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _EmployeeBottomNavigation(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _EmployeeBottomNavigation extends StatelessWidget {
  const _EmployeeBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<_NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 86,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final active = index == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(bottom: 4),
                        height: 4,
                        width: active ? 40 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Icon(
                        item.icon,
                        size: 26,
                        color: active
                            ? AppColors.primary
                            : const Color(0xFF95A4BD),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label.toUpperCase(),
                          maxLines: 1,
                          style: TextStyle(
                            color: active
                                ? AppColors.primary
                                : const Color(0xFF95A4BD),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
