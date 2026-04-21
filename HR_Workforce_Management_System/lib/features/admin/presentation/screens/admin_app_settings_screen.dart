import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/user_service.dart';
import '../widgets/admin_ui_kit.dart';

class AdminAppSettingsScreen extends ConsumerStatefulWidget {
  const AdminAppSettingsScreen({super.key});

  @override
  ConsumerState<AdminAppSettingsScreen> createState() => _AdminAppSettingsScreenState();
}

class _AdminAppSettingsScreenState extends ConsumerState<AdminAppSettingsScreen> {
  late Map<String, dynamic> _notifications;
  late Map<String, dynamic> _display;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    final settings = user?.settings;
    
    _notifications = Map<String, dynamic>.from(settings?['notifications'] ?? {
      'leaveRequests': true,
      'lateArrivals': true,
      'payrollReminders': true,
    });
    
    _display = Map<String, dynamic>.from(settings?['display'] ?? {
      'showEmployeePhotos': true,
    });
  }

  Future<void> _updateSetting(String section, String key, bool value) async {
    setState(() {
      if (section == 'notifications') {
        _notifications[key] = value;
      } else {
        _display[key] = value;
      }
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await UserService.updateProfile(uid, {
        'settings.$section.$key': value,
      });
      // Optionally reload user to sync provider
      await ref.read(authControllerProvider.notifier).loadUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving setting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AdminColors.text),
        ),
        title: const Text(
          'App Settings',
          style: TextStyle(
            color: AdminColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('NOTIFICATIONS'),
            const SizedBox(height: 12),
            AdminSurfaceCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Leave request alerts',
                    _notifications['leaveRequests'] ?? true,
                    (v) => _updateSetting('notifications', 'leaveRequests', v),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    'Late arrival alerts',
                    _notifications['lateArrivals'] ?? true,
                    (v) => _updateSetting('notifications', 'lateArrivals', v),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    'Payroll reminders',
                    _notifications['payrollReminders'] ?? true,
                    (v) => _updateSetting('notifications', 'payrollReminders', v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('DISPLAY'),
            const SizedBox(height: 12),
            AdminSurfaceCard(
              child: _buildSwitchTile(
                'Show employee photos in list',
                _display['showEmployeePhotos'] ?? true,
                (v) => _updateSetting('display', 'showEmployeePhotos', v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF8A99AF),
        fontSize: 13,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: AdminColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFFE65100),
      ),
    );
  }
}
