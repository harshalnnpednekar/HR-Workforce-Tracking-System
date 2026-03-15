import 'package:flutter/material.dart';

class AdminColors {
  static const Color background = Color(0xFFF6F4F2);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFFFF5B0A);
  static const Color text = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color border = Color(0xFFE6EBF2);
  static const Color softOrange = Color(0xFFFFF1E8);
  static const Color softGreen = Color(0xFFE8F9EF);
  static const Color softBlue = Color(0xFFEAF2FF);
  static const Color softRed = Color(0xFFFFECEC);
  static const Color green = Color(0xFF18C37E);
  static const Color blue = Color(0xFF3B82F6);
  static const Color red = Color(0xFFFF5D5D);
  static const Color amber = Color(0xFFFFA033);
}

class AdminSurfaceCard extends StatelessWidget {
  const AdminSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AdminColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: content,
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: 21,
      fontWeight: FontWeight.w800,
      color: AdminColors.text,
    );

    return Row(
      children: [
        Expanded(child: Text(title, style: titleStyle)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AdminColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class AdminIconBadge extends StatelessWidget {
  const AdminIconBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.size = 52,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: size * 0.42),
    );
  }
}
