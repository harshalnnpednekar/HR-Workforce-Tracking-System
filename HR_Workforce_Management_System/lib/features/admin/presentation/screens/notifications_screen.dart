import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/notification_service.dart';

/// A full-page notification center used by BOTH admin and employee.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => NotificationsScreen(userId: uid, isAdmin: false),
///   ));
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.userId,
    this.isAdmin = false,
  });

  final String userId;
  final bool isAdmin;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await NotificationService.markAllRead(widget.userId);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE6EBF2)),
        ),
        actions: [
          _markingAll
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : TextButton(
                  onPressed: _markAllRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Color(0xFFFF5B0A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.streamNotifications(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load notifications.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return const _EmptyState();
          }

          // Group by time section
          final grouped = _groupNotifications(notifications);

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            itemCount: _countItems(grouped),
            itemBuilder: (context, index) {
              return _buildItem(context, grouped, index);
            },
          );
        },
      ),
    );
  }

  // ─── Grouping ───────────────────────────────────────────────────────────────

  List<_NotifGroup> _groupNotifications(List<Map<String, dynamic>> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final Map<String, List<Map<String, dynamic>>> buckets = {
      'TODAY': [],
      'YESTERDAY': [],
      'EARLIER THIS WEEK': [],
      'OLDER': [],
    };

    for (final n in list) {
      final ts = n['createdAt'];
      final date = ts is Timestamp ? ts.toDate() : null;
      final day = date != null ? DateTime(date.year, date.month, date.day) : null;

      if (day == null || day.isAtSameMomentAs(today)) {
        buckets['TODAY']!.add(n);
      } else if (day.isAtSameMomentAs(yesterday)) {
        buckets['YESTERDAY']!.add(n);
      } else if (day.isAfter(weekAgo)) {
        buckets['EARLIER THIS WEEK']!.add(n);
      } else {
        buckets['OLDER']!.add(n);
      }
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _NotifGroup(label: e.key, items: e.value))
        .toList();
  }

  int _countItems(List<_NotifGroup> groups) {
    // Each group contributes 1 header + items.length items + 1 footer sentinel
    int count = 0;
    for (final g in groups) {
      count += 1 + g.items.length;
    }
    count += 1; // end message
    return count;
  }

  Widget _buildItem(
    BuildContext context,
    List<_NotifGroup> groups,
    int flatIndex,
  ) {
    int cursor = 0;
    for (final group in groups) {
      if (flatIndex == cursor) {
        return _SectionHeader(label: group.label);
      }
      cursor++;
      for (final item in group.items) {
        if (flatIndex == cursor) {
          return _NotifCard(
            notification: item,
            onTap: () async {
              if (item['isRead'] == false) {
                await NotificationService.markRead(item['id'] as String);
              }
            },
          );
        }
        cursor++;
      }
    }
    // End sentinel
    return const _EndMessage();
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Notification Card ───────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notification, this.onTap});

  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = (notification['type'] as String?) ?? 'system';
    final title = (notification['title'] as String?) ?? '';
    final message = (notification['message'] as String?) ?? '';
    final isRead = (notification['isRead'] as bool?) ?? true;
    final ts = notification['createdAt'];
    final timeStr = _formatTime(ts);
    final meta = _NotifMeta.forType(type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFFF4EE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead ? const Color(0xFFE6EBF2) : const Color(0xFFFFD4B8),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A0F172A),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: meta.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, color: meta.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5B0A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts is! Timestamp) return '';
    final date = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }
}

// ─── Notification Meta ───────────────────────────────────────────────────────

class _NotifMeta {
  const _NotifMeta({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  static _NotifMeta forType(String type) {
    return switch (type) {
      NotificationService.typeLeaveApproved => const _NotifMeta(
          icon: Icons.event_available_rounded,
          iconColor: Color(0xFF16A34A),
          iconBg: Color(0xFFDCFCE7),
        ),
      NotificationService.typeLeaveRejected => const _NotifMeta(
          icon: Icons.event_busy_rounded,
          iconColor: Color(0xFFDC2626),
          iconBg: Color(0xFFFEE2E2),
        ),
      NotificationService.typeLeaveRequest => const _NotifMeta(
          icon: Icons.mail_outline_rounded,
          iconColor: Color(0xFFFF5B0A),
          iconBg: Color(0xFFFFF0E8),
        ),
      NotificationService.typeAttendance => const _NotifMeta(
          icon: Icons.access_time_rounded,
          iconColor: Color(0xFF3B82F6),
          iconBg: Color(0xFFDEEBFF),
        ),
      NotificationService.typePayroll => const _NotifMeta(
          icon: Icons.payments_outlined,
          iconColor: Color(0xFF16A34A),
          iconBg: Color(0xFFDCFCE7),
        ),
      NotificationService.typeLate => const _NotifMeta(
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFD97706),
          iconBg: Color(0xFFFEF3C7),
        ),
      NotificationService.typeNewEmployee => const _NotifMeta(
          icon: Icons.person_add_alt_1_rounded,
          iconColor: Color(0xFF7C3AED),
          iconBg: Color(0xFFEDE9FE),
        ),
      _ => const _NotifMeta(
          icon: Icons.notifications_rounded,
          iconColor: Color(0xFF6B7280),
          iconBg: Color(0xFFF3F4F6),
        ),
    };
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No Notifications',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You're all caught up!",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── End Message ─────────────────────────────────────────────────────────────

class _EndMessage extends StatelessWidget {
  const _EndMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: const [
          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "You've seen all notifications",
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }
}

// ─── Internal data models ─────────────────────────────────────────────────────

class _NotifGroup {
  const _NotifGroup({required this.label, required this.items});
  final String label;
  final List<Map<String, dynamic>> items;
}
