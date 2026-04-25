import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class DemographicRow {
  DemographicRow()
      : nationality = 'Country',
        region = 'N/A',
        gender = 'Gender',
        ageGroup = 'Age Group',
        countCtrl = TextEditingController(text: '0');

  String nationality;
  String region;
  String gender;
  String ageGroup;
  final TextEditingController countCtrl;

  void dispose() => countCtrl.dispose();
}

// ─── Options ──────────────────────────────────────────────────────────────────

const _purposeOptions = [
  'Select purpose', 'Leisure', 'Business', 'Education',
  'Medical', 'Religious', 'Others',
];

const _transportOptions = [
  'Select transportation', 'Private Car', 'Bus', 'Van',
  'Motorcycle', 'Tricycle', 'Others',
];

const _nationalityOptions = [
  'Country', 'Philippines', 'USA', 'Japan',
  'Korea', 'China', 'Others',
];

const _regionOptions = [
  'N/A', 'NCR', 'Laguna', 'Cavite',
  'Batangas', 'Quezon', 'Others',
];

const _genderOptions = ['Gender', 'Male', 'Female', 'Other'];

const _ageGroupOptions = [
  'Age Group', '0–17', '18–25', '26–35',
  '36–45', '46–60', '60+',
];

// ─── Guest Entry Page ─────────────────────────────────────────────────────────

class BusinessGuestEntryPage extends StatefulWidget {
  const BusinessGuestEntryPage({super.key});

  @override
  State<BusinessGuestEntryPage> createState() => _BusinessGuestEntryPageState();
}

class _BusinessGuestEntryPageState extends State<BusinessGuestEntryPage> {
  // Stay Info
  DateTime? _checkIn;
  DateTime? _checkOut;
  final _totalGuestsCtrl   = TextEditingController();
  final _roomsOccupiedCtrl = TextEditingController();
  String _purpose   = 'Select purpose';
  String _transport = 'Select transportation';

  // Demographic rows
  final List<DemographicRow> _rows = [DemographicRow()];

  int get _nightsCount {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays.clamp(0, 999);
  }

  int get _demographicTotal {
    return _rows.fold(0, (sum, r) => sum + (int.tryParse(r.countCtrl.text) ?? 0));
  }

  int get _totalGuests => int.tryParse(_totalGuestsCtrl.text) ?? 0;

  void _addRow() => setState(() => _rows.add(DemographicRow()));

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _clearForm() {
    setState(() {
      _checkIn = null;
      _checkOut = null;
      _totalGuestsCtrl.clear();
      _roomsOccupiedCtrl.clear();
      _purpose   = 'Select purpose';
      _transport = 'Select transportation';
      for (final r in _rows) r.dispose();
      _rows
        ..clear()
        ..add(DemographicRow());
    });
  }

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryCyan,
            surface: AppColors.cardBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut != null && _checkOut!.isBefore(picked)) _checkOut = null;
      } else {
        _checkOut = picked;
      }
    });
  }

  @override
  void dispose() {
    _totalGuestsCtrl.dispose();
    _roomsOccupiedCtrl.dispose();
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
            _PageHeader(),
            const SizedBox(height: 20),
            _StayInfoCard(
              checkIn: _checkIn,
              checkOut: _checkOut,
              nights: _nightsCount,
              totalGuestsCtrl: _totalGuestsCtrl,
              roomsOccupiedCtrl: _roomsOccupiedCtrl,
              purpose: _purpose,
              transport: _transport,
              onPickCheckIn: () => _pickDate(context, true),
              onPickCheckOut: () => _pickDate(context, false),
              onPurposeChanged: (v) => setState(() => _purpose = v!),
              onTransportChanged: (v) => setState(() => _transport = v!),
              onGuestsChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _DemographicCard(
              rows: _rows,
              total: _totalGuests,
              currentSum: _demographicTotal,
              onAddRow: _addRow,
              onRemoveRow: _removeRow,
              onRowChanged: () => setState(() {}),
            ),
            const SizedBox(height: 20),
            _FormActions(
              onClear: _clearForm,
              onSave: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
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
    required this.onPickCheckIn,
    required this.onPickCheckOut,
    required this.onPurposeChanged,
    required this.onTransportChanged,
    required this.onGuestsChanged,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final TextEditingController totalGuestsCtrl;
  final TextEditingController roomsOccupiedCtrl;
  final String purpose;
  final String transport;
  final VoidCallback onPickCheckIn;
  final VoidCallback onPickCheckOut;
  final ValueChanged<String?> onPurposeChanged;
  final ValueChanged<String?> onTransportChanged;
  final ValueChanged<String> onGuestsChanged;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'mm/dd/yyyy';
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
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

          // Check-in / Check-out / Nights
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Check-in Date *',
                  child: _DatePickerField(
                    value: _formatDate(checkIn),
                    onTap: onPickCheckIn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _LabeledField(
                  label: 'Check-out Date *',
                  child: _DatePickerField(
                    value: _formatDate(checkOut),
                    onTap: onPickCheckOut,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _LabeledField(
                  label: 'Length of Stay',
                  child: _ReadOnlyField(value: '$nights nights'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Guests / Rooms Occupied / Purpose
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Total Guests *',
                  child: _InputField(
                    controller: totalGuestsCtrl,
                    hint: 'e.g. 10',
                    keyboardType: TextInputType.number,
                    onChanged: onGuestsChanged,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _LabeledField(
                  label: 'Rooms Occupied *',
                  child: _InputField(
                    controller: roomsOccupiedCtrl,
                    hint: 'e.g. 3',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _LabeledField(
                  label: 'Purpose of Visit *',
                  child: _DropdownField(
                    value: purpose,
                    items: _purposeOptions,
                    onChanged: onPurposeChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mode of Transportation
          SizedBox(
            width: 480,
            child: _LabeledField(
              label: 'Mode of Transportation *',
              child: _DropdownField(
                value: transport,
                items: _transportOptions,
                onChanged: onTransportChanged,
              ),
            ),
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
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onRowChanged,
  });

  final List<DemographicRow> rows;
  final int total;
  final int currentSum;
  final VoidCallback onAddRow;
  final ValueChanged<int> onRemoveRow;
  final VoidCallback onRowChanged;

  @override
  Widget build(BuildContext context) {
    final totalLabel = total > 0 ? '$total' : '?';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                    'Breakdown must sum to $totalLabel total guests',
                    style: const TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Counter
              Text(
                '$currentSum / $totalLabel',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              // Add Row button
              GestureDetector(
                onTap: onAddRow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4)),
                  ),
                  child: const Row(
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
          const SizedBox(height: 16),

          // Column headers
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
                SizedBox(width: 30), // space for delete icon
              ],
            ),
          ),

          // Rows
          ...List.generate(rows.length, (i) {
            final row = rows[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DemographicRowWidget(
                row: row,
                showDelete: rows.length > 1,
                onDelete: () => onRemoveRow(i),
                onChanged: onRowChanged,
              ),
            );
          }),

          const SizedBox(height: 8),

          // Hint
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Example: For 10 guests — add rows like: 5 Philippines (NCR) / Male / 26–35 = 3, Philippines (NCR) / Female / 26–35 = 2, USA / Male / 36–45 = 5',
                  style: const TextStyle(
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

class _DemographicRowWidget extends StatelessWidget {
  const _DemographicRowWidget({
    required this.row,
    required this.showDelete,
    required this.onDelete,
    required this.onChanged,
  });

  final DemographicRow row;
  final bool showDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _DropdownField(
            value: row.nationality,
            items: _nationalityOptions,
            onChanged: (v) {
              row.nationality = v!;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _DropdownField(
            value: row.region,
            items: _regionOptions,
            onChanged: (v) {
              row.region = v!;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _DropdownField(
            value: row.gender,
            items: _genderOptions,
            onChanged: (v) {
              row.gender = v!;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _DropdownField(
            value: row.ageGroup,
            items: _ageGroupOptions,
            onChanged: (v) {
              row.ageGroup = v!;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: _InputField(
            controller: row.countCtrl,
            hint: '0',
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 24,
          child: showDelete
              ? GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSubtle,
                    size: 16,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Form Actions ─────────────────────────────────────────────────────────────

class _FormActions extends StatelessWidget {
  const _FormActions({required this.onClear, required this.onSave});

  final VoidCallback onClear;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Clear Form
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: onClear,
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
        ),
        const SizedBox(width: 14),

        // Save Guest Entry
        Expanded(
          child: SizedBox(
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
                onPressed: onSave,
                icon: const Icon(Icons.person_add_rounded,
                    size: 17, color: Colors.white),
                label: const Text(
                  'Save Guest Entry',
                  style: TextStyle(
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
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
        filled: true,
        fillColor: AppColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primaryCyan, width: 1.5),
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
  const _DatePickerField({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
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
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSubtle, size: 15),
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
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
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