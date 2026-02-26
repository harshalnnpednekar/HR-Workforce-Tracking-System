import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget that displays the employee's profile header (avatar, name, title).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // Inner border and avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?u=john',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'John Doe',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Software Engineer • EMP-4092',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
