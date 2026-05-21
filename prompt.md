import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../api/messages_api.dart';

// ─── Send Mode ────────────────────────────────────────────────────────────────

enum SendToMode { specific, all }

// ─── Draft (DB-aligned) ────────────────────────────────────────────────────────

class ComposeMessageDraft {
  ComposeMessageDraft({
    this.sendToMode = SendToMode.specific,
    this.selectedBusiness, // holds UUID + name from businesses table
    this.messageType,
    this.subject = '',
    this.messageContent = '',
  });

  SendToMode sendToMode;
  BusinessSummary? selectedBusiness; // was String? — now a proper model
  MessageType? messageType;
  String subject;
  String messageContent;

  bool get isValid {
    final hasRecipient = sendToMode == SendToMode.all ||
        selectedBusiness != null;
    return hasRecipient &&
        messageType != null &&
        subject.trim().isNotEmpty &&
        messageContent.trim().isNotEmpty;
  }

  ComposeMessageDraft copyWith({
    SendToMode? sendToMode,
    BusinessSummary? selectedBusiness,
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

/// [api]      — injected MessagesApi instance
/// [senderId] — the logged-in admin's profiles.id (UUID)
Future<bool?> showComposeMessageDialog(
  BuildContext context, {
  required MessagesApi api,
  required String senderId,
  ComposeMessageDraft? initialDraft,
}) {
  return showDialog<bool>(
    context: context,
    // ignore: deprecated_member_use
    barrierColor: Colors.black.withOpacity(0.65),
    barrierDismissible: true,
    builder: (_) => ComposeMessageDialog(
      api: api,
      senderId: senderId,
      initialDraft: initialDraft,
    ),
  );
}

// ─── Letter Preview Builder ───────────────────────────────────────────────────

String _buildLetter(ComposeMessageDraft d) {
  final now = DateTime.now();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
  final typeLabel = switch (d.messageType) {
    MessageType.compliance  => 'COMPLIANCE NOTICE',
    MessageType.announcement => 'ANNOUNCEMENT',
    _                        => 'GENERAL NOTICE',
  };
  final recipient = d.sendToMode == SendToMode.all
      ? 'All Registered Accommodations'
      : (d.selectedBusiness?.name ?? '—');
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
  const ComposeMessageDialog({
    super.key,
    required this.api,
    required this.senderId,
    this.initialDraft,
  });

  final MessagesApi api;
  final String senderId;
  final ComposeMessageDraft? initialDraft;

  @override
  State<ComposeMessageDialog> createState() => _ComposeMessageDialogState();
}

class _ComposeMessageDialogState extends State<ComposeMessageDialog>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── State ──────────────────────────────────────────────────────────────────
  late ComposeMessageDraft _draft;
  bool _previewMode = false;
  bool _sending = false;

  /// Tracks which fields the user has interacted with.
  /// Errors only show for touched fields (or all after first submit attempt).
  final Set<String> _touched = {};

  // ── Businesses (loaded from API) ───────────────────────────────────────────
  List<BusinessSummary> _businesses = [];
  bool _loadingBusinesses = true;
  String? _businessesError;

  // ── Text Controllers ───────────────────────────────────────────────────────
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

    _loadBusinesses();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── Business Loader ────────────────────────────────────────────────────────

  Future<void> _loadBusinesses() async {
    setState(() {
      _loadingBusinesses = true;
      _businessesError = null;
    });
    try {
      final list = await widget.api.fetchBusinesses();
      if (mounted) setState(() => _businesses = list);
    } catch (e) {
      if (mounted) setState(() => _businessesError = 'Failed to load businesses.');
    } finally {
      if (mounted) setState(() => _loadingBusinesses = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _syncText() {
    _draft.subject = _subjectCtrl.text;
    _draft.messageContent = _contentCtrl.text;
  }

  void _touch(String field) {
    if (!_touched.contains(field)) {
      setState(() => _touched.add(field));
    }
  }

  /// Returns an error string when the field is touched and invalid, else null.
  String? _err(String field, bool invalid, String message) {
    if (_touched.contains(field) && invalid) return message;
    return null;
  }

  void _togglePreview() {
    _syncText();
    setState(() => _previewMode = !_previewMode);
  }

  Future<void> _send() async {
    _syncText();

    // Mark every field as touched so all errors surface at once
    setState(() {
      _touched
        ..add('business')
        ..add('messageType')
        ..add('subject')
        ..add('content');
    });

    if (!_draft.isValid) return;

    setState(() => _sending = true);

    try {
      if (_draft.sendToMode == SendToMode.all) {
        await widget.api.sendToAll(
          senderId: widget.senderId,
          messageType: _draft.messageType!,
          subject: _draft.subject,
          content: _draft.messageContent,
        );
      } else {
        await widget.api.sendToOne(
          senderId: widget.senderId,
          businessId: _draft.selectedBusiness!.id, // UUID — no ambiguity
          messageType: _draft.messageType!,
          subject: _draft.subject,
          content: _draft.messageContent,
        );
      }

      if (mounted) Navigator.of(context).pop(true); // success
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Derive validation errors
    final businessErr = _err(
      'business',
      _draft.sendToMode == SendToMode.specific &&
          _draft.selectedBusiness == null,
      'Please select a business',
    );
    final typeErr = _err(
      'messageType',
      _draft.messageType == null,
      'Please select a message type',
    );
    final subjectErr = _err(
      'subject',
      _draft.subject.trim().isEmpty,
      'Subject is required',
    );
    final contentErr = _err(
      'content',
      _draft.messageContent.trim().isEmpty,
      'Message content is required',
    );

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
                                    businesses: _businesses,
                                    loadingBusinesses: _loadingBusinesses,
                                    businessesError: _businessesError,
                                    onRetryBusinesses: _loadBusinesses,
                                    businessErr: businessErr,
                                    typeErr: typeErr,
                                    subjectErr: subjectErr,
                                    contentErr: contentErr,
                                    onChanged: (d) =>
                                        setState(() => _draft = d),
                                    onTouch: _touch,
                                    onSyncText: _syncText,
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
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textGray, size: 16),
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
    required this.businesses,
    required this.loadingBusinesses,
    required this.businessesError,
    required this.onRetryBusinesses,
    required this.businessErr,
    required this.typeErr,
    required this.subjectErr,
    required this.contentErr,
    required this.onChanged,
    required this.onTouch,
    required this.onSyncText,
  });

  final ComposeMessageDraft draft;
  final TextEditingController subjectCtrl;
  final TextEditingController contentCtrl;
  final List<BusinessSummary> businesses;
  final bool loadingBusinesses;
  final String? businessesError;
  final VoidCallback onRetryBusinesses;
  final String? businessErr;
  final String? typeErr;
  final String? subjectErr;
  final String? contentErr;
  final ValueChanged<ComposeMessageDraft> onChanged;
  final ValueChanged<String> onTouch;
  final VoidCallback onSyncText;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Send To ────────────────────────────────────────────────────────
          const _Label('Send To'),
          const SizedBox(height: 10),
          _SendToToggle(
            mode: draft.sendToMode,
            onChanged: (m) {
              onTouch('business');
              onChanged(draft.copyWith(
                sendToMode: m,
                clearBusiness: m == SendToMode.all,
              ));
            },
          ),

          // ── Business Picker ────────────────────────────────────────────────
          if (draft.sendToMode == SendToMode.specific) ...[
            const SizedBox(height: 18),
            const _Label('Select Business'),
            const SizedBox(height: 10),
            _BusinessDropdown(
              selected: draft.selectedBusiness,
              businesses: businesses,
              loading: loadingBusinesses,
              loadError: businessesError,
              onRetry: onRetryBusinesses,
              errorText: businessErr,
              onChanged: (b) {
                onTouch('business');
                onChanged(draft.copyWith(selectedBusiness: b));
              },
            ),
          ],

          // ── Message Type ───────────────────────────────────────────────────
          const SizedBox(height: 18),
          const _Label('Message Type'),
          const SizedBox(height: 10),
          _TypeSelector(
            selected: draft.messageType,
            errorText: typeErr,
            onChanged: (t) {
              onTouch('messageType');
              onChanged(draft.copyWith(messageType: t));
            },
          ),

          // ── Subject ────────────────────────────────────────────────────────
          const SizedBox(height: 18),
          const _Label('Subject'),
          const SizedBox(height: 10),
          _StyledTextField(
            controller: subjectCtrl,
            hint: 'Enter subject...',
            errorText: subjectErr,
            onChanged: (v) {
              onTouch('subject');
              onSyncText();
              onChanged(draft.copyWith(subject: v));
            },
            onEditingComplete: () => onTouch('subject'),
          ),

          // ── Message Content ────────────────────────────────────────────────
          const SizedBox(height: 18),
          const _Label('Message Content'),
          const SizedBox(height: 10),
          _StyledTextField(
            controller: contentCtrl,
            hint: 'Write your message here...',
            maxLines: 6,
            errorText: contentErr,
            onChanged: (v) {
              onTouch('content');
              onSyncText();
              onChanged(draft.copyWith(messageContent: v));
            },
            onEditingComplete: () => onTouch('content'),
          ),
        ],
      ),
    );
  }
}

// ─── Send-To Toggle ───────────────────────────────────────────────────────────

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

class _BusinessDropdown extends StatelessWidget {
  const _BusinessDropdown({
    required this.selected,
    required this.businesses,
    required this.loading,
    required this.loadError,
    required this.onRetry,
    required this.onChanged,
    this.errorText,
  });

  final BusinessSummary? selected;
  final List<BusinessSummary> businesses;
  final bool loading;
  final String? loadError;
  final VoidCallback onRetry;
  final ValueChanged<BusinessSummary?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Loading state ──────────────────────────────────────────────────
        if (loading)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textGray,
                ),
              ),
            ),
          )

        // ── Error state ────────────────────────────────────────────────────
        else if (loadError != null)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loadError!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: onRetry,
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )

        // ── Dropdown ───────────────────────────────────────────────────────
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError
                    ? Colors.redAccent
                    : AppColors.cardBorder,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BusinessSummary>(
                value: selected,
                hint: const Text(
                  'Choose business...',
                  style: TextStyle(
                      color: AppColors.textSubtle, fontSize: 13.5),
                ),
                isExpanded: true,
                dropdownColor: AppColors.cardBackground,
                iconEnabledColor: AppColors.textGray,
                style: const TextStyle(
                    color: AppColors.textWhite, fontSize: 13.5),
                // Compare by UUID so equality works correctly
                items: businesses
                    .map(
                      (b) => DropdownMenuItem<BusinessSummary>(
                        value: b,
                        child: Row(
                          children: [
                            Expanded(child: Text(b.name)),
                            // Show status badge for non-active businesses
                            if (b.status != null && b.status != 'active')
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.orange.withOpacity(0.4)),
                                ),
                                child: Text(
                                  b.status!,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),

        // ── Inline error ───────────────────────────────────────────────────
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 13),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Message Type Selector ────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    this.errorText,
  });

  final MessageType? selected;
  final ValueChanged<MessageType> onChanged;
  final String? errorText;

  static const _opts = [
    (
      type: MessageType.compliance,
      color: Color(0xFFFF4D6A),
    ),
    (
      type: MessageType.announcement,
      color: Color(0xFF9B8AFB),
    ),
    (
      type: MessageType.general,
      color: Color(0xFF1A6FFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_opts.length, (i) {
            final opt = _opts[i];
            final isActive = selected == opt.type;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: i < _opts.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onChanged(opt.type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          // ignore: deprecated_member_use
                          ? opt.color.withOpacity(0.13)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            // ignore: deprecated_member_use
                            ? opt.color.withOpacity(0.5)
                            : (errorText != null
                                ? Colors.redAccent.withOpacity(0.5)
                                : AppColors.cardBorder),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(opt.type.icon,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            opt.type.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive
                                  ? opt.color
                                  : AppColors.textGray,
                              fontSize: 12.5,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 13),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Styled Text Field ────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
    this.onEditingComplete,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError ? Colors.redAccent : AppColors.cardBorder,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            maxLines: maxLines,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 13.5,
              height: 1.55,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.textSubtle, fontSize: 13.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              // Live character counter for subject (max 255 per DB schema)
              counterText: maxLines == 1
                  ? '${controller.text.length}/255'
                  : null,
              counterStyle: const TextStyle(
                  color: AppColors.textSubtle, fontSize: 10.5),
            ),
            maxLength: maxLines == 1 ? 255 : null, // matches DB varchar(255)
            buildCounter: maxLines == 1
                ? (_, {required currentLength, required isFocused, maxLength}) =>
                    Text(
                      '$currentLength/${maxLength ?? 255}',
                      style: TextStyle(
                        color: currentLength > 240
                            ? Colors.orange
                            : AppColors.textSubtle,
                        fontSize: 10.5,
                      ),
                    )
                : null,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 13),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ),
        ],
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
                      colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: AppColors.primaryBlue.withOpacity(0.35),
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


import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum MessageType {
  compliance,
  announcement,
  general;

  /// Matches the Postgres enum values in the `messages` table.
  String get dbValue => name; // 'compliance' | 'announcement' | 'general'

  String get label => switch (this) {
        MessageType.compliance => 'Compliance',
        MessageType.announcement => 'Announcement',
        MessageType.general => 'General',
      };

  String get icon => switch (this) {
        MessageType.compliance => '⚠️',
        MessageType.announcement => '📣',
        MessageType.general => '💬',
      };
}

enum MessageStatus {
  sent,
  read,
  archived;

  String get dbValue => name;
}

// ─── Models ───────────────────────────────────────────────────────────────────

class BusinessSummary {
  const BusinessSummary({
    required this.id,
    required this.name,
    this.status,
  });

  /// UUID from `businesses.id`
  final String id;

  /// `businesses.business_name`
  final String name;

  /// `businesses.status` — useful for showing inactive/pending badges in the dropdown
  final String? status;

  factory BusinessSummary.fromJson(Map<String, dynamic> json) =>
      BusinessSummary(
        id: json['id'] as String,
        name: json['business_name'] as String,
        status: json['status'] as String?,
      );
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.businessId,
    required this.messageType,
    required this.subject,
    required this.content,
    required this.status,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.senderName,
  });

  final String id;
  final String senderId;
  final String businessId;
  final MessageType messageType;
  final String subject;
  final String content;
  final MessageStatus status;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Joined from `profiles.full_name` via the `sender` relation.
  final String? senderName;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        businessId: json['business_id'] as String,
        messageType: MessageType.values.firstWhere(
          (e) => e.dbValue == json['message_type'],
          orElse: () => MessageType.general,
        ),
        subject: json['subject'] as String,
        content: json['content'] as String,
        status: MessageStatus.values.firstWhere(
          (e) => e.dbValue == json['status'],
          orElse: () => MessageStatus.sent,
        ),
        isRead: json['is_read'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
        senderName:
            (json['sender'] as Map<String, dynamic>?)?['full_name'] as String?,
      );
}

// ─── API ──────────────────────────────────────────────────────────────────────

class MessagesApi {
  MessagesApi({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ── Businesses ─────────────────────────────────────────────────────────────

  /// Fetch all non-deleted businesses for the compose dropdown.
  /// Ordered alphabetically by business name.
  Future<List<BusinessSummary>> fetchBusinesses() async {
    final data = await _client
        .from('businesses')
        .select('id, business_name, status')
        .filter('deleted_at', 'is', null)
        .order('business_name', ascending: true);

    return (data as List<dynamic>)
        .map((b) => BusinessSummary.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  /// Send a message to a single business.
  /// `senderId` is the admin's `profiles.id`.
  Future<void> sendToOne({
    required String senderId,
    required String businessId,
    required MessageType messageType,
    required String subject,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'sender_id': senderId,
      'business_id': businessId,
      'message_type': messageType.dbValue,
      'subject': subject.trim(),
      'content': content.trim(),
      // status defaults to 'sent', is_read defaults to false in DB
    });
  }

  /// Send the same message to every non-deleted business (bulk insert).
  /// Returns the count of businesses messaged.
  Future<int> sendToAll({
    required String senderId,
    required MessageType messageType,
    required String subject,
    required String content,
  }) async {
    // Fetch all active business IDs
    final businesses = await _client
        .from('businesses')
        .select('id')
        .filter('deleted_at', 'is', null)
        .filter('status', 'eq', 'active');

    if ((businesses as List).isEmpty) return 0;

    final rows = businesses
        .map((b) => {
              'sender_id': senderId,
              'business_id': b['id'] as String,
              'message_type': messageType.dbValue,
              'subject': subject.trim(),
              'content': content.trim(),
            })
        .toList();

    await _client.from('messages').insert(rows);
    return rows.length;
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Fetch all messages for a specific business (receiver/business-owner view).
  Future<List<Message>> fetchForBusiness(String businessId) async {
    final data = await _client
        .from('messages')
        .select('*, sender:profiles!sender_id(full_name)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all messages sent by an admin (sender view).
  Future<List<Message>> fetchSentByAdmin(String adminId) async {
    final data = await _client
        .from('messages')
        .select(
          '*, sender:profiles!sender_id(full_name), business:businesses(business_name)',
        )
        .eq('sender_id', adminId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  /// Mark a single message as read.
  Future<void> markAsRead(String messageId) async {
    await _client.from('messages').update({
      'is_read': true,
      'status': MessageStatus.read.dbValue,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', messageId);
  }

  /// Archive a message.
  Future<void> archive(String messageId) async {
    await _client.from('messages').update({
      'status': MessageStatus.archived.dbValue,
    }).eq('id', messageId);
  }

  /// Get unread message count for a business (for badge indicators).
  Future<int> unreadCount(String businessId) async {
    final response = await _client
        .from('messages')
        .select('id')
        .eq('business_id', businessId)
        .eq('is_read', false);

    return (response as List).length;
  }
}



CHnage the code below. make sure it matches the api and the compose message modal is connected to this tooo. GIve me the updated Admin Message Page:


// ignore_for_file: deprecated_member_use

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
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
                _MessagesTable(rows: _filtered),
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
            _ComposeButton(
              onMessageSent: () {
                (context
                    .findAncestorStateOfType<_AdminMessagesPageState>()
                    // ignore: invalid_use_of_protected_member
                    ?.setState(() {}));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message sent successfully'),
                    backgroundColor: AppColors.accentGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
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
          final newMessage = Message(
            type: draft.messageType!,
            subject: draft.subject,
            recipient: draft.sendToMode == SendToMode.all
                ? 'All Businesses'
                : draft.selectedBusiness!,
            date: _getCurrentDate(),
          );
          _messages = [newMessage, ..._messages];
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
                    height: 38,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
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
      child: rows.isEmpty
          ? Column(
              children: [
                const _TableHeader(),
                const Divider(color: AppColors.cardBorder, height: 1),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No messages found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                const _TableHeader(),
                const Divider(color: AppColors.cardBorder, height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.cardBorder, height: 1),
                  itemBuilder: (_, i) => _MessageRow(message: rows[i]),
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
                    const Expanded(flex: 3, child: _HeaderCell('Recipient')),
                    const Expanded(flex: 2, child: _HeaderCell('Date')),
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
      MessageType.compliance => 'COMPLIANCE NOTICE',
      MessageType.announcement => 'ANNOUNCEMENT',
      MessageType.general => 'GENERAL NOTICE',
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
                      flex: 2,
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

