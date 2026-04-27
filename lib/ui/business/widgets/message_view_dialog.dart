import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../pages/business_messages_page.dart';

// ─── Show helper ──────────────────────────────────────────────────────────────

void showMessageViewDialog(BuildContext context, BizMessage message) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => _MessageViewDialog(message: message),
  );
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

class _MessageViewDialog extends StatelessWidget {
  const _MessageViewDialog({required this.message});
  final BizMessage message;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 40,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A2A),
            borderRadius: BorderRadius.circular(14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge
                        _TypeBadge(type: message.type),
                        const Spacer(),
                        // Close button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textGray,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Subject
                    Text(
                      message.subject,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // From + date
                    Text(
                      'From: Tourism Office  •  ${message.date}',
                      style: const TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Letter body ──────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF132035),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Letterhead ──────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'REPUBLIC OF THE PHILIPPINES',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'CITY OF SAN PABLO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'OFFICE OF TOURISM',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Metadata (Date / To / Re) ────────────────────
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MetaRow(label: 'Date:', value: message.date),
                              const SizedBox(height: 5),
                              const _MetaRow(
                                  label: 'To:',
                                  value: 'Grand Hotel San Pablo'),
                              const SizedBox(height: 5),
                              _MetaRow(
                                  label: 'Re:', value: message.subject, bold: true),
                            ],
                          ),
                        ),

                        // ── Notice body ──────────────────────────────────
                        Container(
                          margin: const EdgeInsets.all(14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1A2A),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sectionLabel(message.type),
                                style: const TextStyle(
                                  color: AppColors.textSubtle,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Dear Establishment Representative,',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                message.body,
                                style: const TextStyle(
                                  color: AppColors.textGray,
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Footer / Signatory ───────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'This notice is duly issued by the San Pablo City Tourism Office and is valid even without a handwritten signature, being an official electronic communication of the office.',
                                style: TextStyle(
                                  color: AppColors.textSubtle,
                                  fontSize: 10.5,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'MARIA SANTOS',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tourism Officer',
                                style: TextStyle(
                                  color: AppColors.textGray,
                                  fontSize: 12,
                                ),
                              ),
                              const Text(
                                'San Pablo City Tourism Office',
                                style: TextStyle(
                                  color: AppColors.textGray,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ─── Type Badge (mirrors the one in the page) ─────────────────────────────────

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