import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/message_models.dart';


// ─── Enums ────────────────────────────────────────────────────────────────────


enum SendToMode { specific, all }

// ─── Draft Model (mutable, state-preserving) ──────────────────────────────────

class ComposeMessageDraft {
  ComposeMessageDraft({
    this.sendToMode = SendToMode.specific,
    this.selectedBusiness,
    this.messageType,
    this.subject = '',
    this.messageContent = '',
  });

  SendToMode sendToMode;
  String? selectedBusiness;
  MessageType? messageType;
  String subject;
  String messageContent;

  bool get isValid {
    final hasRecipient = sendToMode == SendToMode.all ||
        (selectedBusiness != null && selectedBusiness!.isNotEmpty);
    return hasRecipient &&
        messageType != null &&
        subject.trim().isNotEmpty &&
        messageContent.trim().isNotEmpty;
  }

  ComposeMessageDraft copyWith({
    SendToMode? sendToMode,
    String? selectedBusiness,
    bool clearBusiness = false,
    MessageType? messageType,
    String? subject,
    String? messageContent,
  }) {
    return ComposeMessageDraft(
      sendToMode: sendToMode ?? this.sendToMode,
      selectedBusiness:
          clearBusiness ? null : (selectedBusiness ?? this.selectedBusiness),
      messageType: messageType ?? this.messageType,
      subject: subject ?? this.subject,
      messageContent: messageContent ?? this.messageContent,
    );
  }
}

// ─── Show Helper ──────────────────────────────────────────────────────────────

Future<ComposeMessageDraft?> showComposeMessageDialog(
  BuildContext context, {
  ComposeMessageDraft? initialDraft,
}) {
  return showDialog<ComposeMessageDraft>(
    context: context,
    // ignore: deprecated_member_use
    barrierColor: Colors.black.withOpacity(0.65),
    barrierDismissible: true,
    builder: (_) => ComposeMessageDialog(initialDraft: initialDraft),
  );
}

// ─── Letter Builder ───────────────────────────────────────────────────────────

String _buildLetter(ComposeMessageDraft d) {
  final now = DateTime.now();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
  final typeLabel = switch (d.messageType) {
    MessageType.compliance => 'COMPLIANCE NOTICE',
    MessageType.announcement => 'ANNOUNCEMENT',
    _ => 'GENERAL NOTICE',
  };
  final recipient = d.sendToMode == SendToMode.all
      ? 'All Registered Accommodations'
      : (d.selectedBusiness ?? '');
  final ref = 'MSG-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

  return '''REPUBLIC OF THE PHILIPPINES
CITY OF SAN PABLO
OFFICE OF TOURISM

$dateStr

To: $recipient
Re: ${d.subject.isEmpty ? '(no subject)' : d.subject}

$typeLabel

Dear Establishment Representative,

${d.messageContent.isEmpty ? '(no content)' : d.messageContent}

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

// ─── Main Dialog ──────────────────────────────────────────────────────────────

class ComposeMessageDialog extends StatefulWidget {
  const ComposeMessageDialog({super.key, this.initialDraft});

  final ComposeMessageDraft? initialDraft;

  @override
  State<ComposeMessageDialog> createState() => _ComposeMessageDialogState();
}

class _ComposeMessageDialogState extends State<ComposeMessageDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  late ComposeMessageDraft _draft;
  bool _previewMode = false;
  bool _sending = false;
  bool _showValidation = false;

  late final TextEditingController _subjectCtrl;
  late final TextEditingController _contentCtrl;

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
    
    _draft = widget.initialDraft ??
        ComposeMessageDraft(
          sendToMode: SendToMode.specific,
          messageType: MessageType.general,
        );
    _subjectCtrl = TextEditingController(text: _draft.subject);
    _contentCtrl = TextEditingController(text: _draft.messageContent);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // Sync text fields into draft before using draft
  void _syncText() {
    _draft.subject = _subjectCtrl.text;
    _draft.messageContent = _contentCtrl.text;
  }

  void _togglePreview() {
    _syncText();
    setState(() => _previewMode = !_previewMode);
  }

  Future<void> _send() async {
    _syncText();
    if (!_draft.isValid) {
      setState(() => _showValidation = true);
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _sending = false);
      Navigator.of(context).pop(_draft);
    }
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
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 48,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Header(
                          previewMode: _previewMode,
                          onToggle: _togglePreview,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _previewMode
                                ? _LetterPreview(
                                    key: const ValueKey('preview'),
                                    text: _buildLetter(_draft),
                                  )
                                : _Form(
                                    key: const ValueKey('form'),
                                    draft: _draft,
                                    subjectCtrl: _subjectCtrl,
                                    contentCtrl: _contentCtrl,
                                    showValidation: _showValidation,
                                    onChanged: (d) => setState(() {
                                      _draft = d;
                                    }),
                                  ),
                          ),
                        ),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        _Footer(
                          canSend: _draft.isValid && !_sending,
                          sending: _sending,
                          onCancel: () => Navigator.of(context).pop(),
                          onSend: _send,
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
  const _Header({
    required this.previewMode,
    required this.onToggle,
    required this.onClose,
  });

  final bool previewMode;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Text(
            'Compose Message',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                previewMode ? 'Edit' : 'Preview Letter',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClose,
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

// ─── Compose Form ─────────────────────────────────────────────────────────────

class _Form extends StatelessWidget {
  const _Form({
    super.key,
    required this.draft,
    required this.subjectCtrl,
    required this.contentCtrl,
    required this.onChanged,
    required this.showValidation,
  });

  final ComposeMessageDraft draft;
  final TextEditingController subjectCtrl;
  final TextEditingController contentCtrl;
  final ValueChanged<ComposeMessageDraft> onChanged;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Send To
          const _Label('Send To'),
          const SizedBox(height: 10),
          _SendToToggle(
            mode: draft.sendToMode,
            onChanged: (m) => onChanged(
              draft.copyWith(
                sendToMode: m,
                clearBusiness: m == SendToMode.all,
              ),
            ),
          ),

          // Business picker (only for specific)
          if (draft.sendToMode == SendToMode.specific) ...[
            const SizedBox(height: 18),
            const _Label('Select Business'),
            const SizedBox(height: 10),
            _BusinessDropdown(
              value: draft.selectedBusiness,
              onChanged: (v) =>
                  onChanged(draft.copyWith(selectedBusiness: v)),
              errorText: showValidation && (draft.selectedBusiness == null || draft.selectedBusiness!.isEmpty)
                  ? 'Please select a business'
                  : null,
            ),
          ],

          // Message Type
          const SizedBox(height: 18),
          const _Label('Message Type'),
          const SizedBox(height: 10),
          _TypeSelector(
            selected: draft.messageType,
            onChanged: (t) => onChanged(draft.copyWith(messageType: t)),
            showValidation: showValidation,
          ),

          // Subject
          const SizedBox(height: 18),
          const _Label('Subject'),
          const SizedBox(height: 10),
          _TextField(
            controller: subjectCtrl,
            hint: 'Enter subject...',
            onChanged: (v) => onChanged(draft.copyWith(subject: v)),
            errorText: showValidation && draft.subject.trim().isEmpty ? 'Subject is required' : null,
          ),

          // Message Content
          const SizedBox(height: 18),
          const _Label('Message Content'),
          const SizedBox(height: 10),
          _TextField(
            controller: contentCtrl,
            hint: 'Write your message here...',
            maxLines: 6,
            onChanged: (v) => onChanged(draft.copyWith(messageContent: v)),
            errorText: showValidation && draft.messageContent.trim().isEmpty ? 'Message content is required' : null,
          ),
        ],
      ),
    );
  }
}

// ─── Send To Toggle ───────────────────────────────────────────────────────────

class _SendToToggle extends StatelessWidget {
  const _SendToToggle({required this.mode, required this.onChanged});

  final SendToMode mode;
  final ValueChanged<SendToMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Segment(
            label: 'Specific Business',
            active: mode == SendToMode.specific,
            leftRounded: true,
            rightRounded: false,
            onTap: () => onChanged(SendToMode.specific),
          ),
        ),
        Expanded(
          child: _Segment(
            label: 'All Businesses',
            active: mode == SendToMode.all,
            leftRounded: false,
            rightRounded: true,
            onTap: () => onChanged(SendToMode.all),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.leftRounded,
    required this.rightRounded,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool leftRounded;
  final bool rightRounded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          color: active ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.horizontal(
            left: leftRounded ? const Radius.circular(10) : Radius.zero,
            right: rightRounded ? const Radius.circular(10) : Radius.zero,
          ),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textGray,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Business Dropdown ────────────────────────────────────────────────────────

const _kBusinesses = [
  'Grand Hotel San Pablo',
  'Sampaloc Lake Resort',
  'Casa San Pablo Inn',
  "Traveler's Lodge",
  'Paradise Resort & Spa',
  'Lakeview Boutique Hotel',
];

class _BusinessDropdown extends StatelessWidget {
  const _BusinessDropdown({required this.value, required this.onChanged, this.errorText});

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text(
            'Choose business...',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
          ),
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          iconEnabledColor: AppColors.textGray,
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
          items: _kBusinesses
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
    // show helper text below
    // (can't return two widgets, but parent layout will handle spacing)
  }

}

// ─── Message Type Selector ────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged, this.showValidation = false});

  final MessageType? selected;
  final ValueChanged<MessageType> onChanged;
  final bool showValidation;

  static const _opts = [
    (type: MessageType.compliance, label: 'Compliance', icon: '⚠️', color: Color(0xFFFF4D6A)),
    (type: MessageType.announcement, label: 'Announcement', icon: '📣', color: Color(0xFF9B8AFB)),
    (type: MessageType.general, label: 'General', icon: '💬', color: Color(0xFF1A6FFF)),
  ];

  @override
  Widget build(BuildContext context) {
    final hasError = showValidation && selected == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: hasError ? Colors.red : Colors.transparent),
          ),
          child: Row(
            children: List.generate(_opts.length, (i) {
              final opt = _opts[i];
              final isActive = selected == opt.type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _opts.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onChanged(opt.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? opt.color.withOpacity(0.13)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? opt.color.withOpacity(0.5)
                              : AppColors.cardBorder,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(opt.icon, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              opt.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive ? opt.color : AppColors.textGray,
                                fontSize: 12.5,
                                fontWeight:
                                    isActive ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          const Text('Please select a message type', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ]
      ],
    );
  }
}

// ─── Text Field ───────────────────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: errorText != null ? Colors.red : AppColors.cardBorder),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 13.5,
              height: 1.55,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ]
      ],
    );
  }
}

// ─── Letter Preview ───────────────────────────────────────────────────────────

class _LetterPreview extends StatelessWidget {
  const _LetterPreview({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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

// ─── Field Label ──────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canSend,
    required this.sending,
    required this.onCancel,
    required this.onSend,
  });

  final bool canSend;
  final bool sending;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Cancel
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send Message (grows to fill)
          Expanded(
            child: GestureDetector(
              onTap: canSend ? onSend : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: canSend ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primaryBlue.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (sending)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.send_rounded,
                            color: Colors.white, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        sending ? 'Sending...' : 'Send Message',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}