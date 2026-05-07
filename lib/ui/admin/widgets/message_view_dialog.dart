import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ─── Message View Data ────────────────────────────────────────────────────────

class MessageViewData {
  const MessageViewData({
    required this.subject,
    required this.recipient,
    required this.date,
    required this.messageType,
    required this.messageContent,
  });

  final String subject;
  final String recipient;
  final String date;
  final String messageType; // e.g. 'COMPLIANCE NOTICE', 'GENERAL NOTICE'
  final String messageContent;
}

// ─── Show Helper ──────────────────────────────────────────────────────────────

Future<void> showMessageViewDialog(
  BuildContext context,
  MessageViewData data,
) {
  return showDialog(
    context: context,
    // ignore: deprecated_member_use
    barrierColor: Colors.black.withOpacity(0.65),
    barrierDismissible: true,
    builder: (_) => MessageViewDialog(data: data),
  );
}

// ─── Letter Builder ───────────────────────────────────────────────────────────

String _buildLetter(MessageViewData d) {
  final now = DateTime.now();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
  final ref = 'MSG-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

  return '''REPUBLIC OF THE PHILIPPINES
CITY OF SAN PABLO
OFFICE OF TOURISM

$dateStr

To: ${d.recipient}
Re: ${d.subject}

${d.messageType}

Dear Establishment Representative,

${d.messageContent}

This notice is duly issued by the San Pablo City Tourism Office and is valid even without a handwritten signature, being an official electronic communication of the office.

For questions and concerns, please contact us at admin@sanpablo.gov.ph or visit our office at the San Pablo City Hall.

Respectfully,

MARIA SANTOS
Tourism Officer
San Pablo City Tourism Office

---
This is an official communication from the San Pablo City Tourism Office.
Reference No.: $ref''';
}

// ─── Main Dialog Widget ───────────────────────────────────────────────────────

class MessageViewDialog extends StatefulWidget {
  const MessageViewDialog({super.key, required this.data});

  final MessageViewData data;

  @override
  State<MessageViewDialog> createState() => _MessageViewDialogState();
}

class _MessageViewDialogState extends State<MessageViewDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: GestureDetector(
          onTap: () {},
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 48,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Header(data: widget.data),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        Flexible(
                          child: _LetterBody(text: _buildLetter(widget.data)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final MessageViewData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.subject,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To: ${data.recipient} • ${data.date}',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
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

// ─── Letter Body ──────────────────────────────────────────────────────────────

class _LetterBody extends StatelessWidget {
  const _LetterBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 13,
            height: 1.75,
          ),
        ),
      ),
    );
  }
}