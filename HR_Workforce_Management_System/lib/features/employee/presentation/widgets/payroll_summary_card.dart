import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A card that displays the current month's payroll and attendance overview.
class PayrollSummaryCard extends StatelessWidget {
  const PayrollSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Performance',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Present',
                  value: '18 Days',
                  color: Colors.green,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricItem(
                  label: 'Late Marks',
                  value: '2',
                  color: Colors.orange,
                  icon: Icons.access_time_filled_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricItem(
            label: 'Provisional Salary',
            value: '\$4,200',
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.account_balance_wallet_rounded,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isFullWidth;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
