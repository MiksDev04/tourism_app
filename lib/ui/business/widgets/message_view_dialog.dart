import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../api/messages_api.dart';

// ─── Show helper ──────────────────────────────────────────────────────────────

String _sectionLabel(MessageType type) {
  switch (type) {
    case MessageType.compliance:
      return 'COMPLIANCE NOTICE';
    case MessageType.announcement:
      return 'ANNOUNCEMENT';
    case MessageType.general:
      return 'GENERAL NOTICE';
  }
}

Future<void> showMessageViewDialog(BuildContext context, Message message) async {
  final api = MessagesApi();
  final recipient = await api.fetchReceiverName(message.businessId) ?? message.businessId;
  final dateStr = _formatDate(message.createdAt);
  final ref = message.id;

  final letter = '''REPUBLIC OF THE PHILIPPINES
CITY OF SAN PABLO
OFFICE OF TOURISM

$dateStr

To: $recipient
Re: ${message.subject}

${_sectionLabel(message.messageType)}

Dear Establishment Representative,

${message.content}

This notice is duly issued by the San Pablo City Tourism Office and is valid even without a handwritten signature, being an official electronic communication of the office.

For questions and concerns, please contact us at admin@sanpablo.gov.ph or visit our office at the San Pablo City Hall.

Respectfully,

${(message.senderName ?? 'MARIA SANTOS').toUpperCase()}
Tourism Officer
San Pablo City Tourism Office

---
This is an official communication from the San Pablo City Tourism Office.
Reference No.: $ref''';

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => _MessageViewDialog(letter: letter),
  );
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

class _MessageViewDialog extends StatelessWidget {
  const _MessageViewDialog({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.6),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModalHeader(onClose: () => Navigator.of(context).pop()),
              const Divider(color: AppColors.cardBorder, height: 1),

              // ── Body ───────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    letter,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Modal Header ─────────────────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Text(
            'Message Letter',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textGray,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta row (Date / To / Re) ────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, height: 1.4),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: AppColors.textSubtle),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: AppColors.textGray,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type Badge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final MessageType type;

  @override
  Widget build(BuildContext context) {
    final (label, color, emoji) = switch (type) {
      MessageType.compliance =>
        ('Compliance', AppColors.accentRed, '⚠️'),
      MessageType.announcement =>
        ('Announcement', AppColors.accentPurple, '📣'),
      MessageType.general =>
        ('General', AppColors.primaryBlue, '💬'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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