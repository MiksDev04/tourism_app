import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../shared/layouts/business_layout.dart';


// ─── Models ───────────────────────────────────────────────────────────────────

enum MessageType { general, compliance, announcement }

class BizMessage {
  BizMessage({
    required this.subject,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
  });

  final String subject;
  final String body;
  final MessageType type;
  final String date;
  bool isRead;
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

final _messages = [
  BizMessage(
    subject: 'System Update: New Report Features',
    body:
        'We have updated the tourism demographics system with new features including improved analytics, better report filtering, and enhanced data export options. Please explore the new features and provid...',
    type: MessageType.general,
    date: '2024-04-20',
    isRead: false,
  ),
  BizMessage(
    subject: 'Monthly Report Compliance Notice - March 2024',
    body:
        'This is to inform you that your monthly report for March 2024 is due. Please submit your report before the 5th of the following month to avoid penalties.',
    type: MessageType.compliance,
    date: '2024-04-01',
    isRead: true,
  ),
];

// ─── Filter Options ───────────────────────────────────────────────────────────

enum _Filter { all, compliance, announcement, general }

// ─── Business Messages Page ───────────────────────────────────────────────────

class BusinessMessagesPage extends StatefulWidget {
  const BusinessMessagesPage({super.key});

  @override
  State<BusinessMessagesPage> createState() => _BusinessMessagesPageState();
}

class _BusinessMessagesPageState extends State<BusinessMessagesPage> {
  _Filter _activeFilter = _Filter.all;

  int get _unreadCount => _messages.where((m) => !m.isRead).length;

  List<BizMessage> get _filtered => _messages.where((m) {
        return switch (_activeFilter) {
          _Filter.all          => true,
          _Filter.compliance   => m.type == MessageType.compliance,
          _Filter.announcement => m.type == MessageType.announcement,
          _Filter.general      => m.type == MessageType.general,
        };
      }).toList();

  void _markAsRead(BizMessage msg) {
    if (!msg.isRead) setState(() => msg.isRead = true);
  }

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Messages',
      selectedIndex: 4,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(unreadCount: _unreadCount),
                const SizedBox(height: 16),
                _FilterTabBar(
                  activeFilter: _activeFilter,
                  onChanged: (f) => setState(() => _activeFilter = f),
                ),
                const SizedBox(height: 16),
                _filtered.isEmpty
                    ? _EmptyState()
                    : Column(
                        children: _filtered
                            .map((msg) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _MessageCard(
                                    message: msg,
                                    isNarrow: isNarrow,
                                    onTap: () => _markAsRead(msg),
                                  ),
                                ))
                            .toList(),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.unreadCount});
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unreadCount > 0
              ? '$unreadCount unread message${unreadCount > 1 ? 's' : ''}'
              : 'No unread messages',
          style: TextStyle(
            color: unreadCount > 0
                ? AppColors.primaryCyan
                : AppColors.textSubtle,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Filter Tab Bar ───────────────────────────────────────────────────────────

class _FilterTabBar extends StatelessWidget {
  const _FilterTabBar({required this.activeFilter, required this.onChanged});

  final _Filter activeFilter;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            emoji: null,
            isActive: activeFilter == _Filter.all,
            onTap: () => onChanged(_Filter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Compliance',
            emoji: '⚠️',
            isActive: activeFilter == _Filter.compliance,
            onTap: () => onChanged(_Filter.compliance),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Announcement',
            emoji: '📣',
            isActive: activeFilter == _Filter.announcement,
            onTap: () => onChanged(_Filter.announcement),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'General',
            emoji: '💬',
            isActive: activeFilter == _Filter.general,
            onTap: () => onChanged(_Filter.general),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String? emoji;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd])
              : null,
          color: isActive ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textGray,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Card ─────────────────────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.isNarrow,
    required this.onTap,
  });

  final BizMessage message;
  final bool isNarrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !message.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.activeNavBg
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? AppColors.primaryCyan.withOpacity(0.25)
                : AppColors.cardBorder,
          ),
        ),
        child: isNarrow
            ? _NarrowLayout(message: message, isUnread: isUnread)
            : _WideLayout(message: message, isUnread: isUnread),
      ),
    );
  }
}

// ─── Wide Layout ──────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.message, required this.isUnread});
  final BizMessage message;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Envelope icon
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 14),
          child: Icon(
            isUnread ? Icons.email_rounded : Icons.drafts_rounded,
            color: isUnread ? AppColors.primaryCyan : AppColors.textSubtle,
            size: 20,
          ),
        ),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    message.subject,
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                message.body,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12.5,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Right side: type badge + date
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _TypeBadge(type: message.type),
            const SizedBox(height: 6),
            Text(
              message.date,
              style: const TextStyle(
                  color: AppColors.textSubtle, fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Narrow Layout ────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.message, required this.isUnread});
  final BizMessage message;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: icon + badge + date
        Row(
          children: [
            Icon(
              isUnread ? Icons.email_rounded : Icons.drafts_rounded,
              color: isUnread ? AppColors.primaryCyan : AppColors.textSubtle,
              size: 18,
            ),
            const SizedBox(width: 8),
            _TypeBadge(type: message.type),
            const Spacer(),
            Text(
              message.date,
              style: const TextStyle(
                  color: AppColors.textSubtle, fontSize: 11.5),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Subject
        Row(
          children: [
            Expanded(
              child: Text(
                message.subject,
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13.5,
                  fontWeight:
                      isUnread ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryCyan,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Body
        Text(
          message.body,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 12.5,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Type Badge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final MessageType type;

  static _BadgeStyle _styleFor(MessageType t) {
    switch (t) {
      case MessageType.general:
        return const _BadgeStyle(
          label: 'General',
          color: AppColors.primaryBlue,
        );
      case MessageType.compliance:
        return const _BadgeStyle(
          label: 'Compliance',
          color: AppColors.accentRed,
        );
      case MessageType.announcement:
        return const _BadgeStyle(
          label: 'Announcement',
          color: AppColors.accentPurple,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.35)),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({required this.label, required this.color});
  final String label;
  final Color color;
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              color: AppColors.textSubtle.withOpacity(0.4), size: 48),
          const SizedBox(height: 12),
          const Text(
            'No messages found.',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 14),
          ),
        ],
      ),
    );
  }
}