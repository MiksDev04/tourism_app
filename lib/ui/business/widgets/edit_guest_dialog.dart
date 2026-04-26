import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../pages/business_guest_records_page.dart'; // for GuestRecord / GuestRecordStatus

// ─── Edit Guest Dialog ────────────────────────────────────────────────────────

/// Opens the edit dialog pre-populated with [record].
/// Returns the updated [GuestRecord] on save, or `null` on cancel.
Future<GuestRecord?> showEditGuestDialog(
  BuildContext context, {
  required GuestRecord record,
}) {
  return showDialog<GuestRecord>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => _EditGuestDialog(record: record),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _EditGuestDialog extends StatefulWidget {
  const _EditGuestDialog({required this.record});
  final GuestRecord record;

  @override
  State<_EditGuestDialog> createState() => _EditGuestDialogState();
}

class _EditGuestDialogState extends State<_EditGuestDialog> {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final TextEditingController _checkInCtrl;
  late final TextEditingController _checkOutCtrl;
  late final TextEditingController _nightsCtrl;
  late final TextEditingController _guestsCtrl;
  late final TextEditingController _roomsCtrl;

  late String _purpose;
  late String _transport;

  // ── Demographic breakdown ─────────────────────────────────────────────────
  // Percentages (0-100); must sum to ≤ 100.
  late final TextEditingController _demoMaleCtrl;
  late final TextEditingController _demoFemaleCtrl;
  late final TextEditingController _demoOtherCtrl;

  // Age groups
  late final TextEditingController _demoUnder18Ctrl;
  late final TextEditingController _demo18to35Ctrl;
  late final TextEditingController _demo36to60Ctrl;
  late final TextEditingController _demoOver60Ctrl;

  // ── Options ───────────────────────────────────────────────────────────────
  static const _purposes = ['Leisure', 'Business', 'Event', 'Other'];
  static const _transports = [
    'Private Car',
    'Bus',
    'Van',
    'Motorcycle',
    'Taxi',
    'Other',
  ];

  // ── Validation ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _checkInCtrl = TextEditingController(text: r.checkIn);
    _checkOutCtrl = TextEditingController(text: r.checkOut);
    _nightsCtrl = TextEditingController(text: r.nights);
    _guestsCtrl = TextEditingController(text: r.guests.toString());
    _roomsCtrl = TextEditingController(text: r.rooms.toString());
    _purpose = _purposes.contains(r.purpose) ? r.purpose : _purposes.first;
    _transport = _transports.contains(r.transport)
        ? r.transport
        : _transports.first;

    // Demographic defaults (blank = not yet filled in)
    _demoMaleCtrl = TextEditingController();
    _demoFemaleCtrl = TextEditingController();
    _demoOtherCtrl = TextEditingController();
    _demoUnder18Ctrl = TextEditingController();
    _demo18to35Ctrl = TextEditingController();
    _demo36to60Ctrl = TextEditingController();
    _demoOver60Ctrl = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _checkInCtrl,
      _checkOutCtrl,
      _nightsCtrl,
      _guestsCtrl,
      _roomsCtrl,
      _demoMaleCtrl,
      _demoFemaleCtrl,
      _demoOtherCtrl,
      _demoUnder18Ctrl,
      _demo18to35Ctrl,
      _demo36to60Ctrl,
      _demoOver60Ctrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final List<GuestRecord> updated = [
      GuestRecord(
        checkIn: '2024-04-01',
        checkOut: '2024-04-03',
        nights: '2 nights',
        guests: 10,
        rooms: 4,
        purpose: 'Leisure',
        transport: 'Private Car',
        status: GuestRecordStatus.active,
        demographics: const GuestDemographics(
          ageGroups: {'18-25': 2, '26-35': 5, '36-50': 3},
          genderDistribution: {'Male': 6, 'Female': 4},
          countries: {'USA': 5, 'Canada': 3, 'UK': 2},
        ),
      ),
      // ... other records with demographics
    ];

    Navigator.of(context).pop(updated);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 24,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              _Header(onClose: () => Navigator.of(context).pop()),

              // ── Scrollable body ─────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stay details ────────────────────────────────
                        _SectionLabel('Stay Details'),
                        const SizedBox(height: 12),
                        if (isNarrow) ...[
                          _DateField(
                            label: 'Check-in',
                            controller: _checkInCtrl,
                          ),
                          const SizedBox(height: 10),
                          _DateField(
                            label: 'Check-out',
                            controller: _checkOutCtrl,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(
                                  label: 'Check-in',
                                  controller: _checkInCtrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateField(
                                  label: 'Check-out',
                                  controller: _checkOutCtrl,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        if (isNarrow) ...[
                          _NumberField(
                            label: 'Guests',
                            controller: _guestsCtrl,
                          ),
                          const SizedBox(height: 10),
                          _NumberField(label: 'Rooms', controller: _roomsCtrl),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _NumberField(
                                  label: 'Guests',
                                  controller: _guestsCtrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _NumberField(
                                  label: 'Rooms',
                                  controller: _roomsCtrl,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        if (isNarrow) ...[
                          _DropdownField<String>(
                            label: 'Purpose',
                            value: _purpose,
                            items: _purposes,
                            onChanged: (v) =>
                                setState(() => _purpose = v ?? _purpose),
                          ),
                          const SizedBox(height: 10),
                          _DropdownField<String>(
                            label: 'Transport',
                            value: _transport,
                            items: _transports,
                            onChanged: (v) =>
                                setState(() => _transport = v ?? _transport),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _DropdownField<String>(
                                  label: 'Purpose',
                                  value: _purpose,
                                  items: _purposes,
                                  onChanged: (v) =>
                                      setState(() => _purpose = v ?? _purpose),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DropdownField<String>(
                                  label: 'Transport',
                                  value: _transport,
                                  items: _transports,
                                  onChanged: (v) => setState(
                                    () => _transport = v ?? _transport,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 22),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        const SizedBox(height: 22),

                        // ── Demographic breakdown ────────────────────────
                        _SectionLabel('Guest Demographic Breakdown'),
                        const SizedBox(height: 6),
                        const Text(
                          'All values are percentages (%). Gender & Age groups each '
                          'should ideally sum to 100%.',
                          style: TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Gender row
                        _SubLabel('Gender'),
                        const SizedBox(height: 8),
                        if (isNarrow) ...[
                          _PercentField(
                            label: 'Male',
                            controller: _demoMaleCtrl,
                          ),
                          const SizedBox(height: 8),
                          _PercentField(
                            label: 'Female',
                            controller: _demoFemaleCtrl,
                          ),
                          const SizedBox(height: 8),
                          _PercentField(
                            label: 'Other / Prefer not to say',
                            controller: _demoOtherCtrl,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _PercentField(
                                  label: 'Male',
                                  controller: _demoMaleCtrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PercentField(
                                  label: 'Female',
                                  controller: _demoFemaleCtrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PercentField(
                                  label: 'Other / Prefer not to say',
                                  controller: _demoOtherCtrl,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),

                        // Age groups
                        _SubLabel('Age Groups'),
                        const SizedBox(height: 8),
                        if (isNarrow) ...[
                          _PercentField(
                            label: 'Under 18',
                            controller: _demoUnder18Ctrl,
                          ),
                          const SizedBox(height: 8),
                          _PercentField(
                            label: '18 – 35',
                            controller: _demo18to35Ctrl,
                          ),
                          const SizedBox(height: 8),
                          _PercentField(
                            label: '36 – 60',
                            controller: _demo36to60Ctrl,
                          ),
                          const SizedBox(height: 8),
                          _PercentField(
                            label: 'Over 60',
                            controller: _demoOver60Ctrl,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _PercentField(
                                  label: 'Under 18',
                                  controller: _demoUnder18Ctrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PercentField(
                                  label: '18 – 35',
                                  controller: _demo18to35Ctrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PercentField(
                                  label: '36 – 60',
                                  controller: _demo36to60Ctrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PercentField(
                                  label: 'Over 60',
                                  controller: _demoOver60Ctrl,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer actions ─────────────────────────────────────────
              _Footer(
                onCancel: () => Navigator.of(context).pop(),
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Guest Record',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Update stay details and demographic breakdown.',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12.5),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.cardBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
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

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.onCancel, required this.onSave});
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(label: 'Cancel', onTap: onCancel, filled: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionBtn(
              label: 'Save Changes',
              onTap: onSave,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    // Teal/blue accent for save — matches existing app accent colours.
    const accent = Color(0xFF3B82F6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: filled ? accent : AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColors.textGray,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Form Field Widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textWhite,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Shared input decoration ───────────────────────────────────────────────────

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12.5),
    filled: true,
    fillColor: AppColors.backgroundDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
  );
}

// ── Date field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          color: AppColors.textSubtle,
          size: 15,
        ),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3B82F6),
                surface: Color(0xFF1A2332),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          controller.text =
              '${picked.year.toString().padLeft(4, '0')}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';
        }
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

// ── Number field ──────────────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      decoration: _inputDecoration(label),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final n = int.tryParse(v);
        if (n == null || n <= 0) return 'Must be > 0';
        return null;
      },
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      dropdownColor: AppColors.cardBackground,
      decoration: _inputDecoration(label),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSubtle,
        size: 18,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                e.toString(),
                style: const TextStyle(color: AppColors.textGray),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Percentage field ──────────────────────────────────────────────────────────

class _PercentField extends StatelessWidget {
  const _PercentField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?')),
      ],
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      decoration: _inputDecoration(label).copyWith(
        suffixText: '%',
        suffixStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return null; // optional
        final n = double.tryParse(v);
        if (n == null || n < 0 || n > 100) return '0–100';
        return null;
      },
    );
  }
}
