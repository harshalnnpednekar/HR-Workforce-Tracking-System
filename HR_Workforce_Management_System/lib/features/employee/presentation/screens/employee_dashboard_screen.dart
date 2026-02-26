import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/attendance_card.dart';
import '../widgets/quick_stats_section.dart';
import 'my_tasks_view.dart';
import 'profile_view.dart';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, John Doe',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Welcome back to work!',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?u=john',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF1F5F9),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // Home Tab
            RefreshIndicator(
              displacement: 100,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
                child: Column(
                  children: const [
                    AttendanceCard(),
                    SizedBox(height: 32),
                    QuickStatsSection(),
                  ],
                ),
              ),
            ),
            // My Tasks Tab
            const MyTasksView(),
            // Profile Tab
            const ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'My Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
