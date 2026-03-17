import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/admin_ui_kit.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).user;
    final fullName = currentUser?.name.trim().isNotEmpty == true
        ? currentUser!.name.trim()
        : 'HR Admin';
    final department = currentUser?.department?.trim();
    final roleLabel = department != null && department.isNotEmpty
        ? department
        : 'Administrator';

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AdminColors.text),
        ),
        title: const Text(
          'Admin Profile',
          style: TextStyle(
            color: AdminColors.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Center(child: _ProfileAvatar(name: fullName)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  fullName,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'HR Manager at Equitec',
                  style: TextStyle(
                    color: AdminColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEE4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: const TextStyle(
                      color: AdminColors.primary,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AdminColors.border, height: 1),
              const SizedBox(height: 18),
              const _SectionLabel(label: 'ACCOUNT SETTINGS'),
              const SizedBox(height: 10),
              const _ProfileActionTile(
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
              ),
              const SizedBox(height: 8),
              const _ProfileActionTile(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Manage your security credentials',
              ),
              const SizedBox(height: 18),
              const _SectionLabel(label: 'PREFERENCES'),
              const SizedBox(height: 10),
              const _ProfileActionTile(
                icon: Icons.settings,
                title: 'App Settings',
                subtitle: 'Notifications, display, and more',
              ),
              const SizedBox(height: 8),
              const _ProfileActionTile(
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'FAQs and contact support',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _logout(context, ref),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFFD8E0EA)),
                  foregroundColor: const Color(0xFFFF4D4F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'EQUITEC HR PORTAL · VERSION 2.4.0',
                  style: TextStyle(
                    color: Color(0xFF9AA8BE),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFFB0B8C5), width: 2),
            gradient: const LinearGradient(
              colors: [Color(0xFFE7EBF1), Color(0xFFD6DCE6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Text(
              initials.isEmpty ? 'HR' : initials,
              style: const TextStyle(
                color: AdminColors.text,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdminColors.primary,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF8A99AF),
        fontSize: 12,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE6),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AdminColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7D8BA2),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA8BE)),
        ],
      ),
    );
  }
}
