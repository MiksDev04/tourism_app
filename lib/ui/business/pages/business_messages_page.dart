import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../api/messages_api.dart';
import '../widgets/message_view_dialog.dart';
import '../../shared/layouts/business_layout.dart';

// ─── Filter Options ───────────────────────────────────────────────────────────

enum _Filter { all, compliance, announcement, general }

// ─── Business Messages Page ───────────────────────────────────────────────────

class BusinessMessagesPage extends StatefulWidget {
  const BusinessMessagesPage({super.key});

  @override
  State<BusinessMessagesPage> createState() => _BusinessMessagesPageState();
}

class _BusinessMessagesPageState extends State<BusinessMessagesPage> {
  final _api = MessagesApi();

  _Filter _activeFilter = _Filter.all;
  List<Message> _messages = [];

  /// Tracks IDs that have been optimistically marked read in this session,
  /// since Message.isRead is immutable (we can't mutate the model directly).
  final Set<String> _locallyRead = {};

  bool _isLoading = true;
  String? _error;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Data Loading ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Resolve the businessId that belongs to the currently authenticated user.
      _businessId ??= await _resolveBusinessId();

      if (_businessId == null) {
        setState(() {
          _error = 'No business account found for this user.';
          _isLoading = false;
        });
        return;
      }

      final messages = await _api.fetchForBusiness(_businessId!);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Looks up the `businesses.id` for the currently signed-in user.
  Future<String?> _resolveBusinessId() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await Supabase.instance.client
        .from('businesses')
        .select('id')
        .eq('profile_id', userId)
        .maybeSingle();

    return data?['id'] as String?;
  }

  // ── Computed ─────────────────────────────────────────────────────────────────

  bool _isRead(Message msg) => msg.isRead || _locallyRead.contains(msg.id);

  int get _unreadCount =>
      _messages.where((m) => !_isRead(m)).length;

  List<Message> get _filtered => _messages.where((m) {
        return switch (_activeFilter) {
          _Filter.all => true,
          _Filter.compliance => m.messageType == MessageType.compliance,
          _Filter.announcement => m.messageType == MessageType.announcement,
          _Filter.general => m.messageType == MessageType.general,
        };
      }).toList();

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _openMessage(Message msg) async {
    // Optimistic update — mark read immediately in the UI.
    if (!_isRead(msg)) {
      setState(() => _locallyRead.add(msg.id));
      // Fire-and-forget; errors are non-fatal for the UI.
      _api.markAsRead(msg.id).catchError((_) {});
    }

    if (!mounted) return;
    showMessageViewDialog(context, msg);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Messages',
      selectedIndex: 4,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return RefreshIndicator(
            color: AppColors.primaryCyan,
            backgroundColor: AppColors.cardBackground,
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  _buildBody(isNarrow),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isNarrow) {
    if (_isLoading) return const _LoadingState();
    if (_error != null) return _ErrorState(message: _error!, onRetry: _loadData);
    if (_filtered.isEmpty) return const _EmptyState();

    return Column(
      children: _filtered.map((msg) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MessageCard(
            message: msg,
            isRead: _isRead(msg),
            isNarrow: isNarrow,
            onTap: () => _openMessage(msg),
          ),
        );
      }).toList(),
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
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
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
    required this.isRead,
    required this.isNarrow,
    required this.onTap,
  });

  final Message message;

  /// Derived outside the card (combines isRead + locallyRead).
  final bool isRead;
  final bool isNarrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.activeNavBg : AppColors.cardBackground,
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
  final Message message;
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
                  Expanded(
                    child: Text(
                      message.subject,
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                message.content,
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
            _TypeBadge(type: message.messageType),
            const SizedBox(height: 6),
            Text(
              _formatDate(message.createdAt),
              style: const TextStyle(
                color: AppColors.textSubtle,
                fontSize: 11.5,
              ),
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
  final Message message;
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
            _TypeBadge(type: message.messageType),
            const Spacer(),
            Text(
              _formatDate(message.createdAt),
              style: const TextStyle(
                color: AppColors.textSubtle,
                fontSize: 11.5,
              ),
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
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
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
          message.content,
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

// ─── Loading State ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryCyan,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed.withOpacity(0.6),
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSubtle, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            color: AppColors.textSubtle.withOpacity(0.4),
            size: 48,
          ),
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

// ─── Date Formatter ───────────────────────────────────────────────────────────

/// Returns `yyyy-MM-dd` without any external date package.
String _formatDate(DateTime dt) {
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}