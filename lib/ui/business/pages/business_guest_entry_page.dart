import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';
import '../../../api/business_guest_entry_api.dart';

// ─── Light input colours (mirrors edit-guest dialog) ─────────────────────────

const _kInputFill   = Color(0xFFF8FAFC); // near-white field background
const _kInputBorder = Color(0xFFD1D5DB); // subtle grey border
const _kInputFocused = Color(0xFF3B82F6); // blue focus ring
const _kDropBg      = Color(0xFFFFFFFF); // pure white dropdown menu
const _kInputText   = Color(0xFF111827); // near-black text in fields
const _kInputHint   = Color(0xFF9CA3AF); // grey hint / placeholder
const _kReadOnlyFill = Color(0xFFEFF2F5); // dimmer read-only background

// ─── Models ───────────────────────────────────────────────────────────────────

class DemographicRow {
  DemographicRow()
      : nationality = null,
        region = null,
        sex = null,
        ageGroup = null,
        countCtrl = TextEditingController(text: '');

  String? nationality;
  String? region;
  String? sex;
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

const _sexOptions = ['Male', 'Female'];

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
  final _totalGuestsCtrl   = TextEditingController();
  final _roomsOccupiedCtrl = TextEditingController();
  String? _purpose;
  String? _transport;
  final _purposeOtherCtrl   = TextEditingController();
  final _transportOtherCtrl = TextEditingController();
  bool _showPurposeOther   = false;
  bool _showTransportOther = false;
  bool _isSaving = false;

  Map<String, String?> _errors   = {};
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
      _showPurposeOther   = false;
      _showTransportOther = false;
      _errors = {};
      for (final r in _rows) r.dispose();
      _rows
        ..clear()
        ..add(DemographicRow());
      _rowErrors = [{}];
    });
  }

  bool _validateAndSetErrors() {
    final errors    = <String, String?>{};
    final rowErrors = List.generate(_rows.length, (_) => <String, String?>{});
    bool hasError   = false;

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

    final guests = int.tryParse(_totalGuestsCtrl.text);
    if (guests == null || guests <= 0) {
      errors['totalGuests'] = 'Enter at least 1 guest.';
      hasError = true;
    } else if (guests > 9999) {
      errors['totalGuests'] = 'Value seems too large.';
      hasError = true;
    }

    final rooms = int.tryParse(_roomsOccupiedCtrl.text);
    if (rooms == null || rooms <= 0) {
      errors['roomsOccupied'] = 'Enter at least 1 room.';
      hasError = true;
    } else if (guests != null && guests > 0 && rooms > guests) {
      errors['roomsOccupied'] = 'Cannot exceed total guests.';
      hasError = true;
    }

    if (_purpose == null) {
      errors['purpose'] = 'Please select a purpose of visit.';
      hasError = true;
    } else if (_purpose == 'Others' && _purposeOtherCtrl.text.trim().isEmpty) {
      errors['purposeOther'] = 'Please specify the purpose.';
      hasError = true;
    }

    if (_transport == null) {
      errors['transport'] = 'Please select a mode of transportation.';
      hasError = true;
    } else if (_transport == 'Others' &&
        _transportOtherCtrl.text.trim().isEmpty) {
      errors['transportOther'] = 'Please specify the transportation.';
      hasError = true;
    }

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
      if (row.sex == null) {
        rowErrors[i]['sex'] = 'Required';
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
      if (row.nationality != null && row.sex != null && row.ageGroup != null) {
        final key =
            '${row.nationality}|${row.region}|${row.sex}|${row.ageGroup}';
        if (!seen.add(key)) {
          rowErrors[i]['nationality'] = 'Duplicate row — merge counts instead';
          hasError = true;
        }
      }
    }

    if (!hasError && guests != null && guests > 0) {
      if (_demographicTotal != guests) {
        errors['demographicSum'] =
            'Demographic total ($_demographicTotal) must equal total guests ($guests).';
        hasError = true;
      }
    }

    setState(() {
      _errors    = errors;
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
                  sex: r.sex!,
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
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final firstDate = isCheckIn
        ? DateTime(2020)
        : (_checkIn != null
            ? _checkIn!.add(const Duration(days: 1))
            : today);
    final lastDate = isCheckIn ? today : today.add(const Duration(days: 730));
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
      // Light date-picker to match edit dialog
      builder: (ctx, child) => Theme(
        data: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3B82F6),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF111827),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
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
              style:
                  const TextStyle(color: AppColors.accentRed, fontSize: 13),
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
    if (dt == null) return '';
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return _SectionCard(
      title: 'Stay Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Check-in / Check-out / Nights ─────────────────────────────────
          // On mobile: check-in + check-out side-by-side (row), length below.
          // On desktop: all three in one row.
          if (isMobile) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FieldCol(
                    label: 'Check-in Date *',
                    errorText: errors['checkIn'],
                    child: _EntryDateField(
                      value: _fmt(checkIn),
                      hasError: errors['checkIn'] != null,
                      onTap: onPickCheckIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FieldCol(
                    label: 'Check-out Date *',
                    errorText: errors['checkOut'],
                    child: _EntryDateField(
                      value: _fmt(checkOut),
                      hasError: errors['checkOut'] != null,
                      onTap: onPickCheckOut,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FieldCol(
              label: 'Length of Stay',
              child: _EntryReadOnlyField(
                value: nights > 0 ? '$nights night${nights > 1 ? 's' : ''}' : '—',
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FieldCol(
                    label: 'Check-in Date *',
                    errorText: errors['checkIn'],
                    child: _EntryDateField(
                      value: _fmt(checkIn),
                      hasError: errors['checkIn'] != null,
                      onTap: onPickCheckIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FieldCol(
                    label: 'Check-out Date *',
                    errorText: errors['checkOut'],
                    child: _EntryDateField(
                      value: _fmt(checkOut),
                      hasError: errors['checkOut'] != null,
                      onTap: onPickCheckOut,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FieldCol(
                    label: 'Length of Stay',
                    child: _EntryReadOnlyField(
                      value: nights > 0
                          ? '$nights night${nights > 1 ? 's' : ''}'
                          : '—',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // ── Total Guests / Rooms ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldCol(
                  label: 'Total Guests *',
                  errorText: errors['totalGuests'],
                  child: _EntryNumberField(
                    controller: totalGuestsCtrl,
                    hint: 'e.g. 10',
                    hasError: errors['totalGuests'] != null,
                    onChanged: onGuestsChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FieldCol(
                  label: 'Rooms Occupied *',
                  errorText: errors['roomsOccupied'],
                  child: _EntryNumberField(
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
          if (isMobile) ...[
            _FieldCol(
              label: 'Purpose of Visit *',
              errorText: errors['purpose'],
              child: _EntryDropdownField(
                value: purpose,
                items: _purposeOptions,
                hint: 'Select purpose',
                hasError: errors['purpose'] != null,
                onChanged: onPurposeChanged,
              ),
            ),
            if (showPurposeOther) ...[
              const SizedBox(height: 10),
              _FieldCol(
                label: 'Please specify *',
                errorText: errors['purposeOther'],
                child: _EntryTextField(
                  controller: purposeOtherCtrl,
                  hint: 'Specify purpose',
                  hasError: errors['purposeOther'] != null,
                  onChanged: onPurposeOtherChanged,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _FieldCol(
              label: 'Mode of Transportation *',
              errorText: errors['transport'],
              child: _EntryDropdownField(
                value: transport,
                items: _transportOptions,
                hint: 'Select transportation',
                hasError: errors['transport'] != null,
                onChanged: onTransportChanged,
              ),
            ),
            if (showTransportOther) ...[
              const SizedBox(height: 10),
              _FieldCol(
                label: 'Please specify *',
                errorText: errors['transportOther'],
                child: _EntryTextField(
                  controller: transportOtherCtrl,
                  hint: 'Specify transportation',
                  hasError: errors['transportOther'] != null,
                  onChanged: onTransportOtherChanged,
                ),
              ),
            ],
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldCol(
                        label: 'Purpose of Visit *',
                        errorText: errors['purpose'],
                        child: _EntryDropdownField(
                          value: purpose,
                          items: _purposeOptions,
                          hint: 'Select purpose',
                          hasError: errors['purpose'] != null,
                          onChanged: onPurposeChanged,
                        ),
                      ),
                      if (showPurposeOther) ...[
                        const SizedBox(height: 10),
                        _FieldCol(
                          label: 'Please specify *',
                          errorText: errors['purposeOther'],
                          child: _EntryTextField(
                            controller: purposeOtherCtrl,
                            hint: 'Specify purpose',
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
                      _FieldCol(
                        label: 'Mode of Transportation *',
                        errorText: errors['transport'],
                        child: _EntryDropdownField(
                          value: transport,
                          items: _transportOptions,
                          hint: 'Select transportation',
                          hasError: errors['transport'] != null,
                          onChanged: onTransportChanged,
                        ),
                      ),
                      if (showTransportOther) ...[
                        const SizedBox(height: 10),
                        _FieldCol(
                          label: 'Please specify *',
                          errorText: errors['transportOther'],
                          child: _EntryTextField(
                            controller: transportOtherCtrl,
                            hint: 'Specify transportation',
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
  final void Function(int rowIndex, String fieldKey) onRowChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile  = MediaQuery.of(context).size.width < 600;
    final totalLabel = total > 0 ? '$total' : '?';
    final sumMatch   = total > 0 && currentSum == total;
    final sumColor   = currentSum == 0
        ? AppColors.textGray
        : sumMatch
            ? const Color(0xFF00C48C)
            : AppColors.accentRed;
    final sumError = errors['demographicSum'];

    return _SectionCard(
      title: 'Guest Demographic Breakdown',
      subtitle: 'Must sum to $totalLabel total guests',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$currentSum / $totalLabel',
            style: TextStyle(
              color: sumColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          _AddRowButton(onTap: onAddRow),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sumError != null) ...[
            const SizedBox(height: 4),
            _InlineError(message: sumError),
            const SizedBox(height: 10),
          ],

          // Column headers (desktop only)
          if (!isMobile)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _ColHeader('Nationality')),
                  SizedBox(width: 8),
                  Expanded(flex: 3, child: _ColHeader('Region (If PH)')),
                  SizedBox(width: 8),
                  Expanded(flex: 2, child: _ColHeader('Sex')),
                  SizedBox(width: 8),
                  Expanded(flex: 2, child: _ColHeader('Age Group')),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: _ColHeader('Count')),
                  SizedBox(width: 28),
                ],
              ),
            ),

          ...List.generate(rows.length, (i) {
            final row  = rows[i];
            final rErr = i < rowErrors.length ? rowErrors[i] : <String, String?>{};
            final isPhilippines = row.nationality == 'Philippines';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: isMobile
                  ? _MobileDemoRow(
                      row: row,
                      isPhilippines: isPhilippines,
                      showDelete: rows.length > 1,
                      rowErrors: rErr,
                      onDelete: () => onRemoveRow(i),
                      onChanged: (fieldKey) => onRowChanged(i, fieldKey),
                    )
                  : _DesktopDemoRow(
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
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFFD4A017), size: 13),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Each row represents a unique combination of nationality, region, sex, and age group. Add multiple rows to cover all guest segments.',
                  style: TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 11,
                    height: 1.5,
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

class _DesktopDemoRow extends StatelessWidget {
  const _DesktopDemoRow({
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: _CompactDropWithError(
                errorText: rowErrors['nationality'],
                child: _CompactDrop(
                  hint: 'Country',
                  value: row.nationality,
                  items: _nationalityOptions,
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
              flex: 3,
              child: _CompactDropWithError(
                errorText: rowErrors['region'],
                child: _CompactDrop(
                  hint: 'N/A',
                  value: isPhilippines ? row.region : null,
                  items: _regionOptions,
                  enabled: isPhilippines,
                  onChanged: (v) {
                    row.region = v;
                    onChanged('region');
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _CompactDropWithError(
                errorText: rowErrors['sex'],
                child: _CompactDrop(
                  hint: 'Sex',
                  value: row.sex,
                  items: _sexOptions,
                  onChanged: (v) {
                    row.sex = v;
                    onChanged('sex');
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _CompactDropWithError(
                errorText: rowErrors['ageGroup'],
                child: _CompactDrop(
                  hint: 'Age Group',
                  value: row.ageGroup,
                  items: _ageGroupOptions,
                  onChanged: (v) {
                    row.ageGroup = v;
                    onChanged('ageGroup');
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: _CompactDropWithError(
                errorText: rowErrors['count'],
                child: _CompactCountField(
                  controller: row.countCtrl,
                  hasError: rowErrors['count'] != null,
                  onChanged: (_) => onChanged('count'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
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
          ],
        ),
      ],
    );
  }
}

// ─── Mobile Demographic Row ───────────────────────────────────────────────────

class _MobileDemoRow extends StatelessWidget {
  const _MobileDemoRow({
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
        color: AppColors.backgroundDark,
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
          // Row 1: Nationality + Region (+ delete)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _CompactDropWithError(
                  errorText: rowErrors['nationality'],
                  child: _CompactDrop(
                    hint: 'Country',
                    value: row.nationality,
                    items: _nationalityOptions,
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
                child: _CompactDropWithError(
                  errorText: rowErrors['region'],
                  child: _CompactDrop(
                    hint: 'Region',
                    value: isPhilippines ? row.region : null,
                    items: _regionOptions,
                    enabled: isPhilippines,
                    onChanged: (v) {
                      row.region = v;
                      onChanged('region');
                    },
                  ),
                ),
              ),
              if (showDelete) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.accentRed,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Sex + Age Group + Count
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _CompactDropWithError(
                  errorText: rowErrors['sex'],
                  child: _CompactDrop(
                    hint: 'Sex',
                    value: row.sex,
                    items: _sexOptions,
                    onChanged: (v) {
                      row.sex = v;
                      onChanged('sex');
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactDropWithError(
                  errorText: rowErrors['ageGroup'],
                  child: _CompactDrop(
                    hint: 'Age Group',
                    value: row.ageGroup,
                    items: _ageGroupOptions,
                    onChanged: (v) {
                      row.ageGroup = v;
                      onChanged('ageGroup');
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: _CompactDropWithError(
                  errorText: rowErrors['count'],
                  child: _CompactCountField(
                    controller: row.countCtrl,
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    final saveBtn = SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onSave,
        icon: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.person_add_rounded,
                size: 17, color: Colors.white),
        label: Text(
          isSaving ? 'Saving...' : 'Save Guest Entry',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
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
          foregroundColor: AppColors.textGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
        child: const Text(
          'Clear Form',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
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

// ─── Shared Section Card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ─── Field Column (label + child + optional error) ────────────────────────────

class _FieldCol extends StatelessWidget {
  const _FieldCol({
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
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 5),
          _InlineError(message: errorText!),
        ],
      ],
    );
  }
}

// ─── Inline Error ─────────────────────────────────────────────────────────────

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
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Add Row Button ───────────────────────────────────────────────────────────

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.textWhite, size: 14),
            SizedBox(width: 4),
            Text(
              '+ Add Row',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Column Header ────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSubtle,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Compact Drop with error wrapper ─────────────────────────────────────────

class _CompactDropWithError extends StatelessWidget {
  const _CompactDropWithError({required this.child, this.errorText});
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (errorText == null) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 3),
        _InlineError(message: errorText!),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INPUT WIDGETS — light style matching the edit-guest dialog
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _lightDecoration({String? hint, bool hasError = false}) {
  final borderColor = hasError ? AppColors.accentRed : _kInputBorder;
  final focusColor  = hasError ? AppColors.accentRed : _kInputFocused;
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _kInputHint, fontSize: 12.5),
    filled: true,
    fillColor: hasError ? AppColors.accentRed.withOpacity(0.04) : _kInputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: focusColor, width: 1.4),
    ),
  );
}

// ── Date picker field ─────────────────────────────────────────────────────────

class _EntryDateField extends StatelessWidget {
  const _EntryDateField({
    required this.value,
    required this.onTap,
    this.hasError = false,
  });
  final String value;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppColors.accentRed : _kInputBorder;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasError
              ? AppColors.accentRed.withOpacity(0.04)
              : _kInputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? 'yyyy-mm-dd' : value,
                style: TextStyle(
                  color: value.isEmpty ? _kInputHint : _kInputText,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: hasError ? AppColors.accentRed : _kInputHint,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Read-only field ───────────────────────────────────────────────────────────

class _EntryReadOnlyField extends StatelessWidget {
  const _EntryReadOnlyField({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kReadOnlyFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kInputBorder),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      ),
    );
  }
}

// ── Number input field ────────────────────────────────────────────────────────

class _EntryNumberField extends StatelessWidget {
  const _EntryNumberField({
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
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: const TextStyle(color: _kInputText, fontSize: 13),
      decoration: _lightDecoration(hint: hint, hasError: hasError),
    );
  }
}

// ── Text input field ──────────────────────────────────────────────────────────

class _EntryTextField extends StatelessWidget {
  const _EntryTextField({
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: _kInputText, fontSize: 13),
      decoration: _lightDecoration(hint: hint, hasError: hasError),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _EntryDropdownField extends StatelessWidget {
  const _EntryDropdownField({
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
    final borderColor = hasError ? AppColors.accentRed : _kInputBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.accentRed.withOpacity(0.04)
            : _kInputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(color: _kInputHint, fontSize: 13),
          ),
          dropdownColor: _kDropBg,
          iconEnabledColor: hasError ? AppColors.accentRed : _kInputHint,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
          ),
          style: const TextStyle(color: _kInputText, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e,
                        style: const TextStyle(
                            color: _kInputText, fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Compact dropdown for demographic rows ─────────────────────────────────────

class _CompactDrop extends StatelessWidget {
  const _CompactDrop({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveValue =
        (value != null && items.contains(value)) ? value : null;
    final fillColor = enabled ? _kInputFill : _kReadOnlyFill;
    final textColor =
        enabled ? _kInputText : const Color(0xFF9CA3AF);
    final hintColor =
        enabled ? _kInputHint : const Color(0xFFD1D5DB);
    final iconColor =
        enabled ? _kInputHint : const Color(0xFFD1D5DB);
    final borderColor =
        enabled ? _kInputBorder : const Color(0xFFE5E7EB);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: Text(hint,
              style: TextStyle(color: hintColor, fontSize: 12)),
          style: TextStyle(color: textColor, fontSize: 12),
          dropdownColor: _kDropBg,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: iconColor, size: 16),
          isExpanded: true,
          onChanged: enabled ? onChanged : null,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e,
                        style: TextStyle(
                            color: textColor, fontSize: 12)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Compact count field for demographic rows ──────────────────────────────────

class _CompactCountField extends StatelessWidget {
  const _CompactCountField({
    required this.controller,
    required this.onChanged,
    this.hasError = false,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppColors.accentRed : _kInputBorder;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(color: _kInputText, fontSize: 13),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: _kInputHint, fontSize: 12),
          filled: true,
          fillColor: hasError
              ? AppColors.accentRed.withOpacity(0.04)
              : _kInputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kInputFocused, width: 1.4),
          ),
        ),
      ),
    );
  }
}