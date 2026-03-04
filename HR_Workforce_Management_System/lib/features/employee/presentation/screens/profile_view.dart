import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/payroll_summary_card.dart';
import '../widgets/profile_menu.dart';

/// The ProfileView assembles the profile header, payroll summary, and menu.
///
/// Reads the authenticated user from [authControllerProvider] and passes
/// dynamic values to [ProfileHeader].
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).user;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 48),
      child: Column(
        children: [
          ProfileHeader(
            name: currentUser?.name ?? 'User',
            role: currentUser?.role ?? 'employee',
            id: currentUser?.id ?? 'N/A',
          ),
          const SizedBox(height: 40),
          const PayrollSummaryCard(),
          const SizedBox(height: 32),
          const ProfileMenu(),
          const SizedBox(height: 48), // Bottom breathing room
        ],
      ),
    );
  }
}
