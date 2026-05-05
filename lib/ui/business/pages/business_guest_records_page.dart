import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';
import '../widgets/archive_guest_dialog.dart';
import '../widgets/edit_guest_dialog.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum GuestRecordStatus { active, archived }

class GuestRecord {
  const GuestRecord({
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

  final String checkIn;
  final String checkOut;
  final String nights;
  final int guests;
  final int rooms;
  final String purpose;
  final String transport;
  final GuestRecordStatus status;
  final GuestDemographics? demographics;
}

class GuestDemographics {
  const GuestDemographics({
    required this.ageGroups,
    required this.genderDistribution,
    required this.countries,
  });

  final Map<String, int> ageGroups;
  final Map<String, int> genderDistribution;
  final Map<String, int> countries;
}

// ─── Filter Options ───────────────────────────────────────────────────────────

enum _Filter { all, active, archived }

// ─── Guest Records Page ───────────────────────────────────────────────────────

class BusinessGuestRecordsPage extends StatefulWidget {
  const BusinessGuestRecordsPage({super.key});

  @override
  State<BusinessGuestRecordsPage> createState() =>
      _BusinessGuestRecordsPageState();
}

class _BusinessGuestRecordsPageState extends State<BusinessGuestRecordsPage> {
  final List<GuestRecord> _records = [
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
    GuestRecord(
      checkIn: '2024-04-05',
      checkOut: '2024-04-07',
      nights: '2 nights',
      guests: 5,
      rooms: 2,
      purpose: 'Business',
      transport: 'Airport Shuttle',
      status: GuestRecordStatus.active,
      demographics: const GuestDemographics(
        ageGroups: {'18-25': 1, '26-35': 3, '36-50': 1},
        genderDistribution: {'Male': 3, 'Female': 2},
        countries: {'USA': 3, 'Canada': 2},
      ),
    ),
    GuestRecord(
      checkIn: '2024-04-10',
      checkOut: '2024-04-12',
      nights: '2 nights',
      guests: 8,
      rooms: 3,
      purpose: 'Leisure',
      transport: 'Private Car',
      status: GuestRecordStatus.archived,
      demographics: const GuestDemographics(
        ageGroups: {'18-25': 3, '26-35': 4, '36-50': 1},
        genderDistribution: {'Male': 5, 'Female': 3},
        countries: {'USA': 4, 'Canada': 4},
      ),
    ),
    GuestRecord(
      checkIn: '2024-04-15',
      checkOut: '2024-04-18',
      nights: '3 nights',
      guests: 20,
      rooms: 8,
      purpose: 'Conference',
      transport: 'Bus',
      status: GuestRecordStatus.active,
      demographics: const GuestDemographics(
        ageGroups: {'18-25': 5, '26-35': 10, '36-50': 5},
        genderDistribution: {'Male': 12, 'Female': 8},
        countries: {'USA': 10, 'Canada': 6, 'UK': 4},
      ),
    ),
  ];

  _Filter _activeFilter = _Filter.all;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;

  // Filter values
  DateTime? _checkInFrom;
  DateTime? _checkOutTo;
  String? _selectedCountry;
  String? _selectedPurpose;
  String? _selectedTransport;

  // Available options
  final List<String> _countryOptions = ['All', 'USA', 'Canada', 'UK'];
  final List<String> _purposeOptions = ['All', 'Leisure', 'Business', 'Conference'];
  final List<String> _transportOptions = ['All', 'Private Car', 'Airport Shuttle', 'Bus'];

  Future<void> _selectCheckInFrom(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGreen,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textWhite,
            ),
            dialogBackgroundColor: AppColors.cardBackground,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _checkInFrom = picked;
      });
    }
  }

  Future<void> _selectCheckOutTo(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGreen,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textWhite,
            ),
            dialogBackgroundColor: AppColors.cardBackground,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _checkOutTo = picked;
      });
    }
  }

  Future<void> _onArchive(GuestRecord record) async {
    final confirmed = await showArchiveGuestDialog(context);
    if (confirmed != true) return;

    setState(() {
      final idx = _records.indexOf(record);
      if (idx == -1) return;
      _records[idx] = GuestRecord(
        checkIn: record.checkIn,
        checkOut: record.checkOut,
        nights: record.nights,
        guests: record.guests,
        rooms: record.rooms,
        purpose: record.purpose,
        transport: record.transport,
        status: GuestRecordStatus.archived,
        demographics: record.demographics,
      );
    });
  }

  Future<void> _onEdit(GuestRecord record) async {
    final updated = await showEditGuestDialog(context, record: record);
    if (updated == null) return;

    setState(() {
      final idx = _records.indexOf(record);
      if (idx == -1) return;
      _records[idx] = updated;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _checkInFrom = null;
      _checkOutTo = null;
      _selectedCountry = null;
      _selectedPurpose = null;
      _selectedTransport = null;
      _searchQuery = '';
      _activeFilter = _Filter.all;
      _searchCtrl.clear();
    });
  }

  bool _matchesFilters(GuestRecord record) {
    // Check-in From filter
    if (_checkInFrom != null) {
      try {
        final recordCheckIn = DateTime.parse(record.checkIn);
        if (recordCheckIn.isBefore(_checkInFrom!)) return false;
      } catch (e) {
        // If date parsing fails, skip this filter
      }
    }

    // Check-out To filter
    if (_checkOutTo != null) {
      try {
        final recordCheckOut = DateTime.parse(record.checkOut);
        if (recordCheckOut.isAfter(_checkOutTo!)) return false;
      } catch (e) {
        // If date parsing fails, skip this filter
      }
    }

    // Country filter
    if (_selectedCountry != null && _selectedCountry != 'All') {
      final hasCountry = record.demographics?.countries.containsKey(_selectedCountry) ?? false;
      if (!hasCountry) return false;
    }

    // Purpose filter
    if (_selectedPurpose != null && _selectedPurpose != 'All') {
      if (record.purpose != _selectedPurpose) return false;
    }

    // Transport filter
    if (_selectedTransport != null && _selectedTransport != 'All') {
      if (record.transport != _selectedTransport) return false;
    }

    return true;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GuestRecord> get _filtered {
    return _records.where((r) {
      final matchesFilter = switch (_activeFilter) {
        _Filter.all => true,
        _Filter.active => r.status == GuestRecordStatus.active,
        _Filter.archived => r.status == GuestRecordStatus.archived,
      };
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          r.checkIn.contains(q) ||
          r.purpose.toLowerCase().contains(q) ||
          r.transport.toLowerCase().contains(q);
      return matchesFilter && matchesSearch && _matchesFilters(r);
    }).toList();
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
                  activeFilter: _activeFilter,
                  onFilterChanged: (f) => setState(() => _activeFilter = f),
                  showFilters: _showFilters,
                  onFilterToggle: () => setState(() => _showFilters = !_showFilters),
                  isNarrow: isNarrow,
                ),
                const SizedBox(height: 16),
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 14),
                if (_showFilters) ...[
                  _FiltersSection(
                    checkInFrom: _checkInFrom,
                    checkOutTo: _checkOutTo,
                    selectedCountry: _selectedCountry,
                    selectedPurpose: _selectedPurpose,
                    selectedTransport: _selectedTransport,
                    countryOptions: _countryOptions,
                    purposeOptions: _purposeOptions,
                    transportOptions: _transportOptions,
                    onCheckInFromTap: () => _selectCheckInFrom(context),
                    onCheckOutToTap: () => _selectCheckOutTo(context),
                    onCountryChanged: (value) => setState(() => _selectedCountry = value),
                    onPurposeChanged: (value) => setState(() => _selectedPurpose = value),
                    onTransportChanged: (value) => setState(() => _selectedTransport = value),
                    onClearAll: _clearAllFilters,
                    isNarrow: isNarrow,
                  ),
                  const SizedBox(height: 14),
                ],
                _GuestTable(
                  records: _filtered,
                  isNarrow: isNarrow,
                  onEdit: _onEdit,
                  onArchive: _onArchive,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Filters Section ──────────────────────────────────────────────────────────

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({
    required this.checkInFrom,
    required this.checkOutTo,
    required this.selectedCountry,
    required this.selectedPurpose,
    required this.selectedTransport,
    required this.countryOptions,
    required this.purposeOptions,
    required this.transportOptions,
    required this.onCheckInFromTap,
    required this.onCheckOutToTap,
    required this.onCountryChanged,
    required this.onPurposeChanged,
    required this.onTransportChanged,
    required this.onClearAll,
    required this.isNarrow,
  });

  final DateTime? checkInFrom;
  final DateTime? checkOutTo;
  final String? selectedCountry;
  final String? selectedPurpose;
  final String? selectedTransport;
  final List<String> countryOptions;
  final List<String> purposeOptions;
  final List<String> transportOptions;
  final VoidCallback onCheckInFromTap;
  final VoidCallback onCheckOutToTap;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onPurposeChanged;
  final ValueChanged<String?> onTransportChanged;
  final VoidCallback onClearAll;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = checkInFrom != null ||
        checkOutTo != null ||
        (selectedCountry != null && selectedCountry != 'All') ||
        (selectedPurpose != null && selectedPurpose != 'All') ||
        (selectedTransport != null && selectedTransport != 'All');

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Check-in From and Check-out To
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Check-in From',
                  date: checkInFrom,
                  onTap: onCheckInFromTap,
                  hint: 'mm/dd/yyyy',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDatePicker(
                  label: 'Check-out To',
                  date: checkOutTo,
                  onTap: onCheckOutToTap,
                  hint: 'mm/dd/yyyy',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Country and Purpose
          Row(
            children: [
              Expanded(
                child: _buildDropdownWithLabel(
                  label: 'Country',
                  value: selectedCountry,
                  items: countryOptions,
                  onChanged: onCountryChanged,
                  hint: 'All',
                  icon: Icons.public,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownWithLabel(
                  label: 'Purpose',
                  value: selectedPurpose,
                  items: purposeOptions,
                  onChanged: onPurposeChanged,
                  hint: 'All',
                  icon: Icons.work_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Transportation
          Row(
            children: [
              Expanded(
                child: _buildDropdownWithLabel(
                  label: 'Transportation',
                  value: selectedTransport,
                  items: transportOptions,
                  onChanged: onTransportChanged,
                  hint: 'All',
                  icon: Icons.directions_car_outlined,
                ),
              ),
              const SizedBox(width: 8),
              if (hasActiveFilters)
                Expanded(
                  child: _buildClearButton(),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Check-in From',
                date: checkInFrom,
                onTap: onCheckInFromTap,
                hint: 'mm/dd/yyyy',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(
                label: 'Check-out To',
                date: checkOutTo,
                onTap: onCheckOutToTap,
                hint: 'mm/dd/yyyy',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownWithLabel(
                label: 'Country',
                value: selectedCountry,
                items: countryOptions,
                onChanged: onCountryChanged,
                hint: 'All',
                icon: Icons.public,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownWithLabel(
                label: 'Purpose',
                value: selectedPurpose,
                items: purposeOptions,
                onChanged: onPurposeChanged,
                hint: 'All',
                icon: Icons.work_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownWithLabel(
                label: 'Transportation',
                value: selectedTransport,
                items: transportOptions,
                onChanged: onTransportChanged,
                hint: 'All',
                icon: Icons.directions_car_outlined,
              ),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(width: 16),
              _buildClearButton(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                Icon(Icons.calendar_today, color: AppColors.textSubtle, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}'
                        : hint,
                    style: TextStyle(
                      color: date != null ? AppColors.textWhite : AppColors.textSubtle,
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

  Widget _buildDropdownWithLabel({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric( vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.textSubtle, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      hint,
                      style: const TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textGray, size: 20),
              dropdownColor: AppColors.cardBackground,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 12.5,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(item),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              underline: const SizedBox(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClearButton() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClearAll,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear_all, color: AppColors.textGray, size: 16),
              const SizedBox(width: 4),
              Text(
                'Clear All',
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            ],
          ),
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
  });

  final _Filter activeFilter;
  final ValueChanged<_Filter> onFilterChanged;
  final bool showFilters;
  final VoidCallback onFilterToggle;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final filterRow = _FilterToggle(
      activeFilter: activeFilter,
      onChanged: onFilterChanged,
    );
    final toggleButton = _FilterPanelButton(
      isActive: showFilters,
      onTap: onFilterToggle,
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleSubtitle(),
          const SizedBox(height: 12),
          Row(
            children: [
              filterRow,
              const SizedBox(width: 10),
              toggleButton,
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _TitleSubtitle(),
        const Spacer(),
        filterRow,
        const SizedBox(width: 10),
        toggleButton,
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
            color: isActive ? AppColors.primaryCyan : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: isActive ? AppColors.primaryCyan : AppColors.textGray,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Filters',
              style: TextStyle(
                color: isActive ? AppColors.primaryCyan : AppColors.textGray,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleSubtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guest Records',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'View and manage all guest entries',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Filter Toggle ────────────────────────────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({required this.activeFilter, required this.onChanged});

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
            label: 'All',
            isActive: activeFilter == _Filter.all,
            onTap: () => onChanged(_Filter.all),
          ),
          _FilterTab(
            label: 'Active',
            isActive: activeFilter == _Filter.active,
            onTap: () => onChanged(_Filter.active),
          ),
          _FilterTab(
            label: 'Archived',
            isActive: activeFilter == _Filter.archived,
            onTap: () => onChanged(_Filter.archived),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
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
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textGray,
            fontSize: 13,
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
  final ValueChanged<String> onChanged;

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
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Search by date or purpose...',
          hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSubtle,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        ),
      ),
    );
  }
}

// ─── Guest Table ──────────────────────────────────────────────────────────────

class _GuestTable extends StatelessWidget {
  const _GuestTable({
    required this.records,
    required this.isNarrow,
    required this.onEdit,
    required this.onArchive,
  });

  final List<GuestRecord> records;
  final bool isNarrow;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          if (!isNarrow) _TableHeader(),
          if (!isNarrow) const Divider(color: AppColors.cardBorder, height: 1),
          records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No records found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ),
                )
              : Column(
                  children: records.map((r) {
                    return Column(
                      children: [
                        if (isNarrow)
                          _RecordCard(
                            record: r,
                            onEdit: onEdit,
                            onArchive: onArchive,
                          )
                        else
                          _RecordRow(
                            record: r,
                            onEdit: onEdit,
                            onArchive: onArchive,
                          ),
                        if (r != records.last)
                          const Divider(color: AppColors.cardBorder, height: 1),
                      ],
                    );
                  }).toList(),
                ),
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
          Expanded(flex: 3, child: _HeaderCell('Transport')),
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

// ─── Table Row (wide screens) ─────────────────────────────────────────────────

class _RecordRow extends StatefulWidget {
  const _RecordRow({
    required this.record,
    required this.onEdit,
    required this.onArchive,
  });

  final GuestRecord record;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onArchive;

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  r.checkIn,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  r.checkOut,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  r.nights,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${r.guests}',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${r.rooms}',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  r.purpose,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  r.transport,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(flex: 2, child: _StatusBadge(status: r.status)),
              Expanded(
                flex: 2,
                child: _ActionButtons(
                  status: r.status,
                  expanded: _expanded,
                  onToggleExpand: () => setState(() => _expanded = !_expanded),
                  onEdit: () => widget.onEdit(r),
                  onArchive: () => widget.onArchive(r),
                ),
              ),
            ],
          ),
        ),
        if (_expanded) _ExpandedDetails(record: r),
      ],
    );
  }
}

// ─── Record Card (narrow screens) ────────────────────────────────────────────

class _RecordCard extends StatefulWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onArchive,
  });

  final GuestRecord record;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onArchive;

  @override
  _RecordCardState createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
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
                    Text(
                      r.checkIn,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.checkOut}  •  ${r.nights}',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                      ),
                    ),
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
              _InfoChip(label: 'Guests', value: '${r.guests}'),
              _InfoChip(label: 'Rooms', value: '${r.rooms}'),
              _InfoChip(label: 'Purpose', value: r.purpose),
              _InfoChip(label: 'Transport', value: r.transport),
            ],
          ),
          if (r.status == GuestRecordStatus.active) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _IconBtn(
                  icon: Icons.edit_outlined,
                  onTap: () => widget.onEdit(widget.record),
                ),
                const SizedBox(width: 8),
                _IconBtn(
                  icon: Icons.archive_outlined,
                  onTap: () => widget.onArchive(widget.record),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textGray,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
          if (_expanded) _ExpandedDetails(record: r),
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
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSubtle),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: AppColors.textGray),
          ),
        ],
      ),
    );
  }
}

// ─── Expanded Details ─────────────────────────────────────────────────────────

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({required this.record});
  final GuestRecord record;

  @override
  Widget build(BuildContext context) {
    final demographics = record.demographics;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Demographic Breakdown',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          if (demographics != null) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Table(
                border: TableBorder.all(
                  color: AppColors.cardBorder,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppColors.cardBackground),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Category',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Details',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Age Groups',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: demographics.ageGroups.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Gender',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: demographics.genderDistribution.entries.map(
                            (entry) {
                              return Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Countries',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: demographics.countries.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'No demographic data available for this entry.',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final GuestRecordStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == GuestRecordStatus.active;
    final color = isActive ? AppColors.accentGreen : AppColors.textGray;
    final label = isActive ? 'active' : 'archived';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.expanded,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onArchive,
  });

  final GuestRecordStatus status;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (status == GuestRecordStatus.active) ...[
          _IconBtn(icon: Icons.edit_outlined, onTap: onEdit),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.archive_outlined, onTap: onArchive),
          const SizedBox(width: 8),
        ],
        _IconBtn(
          icon: expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          onTap: onToggleExpand,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.textGray, size: 17),
    );
  }
}