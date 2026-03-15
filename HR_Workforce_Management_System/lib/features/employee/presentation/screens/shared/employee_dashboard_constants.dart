import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared constants for the entire employee dashboard
class AppColors {
  static const Color surfaceBg = Color(0xFFF3F5F8);
  static const Color cardBorder = Color(0xFFE3E8F1);
  static const Color title = Color(0xFF101B34);
  static const Color muted = Color(0xFF60708E);
  static const Color primary = Color(0xFFF48300);
}

/// Global utility function to show action messages
void showActionMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Reusable card container widget
class BaseCard extends StatelessWidget {
  const BaseCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

/// Bell icon with notification dot
class BellIcon extends StatelessWidget {
  const BellIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: const [
        Icon(
          Icons.notifications_none_rounded,
          color: Color(0xFF3D4F6D),
          size: 31,
        ),
        Positioned(
          right: -1,
          top: 2,
          child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFE94C4C)),
        ),
      ],
    );
  }
}

/// Inner page header with back button, title, and bell icon
class InnerPageHeader extends StatelessWidget {
  const InnerPageHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF3B4C69),
          size: 34,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppColors.title,
              fontWeight: FontWeight.w700,
              fontSize: 26,
            ),
          ),
        ),
        const SizedBox(width: 28, child: BellIcon()),
      ],
    );
  }
}

/// Field label for forms
class FieldLabel extends StatelessWidget {
  const FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

/// Form field with TextFormField
class FormFieldBox extends StatelessWidget {
  const FormFieldBox({
    required this.hintText,
    this.trailing,
    this.height = 52,
    this.readOnly = false,
    this.onTap,
  });

  final String hintText;
  final Widget? trailing;
  final double height;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              readOnly: readOnly,
              onTap: onTap,
              maxLines: height > 60 ? 4 : 1,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF7F8EA7),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Legend dot for calendar
class LegendDot extends StatelessWidget {
  const LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
