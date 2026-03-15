import 'package:flutter/material.dart';

import 'admin_navigation.dart';
import 'admin_ui_kit.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
  });

  final AdminSection currentSection;
  final ValueChanged<AdminSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final drawerSections = [
      AdminSection.dashboard,
      AdminSection.employees,
      AdminSection.leaves,
      AdminSection.payroll,
      AdminSection.hrPolicy,
      AdminSection.reports,
    ];

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'myHR',
                      style: TextStyle(
                        color: AdminColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: drawerSections.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF2F4F7),
                ),
                itemBuilder: (context, index) {
                  final section = drawerSections[index];
                  final selected = section == currentSection;
                  return Container(
                    color: selected
                        ? AdminColors.softOrange
                        : Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: Icon(
                        section.icon,
                        size: 32,
                        color: selected
                            ? AdminColors.primary
                            : const Color(0xFF42526E),
                      ),
                      title: Text(
                        section.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: selected
                              ? AdminColors.primary
                              : const Color(0xFF42526E),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSectionSelected(section);
                      },
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Text(
                'v2.4.0 Admin Portal',
                style: TextStyle(
                  color: Color(0xFF8DA0BE),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
