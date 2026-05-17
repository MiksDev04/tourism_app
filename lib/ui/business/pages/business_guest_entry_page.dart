import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';
import '../../../api/business_guest_entry_api.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class DemographicRow {
  DemographicRow()
      : nationality = null,
        region = null,
        gender = null,
        ageGroup = null,
        countCtrl = TextEditingController(text: '');

  String? nationality;
  String? region;
  String? gender;
  String? ageGroup;
  final TextEditingController countCtrl;

  void dispose() => countCtrl.dispose();
}

// ─── Options ──────────────────────────────────────────────────────────────────

const _purposeOptions = [
  'Leisure',
  'Business',
  'Education',
  'Medical',
  'Religious',
  'Others',
];

const _transportOptions = [
  'Private Car',
  'Bus',
  'Van',
  'Motorcycle',
  'Tricycle',
  'Others',
];

const _nationalityOptions = [
  'Philippines',
  'USA',
  'Japan',
  'Korea',
  'China',
  'Australia',
  'United Kingdom',
  'Canada',
  'Others',
];

const _regionOptions = [
  'NCR',
  'CAR',
  'Region I',
  'Region II',
  'Region III',
  'Region IV-A (CALABARZON)',
  'Region IV-B (MIMAROPA)',
  'Region V',
  'Region VI',
  'Region VII',
  'Region VIII',
  'Region IX',
  'Region X',
  'Region XI',
  'Region XII',
  'Region XIII',
  'BARMM',
];

const _genderOptions = [
  'Male',
  'Female',
  'LGBT+',
  'Prefer not to say',
];

const _ageGroupOptions = [
  '0–9',
  '10–17',
  '18–25',
  '26–35',
  '36–45',
  '46–55',
  '56+',
  'Prefer not to say',
];

// ─── Guest Entry Page ─────────────────────────────────────────────────────────

class BusinessGuestEntryPage extends StatefulWidget {
  const BusinessGuestEntryPage({super.key});

  @override
  State<BusinessGuestEntryPage> createState() => _BusinessGuestEntryPageState();
}

class _BusinessGuestEntryPageState extends State<BusinessGuestEntryPage> {
  final _api = BusinessGuestEntryApi();
  String? _businessId;

  DateTime? _checkIn;
  DateTime? _checkOut;
  final _totalGuestsCtrl = TextEditingController();
  final _roomsOccupiedCtrl = TextEditingController();
  String? _purpose;
  String? _transport;
  final _purposeOtherCtrl = TextEditingController();
  final _transportOtherCtrl = TextEditingController();
  bool _showPurposeOther = false;
  bool _showTransportOther = false;
  bool _isSaving = false;

  // ── Inline validation errors ────────────────────────────────────────────────
  // Top-level field errors
  Map<String, String?> _errors = {};
  // Per-demographic-row errors: list of maps keyed by field name
  List<Map<String, String?>> _rowErrors = [];

  final List<DemographicRow> _rows = [DemographicRow()];

  @override
  void initState() {
    super.initState();
    _rowErrors = [{}];
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    final id = await _api.fetchBusinessId();
    if (mounted) setState(() => _businessId = id);
  }

  int get _nightsCount {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays.clamp(0, 999);
  }

  int get _demographicTotal =>
      _rows.fold(0, (sum, r) => sum + (int.tryParse(r.countCtrl.text) ?? 0));

  int get _totalGuests => int.tryParse(_totalGuestsCtrl.text) ?? 0;

  void _addRow() => setState(() {
        _rows.add(DemographicRow());
        _rowErrors.add({});
      });

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      _rowErrors.removeAt(index);
    });
  }

  void _clearFieldError(String key) {
    if (_errors.containsKey(key)) {
      setState(() => _errors = Map.from(_errors)..remove(key));
    }
  }

  void _clearRowFieldError(int index, String key) {
    if (_rowErrors.length > index && _rowErrors[index].containsKey(key)) {
      setState(() {
        _rowErrors = List.from(_rowErrors);
        _rowErrors[index] = Map.from(_rowErrors[index])..remove(key);
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryCyan,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _checkIn = null;
      _checkOut = null;
      _totalGuestsCtrl.clear();
      _roomsOccupiedCtrl.clear();
      _purpose = null;
      _transport = null;
      _purposeOtherCtrl.clear();
      _transportOtherCtrl.clear();
      _showPurposeOther = false;
      _showTransportOther = false;
      _errors = {};
      for (final r in _rows) r.dispose();
      _rows
        ..clear()
        ..add(DemographicRow());
      _rowErrors = [{}];
    });
  }

  /// Validates all fields, populates [_errors] and [_rowErrors], and returns
  /// true only when the form is fully valid.
  bool _validateAndSetErrors() {
    final errors = <String, String?>{};
    final rowErrors =
        List.generate(_rows.length, (_) => <String, String?>{});
    bool hasError = false;

    // ── Dates ──────────────────────────────────────────────────────────────
    if (_checkIn == null) {
      errors['checkIn'] = 'Please select a check-in date.';
      hasError = true;
    } else if (_checkIn!.isAfter(DateTime.now())) {
      errors['checkIn'] = 'Check-in date cannot be in the future.';
      hasError = true;
    }

    if (_checkOut == null) {
      errors['checkOut'] = 'Please select a check-out date.';
      hasError = true;
    } else if (_checkIn != null && !_checkOut!.isAfter(_checkIn!)) {
      errors['checkOut'] = 'Check-out must be after check-in.';
      hasError = true;
    }

    // ── Guests ─────────────────────────────────────────────────────────────
    final guests = int.tryParse(_totalGuestsCtrl.text);
    if (guests == null || guests <= 0) {
      errors['totalGuests'] = 'Enter at least 1 guest.';
      hasError = true;
    } else if (guests > 9999) {
      errors['totalGuests'] = 'Value seems too large.';
      hasError = true;
    }

    // ── Rooms ──────────────────────────────────────────────────────────────
    final rooms = int.tryParse(_roomsOccupiedCtrl.text);
    if (rooms == null || rooms <= 0) {
      errors['roomsOccupied'] = 'Enter at least 1 room.';
      hasError = true;
    } else if (guests != null && guests > 0 && rooms > guests) {
      errors['roomsOccupied'] = 'Cannot exceed total guests.';
      hasError = true;
    }

    // ── Purpose ────────────────────────────────────────────────────────────
    if (_purpose == null) {
      errors['purpose'] = 'Please select a purpose of visit.';
      hasError = true;
    } else if (_purpose == 'Others' &&
        _purposeOtherCtrl.text.trim().isEmpty) {
      errors['purposeOther'] = 'Please specify the purpose.';
      hasError = true;
    }

    // ── Transport ──────────────────────────────────────────────────────────
    if (_transport == null) {
      errors['transport'] = 'Please select a mode of transportation.';
      hasError = true;
    } else if (_transport == 'Others' &&
        _transportOtherCtrl.text.trim().isEmpty) {
      errors['transportOther'] = 'Please specify the transportation.';
      hasError = true;
    }

    // ── Demographic rows ───────────────────────────────────────────────────
    final seen = <String>{};
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];

      if (row.nationality == null) {
        rowErrors[i]['nationality'] = 'Required';
        hasError = true;
      }
      if (row.nationality == 'Philippines' && row.region == null) {
        rowErrors[i]['region'] = 'Required for Philippine entries';
        hasError = true;
      }
      if (row.gender == null) {
        rowErrors[i]['gender'] = 'Required';
        hasError = true;
      }
      if (row.ageGroup == null) {
        rowErrors[i]['ageGroup'] = 'Required';
        hasError = true;
      }

      final count = int.tryParse(row.countCtrl.text) ?? 0;
      if (count <= 0) {
        rowErrors[i]['count'] = 'Min 1';
        hasError = true;
      }

      // Duplicate-row check (only when all fields are filled)
      if (row.nationality != null &&
          row.gender != null &&
          row.ageGroup != null) {
        final key =
            '${row.nationality}|${row.region}|${row.gender}|${row.ageGroup}';
        if (!seen.add(key)) {
          rowErrors[i]['nationality'] =
              'Duplicate row — merge counts instead';
          hasError = true;
        }
      }
    }

    // ── Demographic sum (only when individual rows are valid) ───────────────
    if (!hasError && guests != null && guests > 0) {
      if (_demographicTotal != guests) {
        errors['demographicSum'] =
            'Demographic total ($_demographicTotal) must equal total guests ($guests).';
        hasError = true;
      }
    }

    setState(() {
      _errors = errors;
      _rowErrors = rowErrors;
    });

    return !hasError;
  }

  Future<void> _save() async {
    final isValid = _validateAndSetErrors();
    if (!isValid) return;

    if (_businessId == null) {
      setState(() => _errors = {
            'businessId': 'Business account not found. Please try again.',
          });
      return;
    }

    setState(() => _isSaving = true);

    final purposeValue =
        _purpose == 'Others' ? _purposeOtherCtrl.text.trim() : _purpose!;
    final transportValue =
        _transport == 'Others' ? _transportOtherCtrl.text.trim() : _transport!;

    final result = await _api.saveGuestEntry(
      GuestEntryData(
        businessId: _businessId!,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        totalGuests: _totalGuests,
        roomsOccupied: int.parse(_roomsOccupiedCtrl.text),
        purposeOfVisit: purposeValue,
        transportationMode: transportValue,
        breakdowns: _rows
            .map((r) => GuestBreakdownData(
                  nationality: r.nationality!,
                  philippinesRegion:
                      r.nationality == 'Philippines' ? r.region : null,
                  gender: r.gender!,
                  ageGroup: r.ageGroup!,
                  count: int.parse(r.countCtrl.text),
                ))
            .toList(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      _clearForm();
      _showSuccessSnackBar('Guest entry saved successfully!');
    } else {
      setState(() => _errors = {
            'submit': result.error ?? 'Failed to save. Please try again.',
          });
    }
  }

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check-in is capped at today (can't pre-record future arrivals).
    // Check-out can be today or up to 2 years ahead.
    final firstDate = isCheckIn
        ? DateTime(2020)
        : (_checkIn != null
            ? _checkIn!.add(const Duration(days: 1))
            : today);
    final lastDate =
        isCheckIn ? today : today.add(const Duration(days: 730));
    final initialDate = isCheckIn
        ? today
        : (_checkIn != null
            ? _checkIn!.add(const Duration(days: 1))
            : today);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      // ── Dark-themed calendar fix ──────────────────────────────────────────
      // ThemeData.dark() alone leaves many surfaces white in Material 3.
      // Explicitly set every relevant ColorScheme slot and the dialog color.
      builder: (ctx, child) => Theme(
        data: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryCyan,
            onPrimary: Colors.black,
            primaryContainer: AppColors.primaryCyan.withOpacity(0.25),
            onPrimaryContainer: AppColors.primaryCyan,
            surface: AppColors.cardBackground,
            onSurface: AppColors.textWhite,
            onSurfaceVariant: AppColors.textGray,
            outline: AppColors.cardBorder,
            surfaceVariant: AppColors.inputBackground,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.cardBackground,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryCyan,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut != null && !_checkOut!.isAfter(picked)) _checkOut = null;
        _clearFieldError('checkIn');
      } else {
        _checkOut = picked;
        _clearFieldError('checkOut');
      }
    });
  }

  @override
  void dispose() {
    _totalGuestsCtrl.dispose();
    _roomsOccupiedCtrl.dispose();
    _purposeOtherCtrl.dispose();
    _transportOtherCtrl.dispose();
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Guest Entry',
      selectedIndex: 1,
      onNavSelected: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeader(),
            const SizedBox(height: 20),

            // ── Global submit error (API-level) ──────────────────────────
            if (_errors['submit'] != null) ...[
              _GlobalErrorBanner(message: _errors['submit']!),
              const SizedBox(height: 12),
            ],
            if (_errors['businessId'] != null) ...[
              _GlobalErrorBanner(message: _errors['businessId']!),
              const SizedBox(height: 12),
            ],

            _StayInfoCard(
              checkIn: _checkIn,
              checkOut: _checkOut,
              nights: _nightsCount,
              totalGuestsCtrl: _totalGuestsCtrl,
              roomsOccupiedCtrl: _roomsOccupiedCtrl,
              purpose: _purpose,
              transport: _transport,
              showPurposeOther: _showPurposeOther,
              showTransportOther: _showTransportOther,
              purposeOtherCtrl: _purposeOtherCtrl,
              transportOtherCtrl: _transportOtherCtrl,
              errors: _errors,
              onPickCheckIn: () => _pickDate(context, true),
              onPickCheckOut: () => _pickDate(context, false),
              onPurposeChanged: (v) {
                setState(() {
                  _purpose = v;
                  _showPurposeOther = v == 'Others';
                  if (!_showPurposeOther) _purposeOtherCtrl.clear();
                });
                _clearFieldError('purpose');
                _clearFieldError('purposeOther');
              },
              onTransportChanged: (v) {
                setState(() {
                  _transport = v;
                  _showTransportOther = v == 'Others';
                  if (!_showTransportOther) _transportOtherCtrl.clear();
                });
                _clearFieldError('transport');
                _clearFieldError('transportOther');
              },
              onGuestsChanged: (_) {
                setState(() {});
                _clearFieldError('totalGuests');
                _clearFieldError('demographicSum');
              },
              onRoomsChanged: (_) => _clearFieldError('roomsOccupied'),
              onPurposeOtherChanged: (_) => _clearFieldError('purposeOther'),
              onTransportOtherChanged: (_) =>
                  _clearFieldError('transportOther'),
            ),
            const SizedBox(height: 16),
            _DemographicCard(
              rows: _rows,
              total: _totalGuests,
              currentSum: _demographicTotal,
              errors: _errors,
              rowErrors: _rowErrors,
              onAddRow: _addRow,
              onRemoveRow: _removeRow,
              onRowChanged: (int rowIndex, String fieldKey) {
                setState(() {});
                _clearRowFieldError(rowIndex, fieldKey);
                _clearFieldError('demographicSum');
              },
            ),
            const SizedBox(height: 20),
            _FormActions(
              isSaving: _isSaving,
              onClear: () {
                _clearForm();
                _showSuccessSnackBar('Form cleared.');
              },
              onSave: _save,
            ),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Guest Entry',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Record tourist demographic data',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Global Error Banner ──────────────────────────────────────────────────────

class _GlobalErrorBanner extends StatelessWidget {
  const _GlobalErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.accentRed, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stay Info Card ───────────────────────────────────────────────────────────

class _StayInfoCard extends StatelessWidget {
  const _StayInfoCard({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.totalGuestsCtrl,
    required this.roomsOccupiedCtrl,
    required this.purpose,
    required this.transport,
    required this.showPurposeOther,
    required this.showTransportOther,
    required this.purposeOtherCtrl,
    required this.transportOtherCtrl,
    required this.errors,
    required this.onPickCheckIn,
    required this.onPickCheckOut,
    required this.onPurposeChanged,
    required this.onTransportChanged,
    required this.onGuestsChanged,
    required this.onRoomsChanged,
    required this.onPurposeOtherChanged,
    required this.onTransportOtherChanged,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final TextEditingController totalGuestsCtrl;
  final TextEditingController roomsOccupiedCtrl;
  final String? purpose;
  final String? transport;
  final bool showPurposeOther;
  final bool showTransportOther;
  final TextEditingController purposeOtherCtrl;
  final TextEditingController transportOtherCtrl;
  final Map<String, String?> errors;
  final VoidCallback onPickCheckIn;
  final VoidCallback onPickCheckOut;
  final ValueChanged<String?> onPurposeChanged;
  final ValueChanged<String?> onTransportChanged;
  final ValueChanged<String> onGuestsChanged;
  final ValueChanged<String> onRoomsChanged;
  final ValueChanged<String> onPurposeOtherChanged;
  final ValueChanged<String> onTransportOtherChanged;

  String _fmt(DateTime? dt) {
    if (dt == null) return 'mm/dd/yyyy';
    return '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stay Information',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),

          // ── Check-in / Check-out / Nights ─────────────────────────────────
          isMobile
              ? Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Check-in Date *',
                            errorText: errors['checkIn'],
                            child: _DatePickerField(
                              value: _fmt(checkIn),
                              hasError: errors['checkIn'] != null,
                              onTap: onPickCheckIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Check-out Date *',
                            errorText: errors['checkOut'],
                            child: _DatePickerField(
                              value: _fmt(checkOut),
                              hasError: errors['checkOut'] != null,
                              onTap: onPickCheckOut,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Length of Stay',
                      child: _ReadOnlyField(
                        value: nights > 0
                            ? '$nights night${nights > 1 ? 's' : ''}'
                            : '—',
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Check-in Date *',
                        errorText: errors['checkIn'],
                        child: _DatePickerField(
                          value: _fmt(checkIn),
                          hasError: errors['checkIn'] != null,
                          onTap: onPickCheckIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Check-out Date *',
                        errorText: errors['checkOut'],
                        child: _DatePickerField(
                          value: _fmt(checkOut),
                          hasError: errors['checkOut'] != null,
                          onTap: onPickCheckOut,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Length of Stay',
                        child: _ReadOnlyField(
                          value: nights > 0
                              ? '$nights night${nights > 1 ? 's' : ''}'
                              : '—',
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),

          // ── Total Guests / Rooms ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Total Guests *',
                  errorText: errors['totalGuests'],
                  child: _NumberInputField(
                    controller: totalGuestsCtrl,
                    hint: 'e.g. 10',
                    hasError: errors['totalGuests'] != null,
                    onChanged: onGuestsChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Rooms Occupied *',
                  errorText: errors['roomsOccupied'],
                  child: _NumberInputField(
                    controller: roomsOccupiedCtrl,
                    hint: 'e.g. 3',
                    hasError: errors['roomsOccupied'] != null,
                    onChanged: onRoomsChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Purpose / Transport ───────────────────────────────────────────
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabeledField(
                      label: 'Purpose of Visit *',
                      errorText: errors['purpose'],
                      child: _DropdownField(
                        value: purpose,
                        items: _purposeOptions,
                        hint: 'Select purpose',
                        hasError: errors['purpose'] != null,
                        onChanged: onPurposeChanged,
                      ),
                    ),
                    if (showPurposeOther) ...[
                      const SizedBox(height: 8),
                      _LabeledField(
                        label: '',
                        errorText: errors['purposeOther'],
                        child: _InputField(
                          controller: purposeOtherCtrl,
                          hint: 'Please specify',
                          hasError: errors['purposeOther'] != null,
                          onChanged: onPurposeOtherChanged,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'Mode of Transportation *',
                      errorText: errors['transport'],
                      child: _DropdownField(
                        value: transport,
                        items: _transportOptions,
                        hint: 'Select transportation',
                        hasError: errors['transport'] != null,
                        onChanged: onTransportChanged,
                      ),
                    ),
                    if (showTransportOther) ...[
                      const SizedBox(height: 8),
                      _LabeledField(
                        label: '',
                        errorText: errors['transportOther'],
                        child: _InputField(
                          controller: transportOtherCtrl,
                          hint: 'Please specify',
                          hasError: errors['transportOther'] != null,
                          onChanged: onTransportOtherChanged,
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledField(
                            label: 'Purpose of Visit *',
                            errorText: errors['purpose'],
                            child: _DropdownField(
                              value: purpose,
                              items: _purposeOptions,
                              hint: 'Select purpose',
                              hasError: errors['purpose'] != null,
                              onChanged: onPurposeChanged,
                            ),
                          ),
                          if (showPurposeOther) ...[
                            const SizedBox(height: 8),
                            _LabeledField(
                              label: '',
                              errorText: errors['purposeOther'],
                              child: _InputField(
                                controller: purposeOtherCtrl,
                                hint: 'Please specify',
                                hasError: errors['purposeOther'] != null,
                                onChanged: onPurposeOtherChanged,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledField(
                            label: 'Mode of Transportation *',
                            errorText: errors['transport'],
                            child: _DropdownField(
                              value: transport,
                              items: _transportOptions,
                              hint: 'Select transportation',
                              hasError: errors['transport'] != null,
                              onChanged: onTransportChanged,
                            ),
                          ),
                          if (showTransportOther) ...[
                            const SizedBox(height: 8),
                            _LabeledField(
                              label: '',
                              errorText: errors['transportOther'],
                              child: _InputField(
                                controller: transportOtherCtrl,
                                hint: 'Please specify',
                                hasError: errors['transportOther'] != null,
                                onChanged: onTransportOtherChanged,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ─── Demographic Card ─────────────────────────────────────────────────────────

class _DemographicCard extends StatelessWidget {
  const _DemographicCard({
    required this.rows,
    required this.total,
    required this.currentSum,
    required this.errors,
    required this.rowErrors,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onRowChanged,
  });

  final List<DemographicRow> rows;
  final int total;
  final int currentSum;
  final Map<String, String?> errors;
  final List<Map<String, String?>> rowErrors;
  final VoidCallback onAddRow;
  final ValueChanged<int> onRemoveRow;
  // rowIndex + fieldKey so parent can clear that specific error
  final void Function(int rowIndex, String fieldKey) onRowChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final totalLabel = total > 0 ? '$total' : '?';
    final sumMatch = total > 0 && currentSum == total;
    final sumColor = currentSum == 0
        ? AppColors.textGray
        : sumMatch
            ? const Color(0xFF00C48C)
            : AppColors.accentRed;
    final sumError = errors['demographicSum'];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guest Demographic Breakdown',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Must sum to $totalLabel total guests',
                      style: const TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$currentSum / $totalLabel',
                style: TextStyle(
                  color: sumColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onAddRow,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AppColors.primaryCyan.withOpacity(0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppColors.primaryCyan, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Add Row',
                        style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Demographic sum error lives here, right under the header
          if (sumError != null) ...[
            const SizedBox(height: 8),
            _InlineError(message: sumError),
          ],

          const SizedBox(height: 16),

          // Column headers (desktop only)
          if (!isMobile)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _ColHeader('Nationality')),
                  SizedBox(width: 10),
                  Expanded(flex: 3, child: _ColHeader('Region (if PH)')),
                  SizedBox(width: 10),
                  Expanded(flex: 2, child: _ColHeader('Gender')),
                  SizedBox(width: 10),
                  Expanded(flex: 2, child: _ColHeader('Age Group')),
                  SizedBox(width: 10),
                  Expanded(flex: 1, child: _ColHeader('Count')),
                  SizedBox(width: 30),
                ],
              ),
            ),

          ...List.generate(rows.length, (i) {
            final row = rows[i];
            final rErr = i < rowErrors.length ? rowErrors[i] : <String, String?>{};
            final isPhilippines = row.nationality == 'Philippines';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: isMobile
                  ? _MobileDemographicRow(
                      row: row,
                      isPhilippines: isPhilippines,
                      showDelete: rows.length > 1,
                      rowErrors: rErr,
                      onDelete: () => onRemoveRow(i),
                      onChanged: (fieldKey) => onRowChanged(i, fieldKey),
                    )
                  : _DemographicRowWidget(
                      row: row,
                      showDelete: rows.length > 1,
                      isPhilippines: isPhilippines,
                      rowErrors: rErr,
                      onDelete: () => onRemoveRow(i),
                      onChanged: (fieldKey) => onRowChanged(i, fieldKey),
                    ),
            );
          }),

          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Each row represents a unique combination of nationality, region, gender, and age group. Add multiple rows to cover all guest segments.',
                  style: TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Desktop Demographic Row ──────────────────────────────────────────────────

class _DemographicRowWidget extends StatelessWidget {
  const _DemographicRowWidget({
    required this.row,
    required this.showDelete,
    required this.isPhilippines,
    required this.rowErrors,
    required this.onDelete,
    required this.onChanged,
  });

  final DemographicRow row;
  final bool showDelete;
  final bool isPhilippines;
  final Map<String, String?> rowErrors;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _LabeledField(
                label: '',
                errorText: rowErrors['nationality'],
                child: _DropdownField(
                  value: row.nationality,
                  items: _nationalityOptions,
                  hint: 'Select country',
                  hasError: rowErrors['nationality'] != null,
                  onChanged: (v) {
                    row.nationality = v;
                    if (v != 'Philippines') row.region = null;
                    onChanged('nationality');
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _LabeledField(
                label: '',
                errorText: rowErrors['region'],
                child: isPhilippines
                    ? _DropdownField(
                        value: row.region,
                        items: _regionOptions,
                        hint: 'Select region',
                        hasError: rowErrors['region'] != null,
                        onChanged: (v) {
                          row.region = v;
                          onChanged('region');
                        },
                      )
                    : const _ReadOnlyField(value: 'N/A'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _LabeledField(
                label: '',
                errorText: rowErrors['gender'],
                child: _DropdownField(
                  value: row.gender,
                  items: _genderOptions,
                  hint: 'Select gender',
                  hasError: rowErrors['gender'] != null,
                  onChanged: (v) {
                    row.gender = v;
                    onChanged('gender');
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _LabeledField(
                label: '',
                errorText: rowErrors['ageGroup'],
                child: _DropdownField(
                  value: row.ageGroup,
                  items: _ageGroupOptions,
                  hint: 'Select age',
                  hasError: rowErrors['ageGroup'] != null,
                  onChanged: (v) {
                    row.ageGroup = v;
                    onChanged('ageGroup');
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _LabeledField(
                label: '',
                errorText: rowErrors['count'],
                child: _NumberInputField(
                  controller: row.countCtrl,
                  hint: '0',
                  hasError: rowErrors['count'] != null,
                  onChanged: (_) => onChanged('count'),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 24,
              // Align delete icon with the input field (not the error text)
              child: Padding(
                padding: const EdgeInsets.only(top: 11),
                child: showDelete
                    ? GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_rounded,
                          color: AppColors.accentRed,
                          size: 16,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Mobile Demographic Row ───────────────────────────────────────────────────

class _MobileDemographicRow extends StatelessWidget {
  const _MobileDemographicRow({
    required this.row,
    required this.isPhilippines,
    required this.showDelete,
    required this.rowErrors,
    required this.onDelete,
    required this.onChanged,
  });

  final DemographicRow row;
  final bool isPhilippines;
  final bool showDelete;
  final Map<String, String?> rowErrors;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rowErrors.isNotEmpty
              ? AppColors.accentRed.withOpacity(0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: '',
                  errorText: rowErrors['nationality'],
                  child: _DropdownField(
                    value: row.nationality,
                    items: _nationalityOptions,
                    hint: 'Nationality',
                    hasError: rowErrors['nationality'] != null,
                    onChanged: (v) {
                      row.nationality = v;
                      if (v != 'Philippines') row.region = null;
                      onChanged('nationality');
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledField(
                  label: '',
                  errorText: rowErrors['region'],
                  child: isPhilippines
                      ? _DropdownField(
                          value: row.region,
                          items: _regionOptions,
                          hint: 'Region',
                          hasError: rowErrors['region'] != null,
                          onChanged: (v) {
                            row.region = v;
                            onChanged('region');
                          },
                        )
                      : const _ReadOnlyField(value: 'N/A'),
                ),
              ),
              if (showDelete) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.accentRed,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: '',
                  errorText: rowErrors['gender'],
                  child: _DropdownField(
                    value: row.gender,
                    items: _genderOptions,
                    hint: 'Gender',
                    hasError: rowErrors['gender'] != null,
                    onChanged: (v) {
                      row.gender = v;
                      onChanged('gender');
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledField(
                  label: '',
                  errorText: rowErrors['ageGroup'],
                  child: _DropdownField(
                    value: row.ageGroup,
                    items: _ageGroupOptions,
                    hint: 'Age Group',
                    hasError: rowErrors['ageGroup'] != null,
                    onChanged: (v) {
                      row.ageGroup = v;
                      onChanged('ageGroup');
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: _LabeledField(
                  label: '',
                  errorText: rowErrors['count'],
                  child: _NumberInputField(
                    controller: row.countCtrl,
                    hint: '0',
                    hasError: rowErrors['count'] != null,
                    onChanged: (_) => onChanged('count'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Form Actions ─────────────────────────────────────────────────────────────

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.onClear,
    required this.onSave,
    required this.isSaving,
  });

  final VoidCallback onClear;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final saveBtn = SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.person_add_rounded,
                  size: 17, color: Colors.white),
          label: Text(
            isSaving ? 'Saving...' : 'Save Guest Entry',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ),
    );

    final clearBtn = SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: isSaving ? null : onClear,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
        child: const Text(
          'Clear Form',
          style: TextStyle(color: AppColors.textGray, fontSize: 13.5),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: saveBtn),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: clearBtn),
        ],
      );
    }

    return Row(
      children: [
        clearBtn,
        const SizedBox(width: 14),
        Expanded(child: saveBtn),
      ],
    );
  }
}

// ─── Inline Error Text ────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline_rounded,
            size: 12, color: AppColors.accentRed),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.accentRed,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
        ],
        child,
        if (errorText != null) ...[
          const SizedBox(height: 5),
          _InlineError(message: errorText!),
        ],
      ],
    );
  }
}

class _NumberInputField extends StatelessWidget {
  const _NumberInputField({
    required this.controller,
    required this.hint,
    this.hasError = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.accentRed;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
        filled: true,
        fillColor: hasError
            ? errorColor.withOpacity(0.05)
            : AppColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: hasError ? errorColor : AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: hasError ? errorColor : AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: hasError ? errorColor : AppColors.primaryCyan,
              width: 1.5),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.hasError = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.accentRed;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
        filled: true,
        fillColor: hasError
            ? errorColor.withOpacity(0.05)
            : AppColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: hasError ? errorColor : AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: hasError ? errorColor : AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: hasError ? errorColor : AppColors.primaryCyan,
              width: 1.5),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        value,
        style: const TextStyle(color: AppColors.textGray, fontSize: 13.5),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.value,
    required this.onTap,
    this.hasError = false,
  });

  final String value;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.accentRed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: hasError
              ? errorColor.withOpacity(0.05)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasError ? errorColor : AppColors.inputBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: value == 'mm/dd/yyyy'
                      ? AppColors.textSubtle
                      : AppColors.textWhite,
                  fontSize: 13.5,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: hasError ? errorColor : AppColors.textSubtle,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select option',
    this.hasError = false,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.accentRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: hasError
            ? errorColor.withOpacity(0.05)
            : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? errorColor : AppColors.inputBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
          ),
          dropdownColor: AppColors.cardBackground,
          iconEnabledColor:
              hasError ? errorColor : AppColors.textGray,
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.label);
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