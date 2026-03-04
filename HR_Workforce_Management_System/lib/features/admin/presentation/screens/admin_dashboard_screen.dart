import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/admin_metric_cards.dart';
import '../widgets/workforce_heatmap.dart';

/// AdminDashboardScreen serves as the dashboard for administrator tasks.
///
/// Features a responsive layout (BottomNavigationBar on Mobile, NavigationRail on Desktop)
/// Displays real-time telemetry and a live workforce heatmap.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _OverviewTab(),
    const Center(child: Text('Delegation (Coming Soon)')),
    const Center(child: Text('HR/Payroll (Coming Soon)')),
  ];

  final List<NavigationDestination> _mobileDestinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Overview',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_ind_outlined),
      selectedIcon: Icon(Icons.assignment_ind),
      label: 'Delegation',
    ),
    NavigationDestination(
      icon: Icon(Icons.payments_outlined),
      selectedIcon: Icon(Icons.payments),
      label: 'HR/Payroll',
    ),
  ];

  final List<NavigationRailDestination> _desktopDestinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Overview'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.assignment_ind_outlined),
      selectedIcon: Icon(Icons.assignment_ind),
      label: Text('Delegation'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.payments_outlined),
      selectedIcon: Icon(Icons.payments),
      label: Text('HR/Payroll'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).user;
    final userName = currentUser?.name ?? 'Admin';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Scaffold(
            appBar: _buildAppBar(context, userName, ref),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: _desktopDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          );
        }

        // Mobile Layout
        return Scaffold(
          appBar: _buildAppBar(context, userName, ref),
          body: _pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: _mobileDestinations,
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, String userName, WidgetRef ref) {
    return AppBar(
      title: Text(
        'Command Center: $userName',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Log Out',
          onPressed: () {
            ref.read(authControllerProvider.notifier).logout();
            context.go('/login');
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          AdminMetricCardsGrid(),
          SizedBox(height: 24),
          WorkforceHeatmap(),
          SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }
}
