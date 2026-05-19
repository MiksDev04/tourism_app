import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';
import '../widgets/edit_guest_dialog.dart';
import '../../../api/business_guest_record_api.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _residenceCategoryLabel(String cat) {
  switch (cat) {
    case 'philippine_resident':
      return 'PH Resident';
    case 'overseas_filipino':
      return 'OFW';
    case 'foreign_resident':
      return 'Foreign';
    default:
      return '—';
  }
}

Color _residenceCategoryColor(String cat) {
  switch (cat) {
    case 'philippine_resident':
      return const Color(0xFF10B981); // green
    case 'overseas_filipino':
      return const Color(0xFF3B82F6); // blue
    case 'foreign_resident':
      return const Color(0xFFF59E0B); // amber
    default:
      return AppColors.textGray;
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

enum GuestRecordStatus { active, archived }

class GuestBreakdownEntry {
  const GuestBreakdownEntry({
    required this.country,
    this.philippinesRegion,
    required this.sex,
    required this.ageGroup,
    required this.count,
    this.isOverseas = false,
    this.residenceCategory = 'unspecified_guest',
  });

  final String  country;
  final String? philippinesRegion;
  final String  sex;
  final String  ageGroup;
  final int     count;
  final bool    isOverseas;
  final String  residenceCategory;
}

class GuestDemographics {
  const GuestDemographics({
    required this.ageGroups,
    required this.sexDistribution,
    required this.countries,
    required this.breakdowns,
  });

  final Map<String, int>      ageGroups;
  final Map<String, int>      sexDistribution;
  final Map<String, int>      countries;
  final List<GuestBreakdownEntry> breakdowns;
}

class GuestRecord {
  const GuestRecord({
    required this.id,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.guests,
    required this.rooms,
    required this.purpose,
    required this.transport,
    required this.status,
    required this.demographics,
  });

  final String           id;
  final String           checkIn;
  final String           checkOut;
  final String           nights;
  final int              guests;
  final int              rooms;
  final String           purpose;
  final String           transport;
  final GuestRecordStatus status;
  final GuestDemographics? demographics;
}

// ─── Filter Options ───────────────────────────────────────────────────────────

enum _Filter { active, archived }

// ─── Guest Records Page ───────────────────────────────────────────────────────

class BusinessGuestRecordsPage extends StatefulWidget {
  const BusinessGuestRecordsPage({super.key});

  @override
  State<BusinessGuestRecordsPage> createState() =>
      _BusinessGuestRecordsPageState();
}

class _BusinessGuestRecordsPageState extends State<BusinessGuestRecordsPage> {
  final _api = BusinessGuestRecordApi();

  String? _businessId;
  List<GuestRecord> _records = [];
  bool _isLoading = true;
  String? _loadError;

  _Filter _activeFilter = _Filter.active;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;

  // Advanced filter values
  DateTime? _checkInFrom;
  DateTime? _checkOutTo;
  String? _selectedPurpose;
  String? _selectedTransport;

  final List<String> _purposeOptions = [
    'All',
    'Leisure',
    'Business',
    'Education',
    'Medical',
    'Religious',
    'Others',
  ];
  final List<String> _transportOptions = [
    'All',
    'Private Car',
    'Bus',
    'Van',
    'Motorcycle',
    'Tricycle',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = await _api.fetchBusinessId();
    if (!mounted) return;
    if (id == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'Business account not found.';
      });
      return;
    }
    _businessId = id;
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (_businessId == null) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final result = await _api.fetchGuestRecords(_businessId!);
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _records   = result.data ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _loadError = result.error;
      });
    }
  }

  // ── Date pickers ────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isCheckIn ? _checkInFrom : _checkOutTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary:            AppColors.primaryCyan,
            onPrimary:          Colors.black,
            primaryContainer:   AppColors.primaryCyan.withOpacity(0.25),
            onPrimaryContainer: AppColors.primaryCyan,
            surface:            AppColors.cardBackground,
            onSurface:          AppColors.textWhite,
            onSurfaceVariant:   AppColors.textGray,
            outline:            AppColors.cardBorder,
            surfaceVariant:     AppColors.inputBackground,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor:    AppColors.cardBackground,
            surfaceTintColor:   Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:         BorderSide(color: AppColors.cardBorder),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryCyan),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isCheckIn) {
        _checkInFrom = picked;
      } else {
        _checkOutTo = picked;
      }
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _onRestore(GuestRecord record) async {
    final result = await _api.restoreRecord(record.id);
    if (!mounted) return;

    if (result.isSuccess) {
      _updateLocalStatus(record, GuestRecordStatus.active);
      _showSnack('Guest record restored.', color: AppColors.accentGreen);
    } else {
      _showSnack(result.error ?? 'Failed to restore.', isError: true);
    }
  }

  Future<void> _onEdit(GuestRecord record) async {
    final updated = await showEditGuestDialog(context, record: record);
    if (updated == null || !mounted) return;

    final result = await _api.updateRecord(
      recordId:          updated.id,
      checkIn:           updated.checkIn,
      checkOut:          updated.checkOut,
      totalGuests:       updated.guests,
      roomsOccupied:     updated.rooms,
      purposeOfVisit:    updated.purpose,
      transportationMode: updated.transport,
      breakdowns:        updated.demographics?.breakdowns ?? [],
    );
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        final idx = _records.indexWhere((r) => r.id == record.id);
        if (idx != -1) _records[idx] = updated;
      });
      _showSnack('Guest record updated.');
    } else {
      _showSnack(result.error ?? 'Failed to update.', isError: true);
    }
  }

  void _updateLocalStatus(GuestRecord record, GuestRecordStatus status) {
    setState(() {
      final idx = _records.indexWhere((r) => r.id == record.id);
      if (idx == -1) return;
      _records[idx] = GuestRecord(
        id:           record.id,
        checkIn:      record.checkIn,
        checkOut:     record.checkOut,
        nights:       record.nights,
        guests:       record.guests,
        rooms:        record.rooms,
        purpose:      record.purpose,
        transport:    record.transport,
        status:       status,
        demographics: record.demographics,
      );
    });
  }

  void _showSnack(String msg, {bool isError = false, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: isError
          ? AppColors.accentRed
          : (color ?? AppColors.primaryCyan),
      duration: const Duration(seconds: 3),
    ));
  }

  void _clearAllFilters() {
    setState(() {
      _checkInFrom       = null;
      _checkOutTo        = null;
      _selectedPurpose   = null;
      _selectedTransport = null;
      _searchQuery       = '';
      _searchCtrl.clear();
    });
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  bool _matchesAdvancedFilters(GuestRecord r) {
    if (_checkInFrom != null) {
      try {
        if (DateTime.parse(r.checkIn).isBefore(_checkInFrom!)) return false;
      } catch (_) {}
    }
    if (_checkOutTo != null) {
      try {
        if (DateTime.parse(r.checkOut).isAfter(_checkOutTo!)) return false;
      } catch (_) {}
    }
    if (_selectedPurpose != null && _selectedPurpose != 'All') {
      if (r.purpose != _selectedPurpose) return false;
    }
    if (_selectedTransport != null && _selectedTransport != 'All') {
      if (r.transport != _selectedTransport) return false;
    }
    return true;
  }

  List<GuestRecord> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      final matchesStatus = switch (_activeFilter) {
        _Filter.active   => r.status == GuestRecordStatus.active,
        _Filter.archived => r.status == GuestRecordStatus.archived,
      };
      final matchesSearch = q.isEmpty ||
          r.checkIn.contains(q) ||
          r.purpose.toLowerCase().contains(q) ||
          r.transport.toLowerCase().contains(q);
      return matchesStatus && matchesSearch && _matchesAdvancedFilters(r);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Guest Records',
      selectedIndex: 2,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(
                  activeFilter:   _activeFilter,
                  onFilterChanged: (f) => setState(() => _activeFilter = f),
                  showFilters:    _showFilters,
                  onFilterToggle: () =>
                      setState(() => _showFilters = !_showFilters),
                  isNarrow:       isNarrow,
                  totalRecords:   _filtered.length,
                ),
                const SizedBox(height: 16),
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged:  (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 14),
                if (_showFilters) ...[
                  _FiltersSection(
                    checkInFrom:        _checkInFrom,
                    checkOutTo:         _checkOutTo,
                    selectedPurpose:    _selectedPurpose,
                    selectedTransport:  _selectedTransport,
                    purposeOptions:     _purposeOptions,
                    transportOptions:   _transportOptions,
                    onCheckInFromTap:   () => _pickDate(context, true),
                    onCheckOutToTap:    () => _pickDate(context, false),
                    onPurposeChanged:   (v) =>
                        setState(() => _selectedPurpose = v),
                    onTransportChanged: (v) =>
                        setState(() => _selectedTransport = v),
                    onClearAll: _clearAllFilters,
                    isNarrow:   isNarrow,
                  ),
                  const SizedBox(height: 14),
                ],
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryCyan),
                    ),
                  )
                else if (_loadError != null)
                  _ErrorBanner(message: _loadError!, onRetry: _loadRecords)
                else
                  _GuestTable(
                    records:   _filtered,
                    isNarrow:  isNarrow,
                    onEdit:    _onEdit,
                    onRestore: _onRestore,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String   message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.accentRed, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.accentRed, fontSize: 13.5)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: AppColors.primaryCyan)),
          ),
        ],
      ),
    );
  }
}

// ─── Filters Section ──────────────────────────────────────────────────────────

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({
    required this.checkInFrom,
    required this.checkOutTo,
    required this.selectedPurpose,
    required this.selectedTransport,
    required this.purposeOptions,
    required this.transportOptions,
    required this.onCheckInFromTap,
    required this.onCheckOutToTap,
    required this.onPurposeChanged,
    required this.onTransportChanged,
    required this.onClearAll,
    required this.isNarrow,
  });

  final DateTime? checkInFrom;
  final DateTime? checkOutTo;
  final String?   selectedPurpose;
  final String?   selectedTransport;
  final List<String> purposeOptions;
  final List<String> transportOptions;
  final VoidCallback onCheckInFromTap;
  final VoidCallback onCheckOutToTap;
  final ValueChanged<String?> onPurposeChanged;
  final ValueChanged<String?> onTransportChanged;
  final VoidCallback onClearAll;
  final bool isNarrow;

  bool get _hasActiveFilters =>
      checkInFrom != null ||
      checkOutTo  != null ||
      (selectedPurpose   != null && selectedPurpose   != 'All') ||
      (selectedTransport != null && selectedTransport != 'All');

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: _DateFilter(
                    label: 'Check-in From',
                    date:  checkInFrom,
                    onTap: onCheckInFromTap)),
            const SizedBox(width: 8),
            Expanded(
                child: _DateFilter(
                    label: 'Check-out To',
                    date:  checkOutTo,
                    onTap: onCheckOutToTap)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _DropFilter(
                    label:     'Purpose',
                    value:     selectedPurpose,
                    items:     purposeOptions,
                    onChanged: onPurposeChanged,
                    icon:      Icons.work_outline)),
            const SizedBox(width: 8),
            Expanded(
                child: _DropFilter(
                    label:     'Transportation',
                    value:     selectedTransport,
                    items:     transportOptions,
                    onChanged: onTransportChanged,
                    icon:      Icons.directions_car_outlined)),
          ]),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 10),
            _ClearAllBtn(onTap: onClearAll),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
            child: _DateFilter(
                label: 'Check-in From',
                date:  checkInFrom,
                onTap: onCheckInFromTap)),
        const SizedBox(width: 12),
        Expanded(
            child: _DateFilter(
                label: 'Check-out To',
                date:  checkOutTo,
                onTap: onCheckOutToTap)),
        const SizedBox(width: 12),
        Expanded(
            child: _DropFilter(
                label:     'Purpose',
                value:     selectedPurpose,
                items:     purposeOptions,
                onChanged: onPurposeChanged,
                icon:      Icons.work_outline)),
        const SizedBox(width: 12),
        Expanded(
            child: _DropFilter(
                label:     'Transportation',
                value:     selectedTransport,
                items:     transportOptions,
                onChanged: onTransportChanged,
                icon:      Icons.directions_car_outlined)),
        if (_hasActiveFilters) ...[
          const SizedBox(width: 12),
          _ClearAllBtn(onTap: onClearAll),
        ],
      ],
    );
  }
}

// ─── Filter Widgets ───────────────────────────────────────────────────────────

class _DateFilter extends StatelessWidget {
  const _DateFilter(
      {required this.label, required this.date, required this.onTap});

  final String    label;
  final DateTime? date;
  final VoidCallback onTap;

  String get _display {
    if (date == null) return 'mm/dd/yyyy';
    return '${date!.month.toString().padLeft(2, '0')}/'
        '${date!.day.toString().padLeft(2, '0')}/${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.textSubtle, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _display,
                    style: TextStyle(
                      color: date != null
                          ? AppColors.textWhite
                          : AppColors.textSubtle,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropFilter extends StatelessWidget {
  const _DropFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  final String    label;
  final String?   value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData  icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:      value,
              isDense:    true,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.textSubtle, size: 14),
                    const SizedBox(width: 6),
                    const Text('All',
                        style: TextStyle(
                            color: AppColors.textSubtle, fontSize: 12.5)),
                  ],
                ),
              ),
              dropdownColor:    AppColors.cardBackground,
              iconEnabledColor: AppColors.textGray,
              style: const TextStyle(
                  color: AppColors.textWhite, fontSize: 12.5),
              items: items
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(e))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClearAllBtn extends StatelessWidget {
  const _ClearAllBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear_all, color: AppColors.textGray, size: 15),
            SizedBox(width: 5),
            Text('Clear All',
                style: TextStyle(color: AppColors.textGray, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.showFilters,
    required this.onFilterToggle,
    required this.isNarrow,
    required this.totalRecords,
  });

  final _Filter  activeFilter;
  final ValueChanged<_Filter> onFilterChanged;
  final bool     showFilters;
  final VoidCallback onFilterToggle;
  final bool     isNarrow;
  final int      totalRecords;

  @override
  Widget build(BuildContext context) {
    final filterRow =
        _FilterToggle(activeFilter: activeFilter, onChanged: onFilterChanged);
    final toggleBtn =
        _FilterPanelButton(isActive: showFilters, onTap: onFilterToggle);

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleSubtitle(totalRecords: totalRecords),
          const SizedBox(height: 12),
          Row(children: [
            filterRow,
            const SizedBox(width: 10),
            toggleBtn,
          ]),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _TitleSubtitle(totalRecords: totalRecords),
        const Spacer(),
        filterRow,
        const SizedBox(width: 10),
        toggleBtn,
      ],
    );
  }
}

class _TitleSubtitle extends StatelessWidget {
  const _TitleSubtitle({required this.totalRecords});
  final int totalRecords;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guest Records ($totalRecords)',
          style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text('View and manage all guest entries',
            style: TextStyle(color: AppColors.textGray, fontSize: 13)),
      ],
    );
  }
}

class _FilterPanelButton extends StatelessWidget {
  const _FilterPanelButton({required this.isActive, required this.onTap});
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryCyan.withOpacity(0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? AppColors.primaryCyan : AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded,
                color: isActive ? AppColors.primaryCyan : AppColors.textGray,
                size: 16),
            const SizedBox(width: 6),
            Text('Filters',
                style: TextStyle(
                    color: isActive
                        ? AppColors.primaryCyan
                        : AppColors.textGray,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Toggle (Active / Archived) ───────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  const _FilterToggle(
      {required this.activeFilter, required this.onChanged});

  final _Filter activeFilter;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterTab(
            label:    'Active',
            isActive: activeFilter == _Filter.active,
            onTap:    () => onChanged(_Filter.active),
          ),
          _FilterTab(
            label:    'Archived',
            isActive: activeFilter == _Filter.archived,
            onTap:    () => onChanged(_Filter.archived),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab(
      {required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool   isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd])
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      isActive ? Colors.white : AppColors.textGray,
            fontSize:   13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged:  onChanged,
        style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Search by date, purpose, or transport...',
          hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppColors.textSubtle, size: 20),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        ),
      ),
    );
  }
}

// ─── Guest Table ──────────────────────────────────────────────────────────────

class _GuestTable extends StatefulWidget {
  const _GuestTable({
    required this.records,
    required this.isNarrow,
    required this.onEdit,
    required this.onRestore,
  });

  final List<GuestRecord>      records;
  final bool                   isNarrow;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onRestore;

  @override
  State<_GuestTable> createState() => _GuestTableState();
}

class _GuestTableState extends State<_GuestTable> {
  int _currentPage = 1;
  int _pageSize    = 10;

  List<GuestRecord> get _records => widget.records;

  int get _totalPages {
    if (_records.isEmpty) return 1;
    return (_records.length / _pageSize).ceil();
  }

  void _prev() =>
      setState(() { if (_currentPage > 1)            _currentPage--; });
  void _next() =>
      setState(() { if (_currentPage < _totalPages)  _currentPage++; });

  void _setPageSize(int size) =>
      setState(() { _pageSize = size; _currentPage = 1; });

  @override
  void didUpdateWidget(covariant _GuestTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final total = _totalPages;
    if (_currentPage > total) setState(() => _currentPage = total);
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = widget.isNarrow;

    final start       = (_currentPage - 1) * _pageSize;
    final pageRecords = _records.skip(start).take(_pageSize).toList();

    return Container(
      decoration: BoxDecoration(
        color:  AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          if (!isNarrow) ...[
            _TableHeader(),
            const Divider(color: AppColors.cardBorder, height: 1),
          ],
          if (_records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('No records found.',
                    style: TextStyle(color: AppColors.textGray)),
              ),
            )
          else
            ...pageRecords.map((r) {
              final isLast = r == pageRecords.last;
              return Column(
                children: [
                  if (isNarrow)
                    _RecordCard(
                        record:    r,
                        onEdit:    widget.onEdit,
                        onRestore: widget.onRestore)
                  else
                    _RecordRow(
                        record:    r,
                        onEdit:    widget.onEdit,
                        onRestore: widget.onRestore),
                  if (!isLast)
                    const Divider(color: AppColors.cardBorder, height: 1),
                ],
              );
            }),

          if (_records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: LayoutBuilder(builder: (context, constraints) {
                final narrowControls =
                    constraints.maxWidth < 420 || isNarrow;
                return narrowControls
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SmallIconBtn(
                                  icon:    Icons.chevron_left,
                                  onTap:   _prev,
                                  enabled: _currentPage > 1),
                              const SizedBox(width: 8),
                              Text('Page $_currentPage of $_totalPages',
                                  style: const TextStyle(
                                      color: AppColors.textGray,
                                      fontSize: 12)),
                              const SizedBox(width: 8),
                              _SmallIconBtn(
                                  icon:    Icons.chevron_right,
                                  onTap:   _next,
                                  enabled: _currentPage < _totalPages),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _CompactPageSizeDropdown(
                              value:     _pageSize,
                              onChanged: _setPageSize),
                        ],
                      )
                    : Row(
                        children: [
                          _SmallIconBtn(
                              icon:    Icons.chevron_left,
                              onTap:   _prev,
                              enabled: _currentPage > 1),
                          const SizedBox(width: 8),
                          Text('Page $_currentPage of $_totalPages',
                              style: const TextStyle(
                                  color: AppColors.textGray, fontSize: 12)),
                          const Spacer(),
                          _CompactPageSizeDropdown(
                              value: _pageSize, onChanged: _setPageSize),
                          const SizedBox(width: 8),
                          _SmallIconBtn(
                              icon:    Icons.chevron_right,
                              onTap:   _next,
                              enabled: _currentPage < _totalPages),
                        ],
                      );
              }),
            ),
        ],
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn(
      {required this.icon, required this.onTap, this.enabled = true});
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 30,
        width:  34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryCyan : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon,
            size:  18,
            color: enabled ? Colors.white : AppColors.textGray),
      ),
    );
  }
}

class _CompactPageSizeDropdown extends StatelessWidget {
  const _CompactPageSizeDropdown(
      {required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [5, 10, 20, 50];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Show',
              style: TextStyle(color: AppColors.textGray, fontSize: 12)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value:    value,
              isDense:  true,
              items: options
                  .map((o) => DropdownMenuItem<int>(
                      value: o,
                      child: Text('$o',
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
              dropdownColor: AppColors.cardBackground,
              style: const TextStyle(
                  color: AppColors.textWhite, fontSize: 13),
              iconEnabledColor: AppColors.textGray,
            ),
          ),
          const SizedBox(width: 6),
          const Text('per page',
              style: TextStyle(color: AppColors.textGray, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Check-in')),
          Expanded(flex: 3, child: _HeaderCell('Check-out')),
          Expanded(flex: 2, child: _HeaderCell('Nights')),
          Expanded(flex: 1, child: _HeaderCell('Guests')),
          Expanded(flex: 1, child: _HeaderCell('Rooms')),
          Expanded(flex: 2, child: _HeaderCell('Purpose')),
          Expanded(flex: 2, child: _HeaderCell('Transport')),
          Expanded(flex: 2, child: _HeaderCell('Status')),
          Expanded(flex: 2, child: _HeaderCell('Actions')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w500));
  }
}

// ─── Table Row (wide) ─────────────────────────────────────────────────────────

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.record,
    required this.onEdit,
    required this.onRestore,
  });

  final GuestRecord record;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onRestore;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(r.checkIn,
                  style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600))),
          Expanded(
              flex: 3,
              child: Text(r.checkOut,
                  style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(r.nights,
                  style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13))),
          Expanded(
              flex: 1,
              child: Text('${r.guests}',
                  style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600))),
          Expanded(
              flex: 1,
              child: Text('${r.rooms}',
                  style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(r.purpose,
                  style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(r.transport,
                  style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 0),
                  child: _StatusBadge(status: r.status),
                ),
              )),
          Expanded(
            flex: 2,
            child: _ActionButtons(
              status:    r.status,
              onEdit:    () => onEdit(r),
              onRestore: () => onRestore(r),
              onView:    () => _showRecordModal(context, r),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Record Card (narrow) ─────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onRestore,
  });

  final GuestRecord record;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onRestore;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.checkIn,
                        style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${r.checkOut}  •  ${r.nights}',
                        style: const TextStyle(
                            color: AppColors.textGray, fontSize: 12)),
                  ],
                ),
              ),
              _StatusBadge(status: r.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _InfoChip(label: 'Guests',    value: '${r.guests}'),
              _InfoChip(label: 'Rooms',     value: '${r.rooms}'),
              _InfoChip(label: 'Purpose',   value: r.purpose),
              _InfoChip(label: 'Transport', value: r.transport),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _IconBtn(
                icon:    Icons.visibility_outlined,
                tooltip: 'View Record',
                onTap:   () => _showRecordModal(context, r),
              ),
              if (r.status == GuestRecordStatus.active) ...[
                const SizedBox(width: 8),
                _IconBtn(
                    icon:    Icons.edit_outlined,
                    tooltip: 'Edit',
                    onTap:   () => onEdit(r)),
              ] else ...[
                const SizedBox(width: 8),
                _IconBtn(
                    icon:    Icons.unarchive_outlined,
                    tooltip: 'Restore',
                    onTap:   () => onRestore(r)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12),
        children: [
          TextSpan(
              text:  '$label: ',
              style: const TextStyle(color: AppColors.textSubtle)),
          TextSpan(
              text:  value,
              style: const TextStyle(color: AppColors.textGray)),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final GuestRecordStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == GuestRecordStatus.active;
    final color    = isActive ? AppColors.accentGreen : AppColors.textGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:  color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isActive ? 'active' : 'archived',
        style: TextStyle(
            color:      color,
            fontSize:   11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.onEdit,
    required this.onRestore,
    required this.onView,
  });

  final GuestRecordStatus status;
  final VoidCallback onEdit;
  final VoidCallback onRestore;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBtn(
          icon:    Icons.visibility_outlined,
          tooltip: 'View Record',
          onTap:   onView,
        ),
        const SizedBox(width: 8),
        if (status == GuestRecordStatus.active)
          _IconBtn(icon: Icons.edit_outlined,    tooltip: 'Edit',    onTap: onEdit)
        else
          _IconBtn(icon: Icons.unarchive_outlined, tooltip: 'Restore', onTap: onRestore),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(
      {required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String?  tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.textGray, size: 17),
    );
    return tooltip != null
        ? Tooltip(message: tooltip!, child: btn)
        : btn;
  }
}

// ─── Full Record Modal ────────────────────────────────────────────────────────

void _showRecordModal(BuildContext context, GuestRecord record) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => _RecordDetailModal(record: record),
  );
}

class _RecordDetailModal extends StatelessWidget {
  const _RecordDetailModal({required this.record});
  final GuestRecord record;

  @override
  Widget build(BuildContext context) {
    final demo     = record.demographics;
    final isNarrow = MediaQuery.of(context).size.width < 560;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 40,
        vertical:   32,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primaryCyan, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Guest Record Details',
                      style: TextStyle(
                          color:      AppColors.textWhite,
                          fontSize:   15,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textGray, size: 20),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ModalSectionLabel('Stay Information'),
                    const SizedBox(height: 10),
                    _StayInfoGrid(record: record),
                    const SizedBox(height: 20),

                    const Divider(color: AppColors.cardBorder, height: 1),
                    const SizedBox(height: 20),

                    const _ModalSectionLabel(
                        'Guest Breakdown by Segment'),
                    const SizedBox(height: 10),
                    if (demo == null || demo.breakdowns.isEmpty)
                      const Text(
                        'No demographic data available.',
                        style: TextStyle(
                            color: AppColors.textSubtle, fontSize: 13),
                      )
                    else ...[
                      _BreakdownTable(breakdowns: demo.breakdowns),
                      const SizedBox(height: 20),

                      const _ModalSectionLabel('Age Groups'),
                      const SizedBox(height: 10),
                      _StatGrid(entries: demo.ageGroups),
                      const SizedBox(height: 20),

                      const _ModalSectionLabel('Sex Distribution'),
                      const SizedBox(height: 10),
                      _StatGrid(entries: demo.sexDistribution),
                      const SizedBox(height: 20),

                      const _ModalSectionLabel('Country / Region'),
                      const SizedBox(height: 10),
                      _StatGrid(entries: demo.countries),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textGray,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stay Info Grid ───────────────────────────────────────────────────────────

class _StayInfoGrid extends StatelessWidget {
  const _StayInfoGrid({required this.record});
  final GuestRecord record;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Check-in',          record.checkIn),
      ('Check-out',         record.checkOut),
      ('Length of Stay',    record.nights),
      ('Total Guests',      '${record.guests}'),
      ('Rooms Occupied',    '${record.rooms}'),
      ('Purpose of Visit',  record.purpose),
      ('Mode of Transport', record.transport),
    ];

    const spacing = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing:    spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:  AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color:      AppColors.textGray,
                        fontSize:   11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color:      AppColors.textWhite,
                        fontSize:   13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Modal Helpers ────────────────────────────────────────────────────────────

class _ModalSectionLabel extends StatelessWidget {
  const _ModalSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color:         AppColors.textWhite,
        fontSize:      12.5,
        fontWeight:    FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ─── Breakdown Table ──────────────────────────────────────────────────────────

class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({required this.breakdowns});
  final List<GuestBreakdownEntry> breakdowns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 520;

      // Narrow: stacked cards
      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: breakdowns.map((b) {
            final catColor = _residenceCategoryColor(b.residenceCategory);
            return Container(
              margin:  const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:  AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(b.country,
                            style: const TextStyle(
                                color:      AppColors.textWhite,
                                fontSize:   13.5,
                                fontWeight: FontWeight.w700)),
                      ),
                      // Residence category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:  catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: catColor.withOpacity(0.35)),
                        ),
                        child: Text(
                          _residenceCategoryLabel(b.residenceCategory),
                          style: TextStyle(
                              color:      catColor,
                              fontSize:   11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing:    8,
                    runSpacing: 6,
                    children: [
                      _BreakdownInfoChip(
                          label: 'Region',
                          value: b.philippinesRegion ?? '—'),
                      if (b.isOverseas)
                        _BreakdownInfoChip(label: 'OFW', value: 'Yes'),
                      _BreakdownInfoChip(label: 'Sex',   value: b.sex),
                      _BreakdownInfoChip(label: 'Age',   value: b.ageGroup),
                      _BreakdownInfoChip(label: 'Count', value: '${b.count}'),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }

      // Wide: table layout — Country | Region | OFW | Residence | Sex | Age | Count
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: AppColors.cardBorder, width: 0.5),
            ),
            columnWidths: const {
              0: FlexColumnWidth(2.0), // Country
              1: FlexColumnWidth(1.8), // Region
              2: FlexColumnWidth(0.7), // OFW
              3: FlexColumnWidth(1.6), // Residence Category
              4: FlexColumnWidth(1.0), // Sex
              5: FlexColumnWidth(1.3), // Age Group
              6: FlexColumnWidth(0.7), // Count
            },
            children: [
              TableRow(
                decoration:
                    BoxDecoration(color: AppColors.inputBackground),
                children: const [
                  _TCell('Country',    isHeader: true),
                  _TCell('Region',     isHeader: true),
                  _TCell('OFW',        isHeader: true),
                  _TCell('Residence',  isHeader: true),
                  _TCell('Sex',        isHeader: true),
                  _TCell('Age Group',  isHeader: true),
                  _TCell('Count',      isHeader: true),
                ],
              ),
              ...breakdowns.map(
                (b) => TableRow(
                  children: [
                    _TCell(b.country),
                    _TCell(b.philippinesRegion ?? '—'),
                    _TCell(b.isOverseas ? 'Yes' : '—'),
                    _TCellBadge(
                      label: _residenceCategoryLabel(b.residenceCategory),
                      color: _residenceCategoryColor(b.residenceCategory),
                    ),
                    _TCell(b.sex),
                    _TCell(b.ageGroup),
                    _TCell('${b.count}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _BreakdownInfoChip extends StatelessWidget {
  const _BreakdownInfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:  AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text:  '$label: ',
                style: const TextStyle(
                    color: AppColors.textSubtle, fontSize: 12)),
            TextSpan(
                text:  value,
                style: const TextStyle(
                    color: AppColors.textGray, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TCell extends StatelessWidget {
  const _TCell(this.text, {this.isHeader = false});
  final String text;
  final bool   isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Text(
        text,
        style: TextStyle(
          color:      isHeader ? AppColors.textGray : AppColors.textWhite,
          fontSize:   11.5,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// Coloured badge cell used for the Residence Category column.
class _TCellBadge extends StatelessWidget {
  const _TCellBadge({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color:  color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color:      color,
              fontSize:   10.5,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.entries});
  final Map<String, int> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('—',
          style: TextStyle(color: AppColors.textSubtle, fontSize: 12));
    }
    return Wrap(
      spacing:    8,
      runSpacing: 8,
      children: entries.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:  AppColors.inputBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text:  e.key,
                  style: const TextStyle(
                      color: AppColors.textGray, fontSize: 12),
                ),
                const TextSpan(
                    text:  '  ', style: TextStyle(fontSize: 12)),
                TextSpan(
                  text:  '${e.value}',
                  style: const TextStyle(
                    color:      AppColors.primaryCyan,
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}