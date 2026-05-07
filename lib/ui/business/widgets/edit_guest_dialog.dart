import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../pages/business_guest_records_page.dart';

// ─── Public model for one demographic row ────────────────────────────────────

class DemographicEntry {
  DemographicEntry({
    this.nationality = '',
    this.region = 'N/A',
    this.gender = '',
    this.ageGroup = '',
    this.count = 0,
  });

  String nationality;
  String region;
  String gender;
  String ageGroup;
  int count;

  DemographicEntry copyWith({
    String? nationality,
    String? region,
    String? gender,
    String? ageGroup,
    int? count,
  }) => DemographicEntry(
    nationality: nationality ?? this.nationality,
    region: region ?? this.region,
    gender: gender ?? this.gender,
    ageGroup: ageGroup ?? this.ageGroup,
    count: count ?? this.count,
  );
}

// ─── Show helper ─────────────────────────────────────────────────────────────

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

// ─── Dialog widget ────────────────────────────────────────────────────────────

class _EditGuestDialog extends StatefulWidget {
  const _EditGuestDialog({required this.record});
  final GuestRecord record;

  @override
  State<_EditGuestDialog> createState() => _EditGuestDialogState();
}

class _EditGuestDialogState extends State<_EditGuestDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _checkInCtrl;
  late final TextEditingController _checkOutCtrl;
  late final TextEditingController _guestsCtrl;
  late final TextEditingController _roomsCtrl;
  late String _purpose;
  late String _transport;
  String _lengthOfStay = '0 nights';

  late List<DemographicEntry> _demoRows;

  static const _purposes = ['Leisure', 'Business', 'Event', 'Other'];
  static const _transports = [
    'Private Car',
    'Bus',
    'Van',
    'Motorcycle',
    'Taxi',
    'Other',
  ];
  // Replace your current static lists with these corrected ones:

  static const _genderOptions = ['Male', 'Female', 'Other'];

  static const _ageGroupOptions = ['18-25', '26-35', '36-45', '46-60', '60+'];

  static const _countries = [
    'Philippines',
    'USA',
    'Japan',
    'South Korea',
    'Australia',
    'UK', // Changed from 'United Kingdom' to match error message
    'Canada',
    'Germany',
    'France',
    'China',
    'Other',
  ];
  static const _phRegions = [
    'N/A',
    'NCR',
    'Ilocos',
    'Cagayan Valley',
    'Central Luzon',
    'CALABARZON',
    'MIMAROPA',
    'Bicol',
    'Western Visayas',
    'Central Visayas',
    'Eastern Visayas',
    'Zamboanga Peninsula',
    'Northern Mindanao',
    'Davao',
    'SOCCSKSARGEN',
    'Caraga',
    'BARMM',
    'CAR',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _checkInCtrl = TextEditingController(text: r.checkIn);
    _checkOutCtrl = TextEditingController(text: r.checkOut);
    _guestsCtrl = TextEditingController(text: r.guests.toString());
    _roomsCtrl = TextEditingController(text: r.rooms.toString());
    _purpose = _purposes.contains(r.purpose) ? r.purpose : _purposes.first;
    _transport = _transports.contains(r.transport)
        ? r.transport
        : _transports.first;
    _lengthOfStay = r.nights;

    // Convert GuestDemographics back to List<DemographicEntry> for editing
    if (r.demographics != null) {
      _demoRows = _convertFromGuestDemographics(r.demographics!);
    } else {
      _demoRows = [DemographicEntry()];
    }
  }

  // ✅ FIXED: Properly convert GuestDemographics to List<DemographicEntry>
  List<DemographicEntry> _convertFromGuestDemographics(GuestDemographics demo) {
    final rows = <DemographicEntry>[];

    // Get the maximum number of rows from all maps
    final maxRows = [
      demo.countries.length,
      demo.genderDistribution.length,
      demo.ageGroups.length,
    ].reduce((a, b) => a > b ? a : b);

    if (maxRows == 0) return [DemographicEntry()];

    // Convert countries map to list of entries
    final countryEntries = demo.countries.entries.toList();
    final genderEntries = demo.genderDistribution.entries.toList();
    final ageEntries = demo.ageGroups.entries.toList();

    for (int i = 0; i < maxRows; i++) {
      String nationality = 'Other';
      String region = 'N/A';

      // Get country info if available
      if (i < countryEntries.length) {
        final countryEntry = countryEntries[i];
        final country = countryEntry.key;

        // Parse Philippines with region
        if (country.startsWith('Philippines')) {
          nationality = 'Philippines';
          final regionMatch = RegExp(r'\((.+?)\)').firstMatch(country);
          region = regionMatch?.group(1) ?? 'N/A';
        } else {
          nationality = country;
          region = 'N/A';
        }
      }

      // Get counts - use the maximum count from available data
      int count = 0;
      if (i < countryEntries.length) count = countryEntries[i].value;
      if (i < genderEntries.length && genderEntries[i].value > count) {
        count = genderEntries[i].value;
      }
      if (i < ageEntries.length && ageEntries[i].value > count) {
        count = ageEntries[i].value;
      }

      rows.add(
        DemographicEntry(
          nationality: nationality,
          region: region,
          gender: i < genderEntries.length ? genderEntries[i].key : '',
          ageGroup: i < ageEntries.length ? ageEntries[i].key : '',
          count: count,
        ),
      );
    }

    return rows.isEmpty ? [DemographicEntry()] : rows;
  }

  @override
  void dispose() {
    _checkInCtrl.dispose();
    _checkOutCtrl.dispose();
    _guestsCtrl.dispose();
    _roomsCtrl.dispose();
    super.dispose();
  }

  void _recalcNights() {
    final checkIn = DateTime.tryParse(_checkInCtrl.text);
    final checkOut = DateTime.tryParse(_checkOutCtrl.text);
    if (checkIn != null && checkOut != null && checkOut.isAfter(checkIn)) {
      final nights = checkOut.difference(checkIn).inDays;
      setState(() => _lengthOfStay = '$nights night${nights == 1 ? '' : 's'}');
    } else {
      setState(() => _lengthOfStay = '0 nights');
    }
  }

  int get _demoTotal => _demoRows.fold(0, (sum, e) => sum + e.count);
  int get _totalGuests => int.tryParse(_guestsCtrl.text.trim()) ?? 0;

  void _addRow() => setState(() => _demoRows.add(DemographicEntry()));
  void _removeRow(int i) => setState(() => _demoRows.removeAt(i));

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Verify demographic total matches guest count
    if (_demoTotal != _totalGuests) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demographic breakdown total ($_demoTotal) must equal total guests ($_totalGuests)',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Convert List<DemographicEntry> to GuestDemographics
    final demographics = _convertToGuestDemographics(_demoRows);

    final updated = GuestRecord(
      checkIn: _checkInCtrl.text.trim(),
      checkOut: _checkOutCtrl.text.trim(),
      nights: _lengthOfStay,
      guests: _totalGuests,
      rooms: int.tryParse(_roomsCtrl.text.trim()) ?? widget.record.rooms,
      purpose: _purpose,
      transport: _transport,
      status: widget.record.status,
      demographics: demographics,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Guest record updated successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Close dialog after showing snackbar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    });
  }

  GuestDemographics _convertToGuestDemographics(List<DemographicEntry> rows) {
    final ageGroups = <String, int>{};
    final genderDistribution = <String, int>{};
    final countries = <String, int>{};

    for (final row in rows) {
      // Age groups
      final ageGroup = row.ageGroup;
      if (ageGroup.isNotEmpty) {
        ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + row.count;
      }

      // Gender distribution
      final gender = row.gender;
      if (gender.isNotEmpty) {
        genderDistribution[gender] =
            (genderDistribution[gender] ?? 0) + row.count;
      }

      // Countries (with region info if Philippines)
      String country = row.nationality;
      if (country == 'Philippines' && row.region != 'N/A') {
        country = 'Philippines (${row.region})';
      }
      if (country.isNotEmpty && country != 'Other') {
        countries[country] = (countries[country] ?? 0) + row.count;
      }
    }

    return GuestDemographics(
      ageGroups: ageGroups,
      genderDistribution: genderDistribution,
      countries: countries,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
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
            children: [
              _TitleBar(onClose: () => Navigator.of(context).pop()),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isNarrow ? 14 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stay Information ─────────────────────────────
                        _SectionCard(
                          title: 'Stay Information',
                          child: Column(
                            children: [
                              _ResponsiveRow(
                                isNarrow: isNarrow,
                                children: [
                                  _FieldCol(
                                    label: 'Check-in Date *',
                                    child: _DateField(
                                      controller: _checkInCtrl,
                                      hint: 'yyyy-mm-dd',
                                      onPicked: _recalcNights,
                                    ),
                                  ),
                                  _FieldCol(
                                    label: 'Check-out Date *',
                                    child: _DateField(
                                      controller: _checkOutCtrl,
                                      hint: 'yyyy-mm-dd',
                                      onPicked: _recalcNights,
                                    ),
                                  ),
                                  _FieldCol(
                                    label: 'Length of Stay',
                                    child: _ReadOnlyField(value: _lengthOfStay),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _ResponsiveRow(
                                isNarrow: isNarrow,
                                children: [
                                  _FieldCol(
                                    label: 'Total Guests *',
                                    child: _NumberField(
                                      controller: _guestsCtrl,
                                      hint: 'e.g. 10',
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  _FieldCol(
                                    label: 'Rooms Occupied *',
                                    child: _NumberField(
                                      controller: _roomsCtrl,
                                      hint: 'e.g. 3',
                                    ),
                                  ),
                                  _FieldCol(
                                    label: 'Purpose of Visit *',
                                    child: _DropdownField(
                                      value: _purpose,
                                      hint: 'Select purpose',
                                      items: _purposes,
                                      onChanged: (v) => setState(
                                        () => _purpose = v ?? _purpose,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: isNarrow ? double.infinity : 210,
                                  child: _FieldCol(
                                    label: 'Mode of Transportation *',
                                    child: _DropdownField(
                                      value: _transport,
                                      hint: 'Select transportation',
                                      items: _transports,
                                      onChanged: (v) => setState(
                                        () => _transport = v ?? _transport,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Demographic Breakdown ────────────────────────
                        _SectionCard(
                          title: 'Guest Demographic Breakdown',
                          subtitle:
                              'Breakdown must sum to $_totalGuests total guests',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_demoTotal / $_totalGuests',
                                style: TextStyle(
                                  color: _demoTotal == _totalGuests
                                      ? Colors.green
                                      : AppColors.textGray,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _AddRowButton(onTap: _addRow),
                            ],
                          ),
                          child: Column(
                            children: [
                              _DemoTableHeader(isNarrow: isNarrow),
                              const SizedBox(height: 8),
                              ..._demoRows.asMap().entries.map(
                                (e) => _DemoEntryRow(
                                  key: ValueKey(e.key),
                                  index: e.key,
                                  entry: e.value,
                                  isNarrow: isNarrow,
                                  countries: _countries,
                                  phRegions: _phRegions,
                                  genderOptions: _genderOptions,
                                  ageGroupOptions: _ageGroupOptions,
                                  onChanged: (u) =>
                                      setState(() => _demoRows[e.key] = u),
                                  onRemove: _demoRows.length > 1
                                      ? () => _removeRow(e.key)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: Color(0xFFD4A017),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Example: For 10 guests — add rows like: '
                                      '5 Philippines (NCR) / Male / 26–35 = 3, '
                                      'Philippines (NCR) / Female / 26–35 = 2, '
                                      'USA / Male / 36–45 = 5',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _Footer(
                onClear: () {
                  _checkInCtrl.clear();
                  _checkOutCtrl.clear();
                  _guestsCtrl.clear();
                  _roomsCtrl.clear();
                  setState(() {
                    _purpose = _purposes.first;
                    _transport = _transports.first;
                    _lengthOfStay = '0 nights';
                    _demoRows = [DemographicEntry()];
                  });
                },
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Title bar ────────────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Guest Entry',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Edit tourist demographic data',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12.5),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textGray,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
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
                          color: AppColors.textSubtle,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Responsive row ───────────────────────────────────────────────────────────

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.children, required this.isNarrow});
  final List<Widget> children;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 12)]).toList()
              ..removeLast(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children
              .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
              .toList()
            ..removeLast(),
    );
  }
}

// ─── Field column ─────────────────────────────────────────────────────────────

class _FieldCol extends StatelessWidget {
  const _FieldCol({required this.label, required this.child});
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Demographic table header ─────────────────────────────────────────────────

class _DemoTableHeader extends StatelessWidget {
  const _DemoTableHeader({required this.isNarrow});
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) return const SizedBox.shrink();
    return const Row(
      children: [
        Expanded(flex: 3, child: _ColHead('Nationality')),
        SizedBox(width: 8),
        Expanded(flex: 3, child: _ColHead('Region (If PH)')),
        SizedBox(width: 8),
        Expanded(flex: 2, child: _ColHead('Gender')),
        SizedBox(width: 8),
        Expanded(flex: 2, child: _ColHead('Age Group')),
        SizedBox(width: 8),
        SizedBox(width: 60, child: _ColHead('Count')),
        SizedBox(width: 28),
      ],
    );
  }
}

class _ColHead extends StatelessWidget {
  const _ColHead(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSubtle,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Demographic entry row ────────────────────────────────────────────────────

class _DemoEntryRow extends StatelessWidget {
  const _DemoEntryRow({
    super.key,
    required this.index,
    required this.entry,
    required this.isNarrow,
    required this.countries,
    required this.phRegions,
    required this.genderOptions,
    required this.ageGroupOptions,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final DemographicEntry entry;
  final bool isNarrow;
  final List<String> countries;
  final List<String> phRegions;
  final List<String> genderOptions;
  final List<String> ageGroupOptions;
  final ValueChanged<DemographicEntry> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final countCtrl = TextEditingController(
      text: entry.count == 0 ? '' : '${entry.count}',
    );
    countCtrl.selection = TextSelection.collapsed(
      offset: countCtrl.text.length,
    );

    final deleteBtn = GestureDetector(
      onTap: onRemove,
      child: Icon(
        Icons.delete_rounded,
        size: 16,
        color: onRemove != null
            ? AppColors.accentRed
            : AppColors.textSubtle.withOpacity(0.3),
      ),
    );

    if (isNarrow) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _CompactDrop(
                    hint: 'Country',
                    value: entry.nationality.isEmpty ? null : entry.nationality,
                    items: countries,
                    onChanged: (v) =>
                        onChanged(entry.copyWith(nationality: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                if (onRemove != null) deleteBtn,
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _CompactDrop(
                    hint: 'Region',
                    value: entry.region,
                    items: phRegions,
                    onChanged: (v) =>
                        onChanged(entry.copyWith(region: v ?? 'N/A')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactDrop(
                    hint: 'Gender',
                    value: entry.gender.isEmpty ? null : entry.gender,
                    items: genderOptions,
                    onChanged: (v) =>
                        onChanged(entry.copyWith(gender: v ?? '')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _CompactDrop(
                    hint: 'Age Group',
                    value: entry.ageGroup.isEmpty ? null : entry.ageGroup,
                    items: ageGroupOptions,
                    onChanged: (v) =>
                        onChanged(entry.copyWith(ageGroup: v ?? '')),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: _CountField(
                    controller: countCtrl,
                    onChanged: (v) =>
                        onChanged(entry.copyWith(count: int.tryParse(v) ?? 0)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _CompactDrop(
              hint: 'Country',
              value: entry.nationality.isEmpty ? null : entry.nationality,
              items: countries,
              onChanged: (v) => onChanged(entry.copyWith(nationality: v ?? '')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _CompactDrop(
              hint: 'N/A',
              value: entry.region,
              items: phRegions,
              onChanged: (v) => onChanged(entry.copyWith(region: v ?? 'N/A')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _CompactDrop(
              hint: 'Gender',
              value: entry.gender.isEmpty ? null : entry.gender,
              items: genderOptions,
              onChanged: (v) => onChanged(entry.copyWith(gender: v ?? '')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _CompactDrop(
              hint: 'Age Group',
              value: entry.ageGroup.isEmpty ? null : entry.ageGroup,
              items: ageGroupOptions,
              onChanged: (v) => onChanged(entry.copyWith(ageGroup: v ?? '')),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: _CountField(
              controller: countCtrl,
              onChanged: (v) =>
                  onChanged(entry.copyWith(count: int.tryParse(v) ?? 0)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 20, child: deleteBtn),
        ],
      ),
    );
  }
}

// ─── Add Row button ───────────────────────────────────────────────────────────

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
          // ignore: deprecated_member_use
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
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

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.onClear, required this.onSave});
  final VoidCallback onClear;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.cardBorder),
              foregroundColor: AppColors.textGray,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Clear Form',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared input decoration ──────────────────────────────────────────────────

InputDecoration _fieldDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12.5),
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

// ─── Date field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.hint,
    this.onPicked,
  });
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      decoration: _fieldDecoration(hint: hint).copyWith(
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          color: AppColors.textSubtle,
          size: 14,
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
          onPicked?.call();
        }
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

// ─── Read-only field ──────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: const TextStyle(color: AppColors.textGray, fontSize: 13),
      ),
    );
  }
}

// ─── Number field ─────────────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hint,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      decoration: _fieldDecoration(hint: hint),
      onChanged: onChanged,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final n = int.tryParse(v);
        if (n == null || n <= 0) return 'Must be > 0';
        return null;
      },
    );
  }
}

// ─── Dropdown field ───────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      hint: Text(
        hint,
        style: const TextStyle(color: AppColors.textSubtle, fontSize: 12.5),
      ),
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      dropdownColor: const Color(0xFF132035),
      decoration: _fieldDecoration(),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSubtle,
        size: 18,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

// ─── Compact dropdown (demo rows) ────────────────────────────────────────────

class _CompactDrop extends StatelessWidget {
  const _CompactDrop({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Ensure the value exists in items, otherwise use null
    final effectiveValue = (value != null && items.contains(value))
        ? value
        : null;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: Text(
            hint,
            style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
          ),
          style: const TextStyle(color: AppColors.textGray, fontSize: 12),
          dropdownColor: const Color(0xFF132035),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSubtle,
            size: 16,
          ),
          isExpanded: true,
          items: items.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(
                e,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Count field ──────────────────────────────────────────────────────────────

class _CountField extends StatelessWidget {
  const _CountField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
          filled: true,
          fillColor: AppColors.backgroundDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.4),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
