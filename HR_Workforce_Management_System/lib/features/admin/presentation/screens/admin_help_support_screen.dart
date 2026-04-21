import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/admin_ui_kit.dart';

class AdminHelpSupportScreen extends StatelessWidget {
  const AdminHelpSupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          'Help & Support',
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
            _buildSectionHeader('FAQ'),
            const SizedBox(height: 12),
            AdminSurfaceCard(
              child: Column(
                children: [
                  _buildFAQTile(
                    'How do I add a new employee?',
                    'Go to the Dashboard, click on "Employees", and tap the "+" button to add a new employee profile.',
                  ),
                  const Divider(height: 1),
                  _buildFAQTile(
                    'How do I approve a leave request?',
                    'Navigate to the "Leaves" section. You can view pending requests and tap "Approve" or "Reject" on each.',
                  ),
                  const Divider(height: 1),
                  _buildFAQTile(
                    'How do I run payroll?',
                    'In the "Payroll" section, you can generate salary slips and process monthly payments for all active employees.',
                  ),
                  const Divider(height: 1),
                  _buildFAQTile(
                    'How do I export reports?',
                    'Reports can be exported from the "Reports" or "Attendance" sections by tapping the export icon in the top right.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('CONTACT SUPPORT'),
            const SizedBox(height: 12),
            _buildSupportButton(
              context: context,
              icon: Icons.email_rounded,
              label: 'Email Support',
              onTap: () => _launchUrl(context, 'mailto:support@equitec.com'),
            ),
            const SizedBox(height: 12),
            _buildSupportButton(
              context: context,
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              onTap: () => _launchUrl(context, 'https://wa.me/+919876543210'),
              color: const Color(0xFF25D366),
            ),
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Text(
                    'EqHR v1.0.0',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Equitec Technologies',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.outfit(
          color: AdminColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AdminColors.primary,
  }) {
    return AdminSurfaceCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AdminColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
