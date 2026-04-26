import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../widgets/compose_message_modal.dart';
import '../widgets/message_view_dialog.dart';
import '../models/message_models.dart';


// ─── Sample Data ──────────────────────────────────────────────────────────────

List<Message> _messages = [
  const Message(
    type: MessageType.compliance,
    subject: 'Monthly Report Compliance Notice - March 2024',
    recipient: 'Grand Hotel San Pablo',
    date: '2024-04-01',
  ),
  const Message(
    type: MessageType.announcement,
    subject: 'Tourism Month Celebration - May 2024',
    recipient: 'Sampaloc Lake Resort',
    date: '2024-04-15',
  ),
  const Message(
    type: MessageType.compliance,
    subject: 'Second Notice: Missing Monthly Reports',
    recipient: 'Paradise Resort & Spa',
    date: '2024-04-10',
  ),
  const Message(
    type: MessageType.general,
    subject: 'System Update: New Report Features',
    recipient: 'Grand Hotel San Pablo',
    date: '2024-04-20',
  ),
  const Message(
    type: MessageType.general,
    subject: 'Data Collection Reminder',
    recipient: 'Sampaloc Lake Resort',
    date: '2024-03-25',
  ),
];

const _typeOptions = ['All Types', 'Compliance', 'Announcement', 'General'];
const _monthOptions = [
  'All Months',
  'April 2024',
  'March 2024',
  'February 2024',
];
const _businessOptions = [
  'All Businesses',
  'Grand Hotel San Pablo',
  'Sampaloc Lake Resort',
  'Paradise Resort & Spa',
];

// ─── Admin Messages Page ──────────────────────────────────────────────────────

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  String _searchQuery = '';
  String _selectedType = 'All Types';
  String _selectedMonth = 'All Months';
  String _selectedBusiness = 'All Businesses';

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Message> get _filtered {
    return _messages.where((m) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          m.subject.toLowerCase().contains(q) ||
          m.recipient.toLowerCase().contains(q);

      final matchesType =
          _selectedType == 'All Types' ||
          m.type.name.toLowerCase() == _selectedType.toLowerCase();

      final matchesBusiness =
          _selectedBusiness == 'All Businesses' ||
          m.recipient == _selectedBusiness;

      return matchesSearch && matchesType && matchesBusiness;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Messages',
      selectedIndex: 3,
      onNavSelected: (_) {},
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeader(),
            const SizedBox(height: 16),
            _FilterRow(
              searchCtrl: _searchCtrl,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              selectedType: _selectedType,
              onTypeChanged: (v) => setState(() => _selectedType = v!),
              selectedMonth: _selectedMonth,
              onMonthChanged: (v) => setState(() => _selectedMonth = v!),
              selectedBusiness: _selectedBusiness,
              onBusinessChanged: (v) => setState(() => _selectedBusiness = v!),
            ),
            const SizedBox(height: 14),
            Expanded(child: _MessagesTable(rows: _filtered)),
          ],
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages & Announcements',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: isSmall ? 18 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send notices to accommodation establishments',
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: isSmall ? 11 : 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _ComposeButton(onMessageSent: () {
              (context.findAncestorStateOfType<_AdminMessagesPageState>()
                  ?.setState(() {}));
            }),
          ],
        );
      },
    );
  }
}

class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onMessageSent});

  final VoidCallback onMessageSent;

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final draft = await showComposeMessageDialog(context);
        if (draft != null && draft.isValid) {
          _messages = [
            Message(
              type: draft.messageType!,
              subject: draft.subject,
              recipient: draft.sendToMode == SendToMode.all 
                  ? 'All Businesses' 
                  : draft.selectedBusiness!,
              date: _getCurrentDate(),
            ),
            ..._messages,
          ];
          onMessageSent();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.send_rounded, color: Colors.white, size: 15),
            SizedBox(width: 7),
            Text(
              'Compose Message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.selectedBusiness,
    required this.onBusinessChanged,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final String selectedType;
  final ValueChanged<String?> onTypeChanged;
  final String selectedMonth;
  final ValueChanged<String?> onMonthChanged;
  final String selectedBusiness;
  final ValueChanged<String?> onBusinessChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 800;
        return isSmall
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _SearchField(
                          controller: searchCtrl,
                          onChanged: onSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: _DropdownFilter(
                          value: selectedType,
                          items: _typeOptions,
                          onChanged: onTypeChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownFilter(
                          value: selectedMonth,
                          items: _monthOptions,
                          onChanged: onMonthChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DropdownFilter(
                          value: selectedBusiness,
                          items: _businessOptions,
                          onChanged: onBusinessChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: _SearchField(
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedType,
                      items: _typeOptions,
                      onChanged: onTypeChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedMonth,
                      items: _monthOptions,
                      onChanged: onMonthChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedBusiness,
                      items: _businessOptions,
                      onChanged: onBusinessChanged,
                    ),
                  ),
                ],
              );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSubtle,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          iconEnabledColor: AppColors.textGray,
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Messages Table ───────────────────────────────────────────────────────────

class _MessagesTable extends StatelessWidget {
  const _MessagesTable({required this.rows});

  final List<Message> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const _TableHeader(),
          const Divider(color: AppColors.cardBorder, height: 1),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No messages found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.cardBorder, height: 1),
                    itemBuilder: (_, i) => _MessageRow(message: rows[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // final isSmall = constraints.maxWidth < 700;
        final isMedium = constraints.maxWidth < 900;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: isMedium
                ? [
                    const Expanded(
                      flex: 5,
                      child: _HeaderCell('Type / Subject'),
                    ),
                    const Expanded(flex: 3, child: _HeaderCell('Recipient')),
                    const Expanded(flex: 2, child: _HeaderCell('Date')),
                  ]
                : [
                    const Expanded(flex: 3, child: _HeaderCell('Type')),
                    const Expanded(flex: 6, child: _HeaderCell('Subject')),
                    const Expanded(flex: 4, child: _HeaderCell('Recipient')),
                    const Expanded(flex: 3, child: _HeaderCell('Date')),
                    const Expanded(flex: 1, child: _HeaderCell('Action')),
                  ],
          ),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Message Row ──────────────────────────────────────────────────────────────

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message});

  final Message message;

  void _openMessage(BuildContext context, Message message) {
    // Map MessageType enum → letter header string
    final typeLabel = switch (message.type) {
      MessageType.compliance   => 'COMPLIANCE NOTICE',
      MessageType.announcement => 'ANNOUNCEMENT',
      MessageType.general      => 'GENERAL NOTICE',
    };

    // Sample body per type — replace with real stored content when available
    final body = switch (message.type) {
      MessageType.compliance =>
        'This is to inform you that your monthly report for '
        '${message.date} is due. Please submit your report '
        'before the 5th of the following month to avoid penalties.',
      MessageType.announcement =>
        'We are pleased to announce an upcoming event related to tourism '
        'in San Pablo City. Please take note of the details and participate '
        'accordingly.',
      MessageType.general =>
        'This is a general notice from the San Pablo City Office of Tourism. '
        'Please review the information carefully and reach out if you have '
        'any questions or concerns.',
    };

    showMessageViewDialog(
      context,
      MessageViewData(
        subject: message.subject,
        recipient: message.recipient,
        date: message.date,
        messageType: typeLabel,
        messageContent: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMedium = constraints.maxWidth < 900;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: isMedium
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeBadge(type: message.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.subject,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openMessage(context, message),
                          child: const Icon(
                            Icons.visibility_outlined,
                            color: AppColors.textGray,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          message.recipient,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          message.date,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  spacing: 5,
                  children: [
                    Expanded(flex: 3, child: _TypeBadge(type: message.type)),
                    Expanded(
                      flex: 6,
                      child: Text(
                        message.subject,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        message.recipient,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        message.date,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () => _openMessage(context, message),
                        child: const Icon(
                          Icons.visibility_outlined,
                          color: AppColors.textGray,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─── Type Badge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final MessageType type;

  static _BadgeStyle _styleFor(MessageType t) {
    switch (t) {
      case MessageType.compliance:
        return const _BadgeStyle(
          label: 'Compliance',
          icon: '⚠️',
          color: Color(0xFFFF4D6A),
        );
      case MessageType.announcement:
        return const _BadgeStyle(
          label: 'Announcement',
          icon: '📣',
          color: Color(0xFF9B8AFB),
        );
      case MessageType.general:
        return const _BadgeStyle(
          label: 'General',
          icon: '💬',
          color: Color(0xFF1A6FFF),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(style.icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final String icon;
  final Color color;
}