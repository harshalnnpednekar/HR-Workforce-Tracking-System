import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';
import '../widgets/payroll_summary_card.dart';
import '../widgets/profile_menu.dart';

/// The ProfileView assembles the profile header, payroll summary, and menu.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 48),
      child: Column(
        children: const [
          ProfileHeader(),
          SizedBox(height: 40),
          PayrollSummaryCard(),
          SizedBox(height: 32),
          ProfileMenu(),
          SizedBox(height: 48), // Bottom breathing room
        ],
      ),
    );
  }
}
