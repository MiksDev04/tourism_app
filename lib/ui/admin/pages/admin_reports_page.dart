import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/review_report_modal.dart';
import '../../shared/layouts/admin_layout.dart';
import '../models/report_models.dart';
import '../../../core/services/excel_generator_service.dart';

// ─── Sample Data ──────────────────────────────────────────────────────────────

// ─── Admin Reports Page ───────────────────────────────────────────────────────

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // Filter state
  bool _showFilters = false;
  String _filterBusiness = '';
  String _filterMonth = '';
  String _filterYear = '';
  String _filterStatus = '';
  bool _isExporting = false;

  // Filter options
  final List<String> _months = [
    'All Months',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> _years = ['All Years', '2024', '2023', '2022'];

  final List<String> _statuses = [
    'All Statuses',
    'Submitted',
    'Approved',
    'Rejected',
    'Draft',
  ];

  // Make reports mutable
  late List<Report> _reports;
  final Set<String> _selectedReportKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _reports = [
      Report(
        business: 'Grand Hotel San Pablo',
        period: 'April 2024',
        totalGuests: 39,
        checkIns: 4,
        submitted: '2024-05-02',
        status: ReportStatus.submitted,
      ),
      Report(
        business: 'Grand Hotel San Pablo',
        period: 'March 2024',
        totalGuests: 16,
        checkIns: 2,
        submitted: '2024-04-03',
        status: ReportStatus.approved,
      ),
      Report(
        business: 'Grand Hotel San Pablo',
        period: 'February 2024',
        totalGuests: 28,
        checkIns: 5,
        submitted: '2024-03-02',
        status: ReportStatus.approved,
      ),
      Report(
        business: 'Sampaloc Lake Resort',
        period: 'April 2024',
        totalGuests: 52,
        checkIns: 8,
        submitted: '2024-05-01',
        status: ReportStatus.approved,
      ),
      Report(
        business: 'Sampaloc Lake Resort',
        period: 'March 2024',
        totalGuests: 45,
        checkIns: 7,
        submitted: '2024-04-02',
        status: ReportStatus.approved,
      ),
      Report(
        business: 'Paradise Resort & Spa',
        period: 'March 2024',
        totalGuests: 0,
        checkIns: 0,
        submitted: null,
        status: ReportStatus.draft,
      ),
      Report(
        business: 'Grand Hotel San Pablo',
        period: 'January 2024',
        totalGuests: 22,
        checkIns: 4,
        submitted: '2024-02-03',
        status: ReportStatus.rejected,
      ),
    ];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _filterBusiness = '';
      _filterMonth = '';
      _filterYear = '';
      _filterStatus = '';
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  List<Report> get _filtered {
    List<Report> filtered = _reports;

    // Search filter
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered
          .where((r) => r.business.toLowerCase().contains(q))
          .toList();
    }

    // Business filter
    if (_filterBusiness.isNotEmpty && _filterBusiness != 'All Businesses') {
      filtered = filtered
          .where((r) => r.business.contains(_filterBusiness))
          .toList();
    }

    // Month filter
    if (_filterMonth.isNotEmpty && _filterMonth != 'All Months') {
      filtered = filtered
          .where((r) => r.period.contains(_filterMonth))
          .toList();
    }

    // Year filter
    if (_filterYear.isNotEmpty && _filterYear != 'All Years') {
      filtered = filtered.where((r) => r.period.contains(_filterYear)).toList();
    }

    // Status filter
    if (_filterStatus.isNotEmpty && _filterStatus != 'All Statuses') {
      final statusMap = {
        'Submitted': ReportStatus.submitted,
        'Approved': ReportStatus.approved,
        'Rejected': ReportStatus.rejected,
        'Draft': ReportStatus.draft,
      };
      final selectedStatus = statusMap[_filterStatus];
      if (selectedStatus != null) {
        filtered = filtered.where((r) => r.status == selectedStatus).toList();
      }
    }

    return filtered;
  }

  // Get unique business names for filter
  List<String> get _businessNames {
    final names = _reports.map((r) => r.business).toSet().toList();
    names.sort();
    return ['All Businesses', ...names];
  }

  String _reportKey(Report report) => '${report.business}||${report.period}';

  bool _isReportSelected(Report report) =>
      _selectedReportKeys.contains(_reportKey(report));

  bool? _selectAllValue(List<Report> rows) {
    if (rows.isEmpty) return false;
    final selectedCount = rows.where(_isReportSelected).length;
    if (selectedCount == 0) return false;
    if (selectedCount == rows.length) return true;
    return null;
  }

  void _toggleReportSelection(Report report, bool? selected) {
    final key = _reportKey(report);
    setState(() {
      if (selected ?? false) {
        _selectedReportKeys.add(key);
      } else {
        _selectedReportKeys.remove(key);
      }
    });
  }

  void _toggleSelectAll(List<Report> rows, bool? selected) {
    setState(() {
      if (selected ?? false) {
        for (final report in rows) {
          _selectedReportKeys.add(_reportKey(report));
        }
      } else {
        for (final report in rows) {
          _selectedReportKeys.remove(_reportKey(report));
        }
      }
    });
  }

  void _updateReportStatus(Report report, ReportStatus newStatus) {
    setState(() {
      for (int i = 0; i < _reports.length; i++) {
        if (_reports[i].business == report.business &&
            _reports[i].period == report.period) {
          _reports[i] = Report(
            business: _reports[i].business,
            period: _reports[i].period,
            totalGuests: _reports[i].totalGuests,
            checkIns: _reports[i].checkIns,
            submitted: _reports[i].submitted,
            status: newStatus,
          );
          break;
        }
      }
    });

    // Just show snackbar - NO Navigator.pop or push
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${report.business} - ${report.period} has been ${newStatus.name}',
        ),
        backgroundColor: newStatus == ReportStatus.approved
            ? const Color(0xFF00C48C)
            : const Color(0xFFFF4D6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final excelGenerator = ExcelGeneratorService();
      final filePath = await excelGenerator.generateDailyAccommodationReport(
        reportData: {},
        fileName: 'DAE-1B_${DateTime.now().toString().substring(0, 10)}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported: $filePath'),
          backgroundColor: const Color(0xFF00C48C),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF4D6A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Reports',
      selectedIndex: 2,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(
                  onFilterTap: () =>
                      setState(() => _showFilters = !_showFilters),
                  showFilters: _showFilters,
                  onExport: _exportToExcel,
                  isExporting: _isExporting,
                ),
                const SizedBox(height: 16),
                if (_showFilters)
                  Column(
                    children: [
                      _FilterSection(
                        businessNames: _businessNames,
                        months: _months,
                        years: _years,
                        statuses: _statuses,
                        selectedBusiness: _filterBusiness,
                        selectedMonth: _filterMonth,
                        selectedYear: _filterYear,
                        selectedStatus: _filterStatus,
                        onBusinessChanged: (value) =>
                            setState(() => _filterBusiness = value ?? ''),
                        onMonthChanged: (value) =>
                            setState(() => _filterMonth = value ?? ''),
                        onYearChanged: (value) =>
                            setState(() => _filterYear = value ?? ''),
                        onStatusChanged: (value) =>
                            setState(() => _filterStatus = value ?? ''),
                        onClear: _clearFilters,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 14),
                _ReportsTable(
                  rows: _filtered,
                  selectAllValue: _selectAllValue(_filtered),
                  isSelected: _isReportSelected,
                  onRowSelectionChanged: _toggleReportSelection,
                  onSelectAllChanged: _toggleSelectAll,
                  onStatusUpdate: _updateReportStatus,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Filter Section ──────────────────────────────────────────────────────────
// ─── Filter Section ──────────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.businessNames,
    required this.months,
    required this.years,
    required this.statuses,
    required this.selectedBusiness,
    required this.selectedMonth,
    required this.selectedYear,
    required this.selectedStatus,
    required this.onBusinessChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final List<String> businessNames;
  final List<String> months;
  final List<String> years;
  final List<String> statuses;
  final String selectedBusiness;
  final String selectedMonth;
  final String selectedYear;
  final String selectedStatus;
  final Function(String?) onBusinessChanged;
  final Function(String?) onMonthChanged;
  final Function(String?) onYearChanged;
  final Function(String?) onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 900;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

    int crossAxisCount = 4;
    if (!isLargeScreen && isMediumScreen) {
      crossAxisCount = 2;
    } else if (screenWidth < 600) {
      crossAxisCount = 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                mainAxisExtent: 73, // Fixed height instead of aspect ratio
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _FilterDropdown(
                      label: 'Business',
                      value: selectedBusiness.isEmpty
                          ? 'All Businesses'
                          : selectedBusiness,
                      items: businessNames,
                      onChanged: onBusinessChanged,
                    );
                  case 1:
                    return _FilterDropdown(
                      label: 'Month',
                      value: selectedMonth.isEmpty
                          ? 'All Months'
                          : selectedMonth,
                      items: months,
                      onChanged: onMonthChanged,
                    );
                  case 2:
                    return _FilterDropdown(
                      label: 'Year',
                      value: selectedYear.isEmpty ? 'All Years' : selectedYear,
                      items: years,
                      onChanged: onYearChanged,
                    );
                  case 3:
                    return _FilterDropdown(
                      label: 'Status',
                      value: selectedStatus.isEmpty
                          ? 'All Statuses'
                          : selectedStatus,
                      items: statuses,
                      onChanged: onStatusChanged,
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textGray,
                size: 20,
              ),
              style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
              dropdownColor: AppColors.cardBackground,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.onFilterTap,
    required this.showFilters,
    required this.onExport,
    required this.isExporting,
  });

  final VoidCallback onFilterTap;
  final bool showFilters;
  final VoidCallback onExport;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth < 900;
    final isSmallScreen = screenWidth <= 700;

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Reports',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Review and approve accommodation reports',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderButton(
                icon: Icons.filter_list_rounded,
                label: null,
                isActive: showFilters,
                onTap: onFilterTap,
              ),
              const SizedBox(width: 10),
              _HeaderButton(
                icon: Icons.download_rounded,
                label: null,
                onTap: onExport,
                isLoading: isExporting,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Monthly Reports',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Review and approve accommodation reports',
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderButton(
              icon: Icons.filter_list_rounded,
              label: isMediumScreen ? null : 'Filters',
              isActive: showFilters,
              onTap: onFilterTap,
            ),
            const SizedBox(width: 10),
            _HeaderButton(
              icon: Icons.download_rounded,
              label: isMediumScreen ? null : 'Export',
              onTap: onExport,
              isLoading: isExporting,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryCyan,
                ),
              )
            else
              Icon(
                icon,
                color: isActive ? AppColors.primaryCyan : AppColors.textGray,
                size: 16,
              ),
            if (label != null && !isLoading) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: isActive ? AppColors.primaryCyan : AppColors.textGray,
                  fontSize: 13,
                ),
              ),
            ],
          ],
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
          hintText: 'Search by business name...',
          hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSubtle,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

// ─── Reports Table ────────────────────────────────────────────────────────────

class _ReportsTable extends StatelessWidget {
  const _ReportsTable({
    required this.rows,
    required this.selectAllValue,
    required this.isSelected,
    required this.onRowSelectionChanged,
    required this.onSelectAllChanged,
    required this.onStatusUpdate,
  });

  final List<Report> rows;
  final bool? selectAllValue;
  final bool Function(Report report) isSelected;
  final void Function(Report report, bool? selected) onRowSelectionChanged;
  final void Function(List<Report> rows, bool? selected) onSelectAllChanged;
  final Function(Report, ReportStatus) onStatusUpdate;

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMediumScreen = constraints.maxWidth < 800;
                    return _TableHeader(
                      isMediumScreen: isMediumScreen,
                      selectAllValue: selectAllValue,
                      onSelectAllChanged: (selected) =>
                          onSelectAllChanged(rows, selected),
                    );
                  },
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No reports found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMediumScreen = constraints.maxWidth < 800;
                    return _TableHeader(
                      isMediumScreen: isMediumScreen,
                      selectAllValue: selectAllValue,
                      onSelectAllChanged: (selected) =>
                          onSelectAllChanged(rows, selected),
                    );
                  },
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.cardBorder, height: 1),
                  itemBuilder: (_, i) => LayoutBuilder(
                    builder: (context, constraints) {
                      final isMediumScreen = constraints.maxWidth < 800;
                      return _TableRow(
                        report: rows[i],
                        isMediumScreen: isMediumScreen,
                        isSelected: isSelected(rows[i]),
                        onSelectionChanged: (selected) =>
                            onRowSelectionChanged(rows[i], selected),
                        onStatusUpdate: onStatusUpdate,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.isMediumScreen,
    required this.selectAllValue,
    required this.onSelectAllChanged,
  });

  final bool isMediumScreen;
  final bool? selectAllValue;
  final ValueChanged<bool?> onSelectAllChanged;

  @override
  Widget build(BuildContext context) {
    // Medium screen: compact card-style rows, no column header needed beyond key fields
    if (isMediumScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _SelectAllCheckbox(value: selectAllValue, onChanged: onSelectAllChanged),
            const SizedBox(width: 8),
            const Expanded(flex: 3, child: _HeaderCell('Business')),
            const Expanded(flex: 2, child: _HeaderCell('Period')),
            const Expanded(flex: 2, child: _HeaderCell('Status')),
            const SizedBox(width: 32), // space for action icon
          ],
        ),
      );
    }

    // Large screen: full column layout
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _SelectAllCheckbox(value: selectAllValue, onChanged: onSelectAllChanged),
          const SizedBox(width: 8),
          const Expanded(flex: 5, child: _HeaderCell('Business')),
          const Expanded(flex: 3, child: _HeaderCell('Period')),
          const Expanded(flex: 2, child: _HeaderCell('Total Guests')),
          const Expanded(flex: 2, child: _HeaderCell('Check-ins')),
          const Expanded(flex: 3, child: _HeaderCell('Submitted')),
          const Expanded(flex: 3, child: _HeaderCell('Status')),
          const SizedBox(width: 36), // space for action icon
        ],
      ),
    );
  }
}

class _SelectAllCheckbox extends StatelessWidget {
  const _SelectAllCheckbox({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: value,
        tristate: true,
        onChanged: onChanged,
        activeColor: AppColors.primaryCyan,
        checkColor: Colors.white,
        side: const BorderSide(color: AppColors.textGray, width: 1.2),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

// ─── Table Row ────────────────────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.report,
    required this.isMediumScreen,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onStatusUpdate,
  });

  final Report report;
  final bool isMediumScreen;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final Function(Report, ReportStatus) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    if (isMediumScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                  activeColor: AppColors.primaryCyan,
                  checkColor: Colors.white,
                  side: const BorderSide(color: AppColors.textGray, width: 1.2),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                // Business + period stacked
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.business,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.period,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Expanded(flex: 2, child: _StatusBadge(status: report.status)),
                const SizedBox(width: 8),
                // Action icon — fixed width, always visible
                GestureDetector(
                  onTap: () => _showReportModal(context),
                  child: const SizedBox(
                    width: 24,
                    child: Icon(
                      Icons.remove_red_eye_outlined,
                      color: AppColors.textGray,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'Total Guests',
                  value: '${report.totalGuests}',
                ),
                _InfoChip(label: 'Check-ins', value: '${report.checkIns}'),
                if (report.submitted != null)
                  _InfoChip(label: 'Submitted', value: report.submitted!),
              ],
            ),
          ],
        ),
      );
    }

    // Large screen: single-row layout with fixed icon width (no Expanded for icon)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: onSelectionChanged,
            activeColor: AppColors.primaryCyan,
            checkColor: Colors.white,
            side: const BorderSide(color: AppColors.textGray, width: 1.2),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 5,
            child: Text(
              report.business,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              report.period,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${report.totalGuests}',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${report.checkIns}',
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              report.submitted ?? '—',
              style: TextStyle(
                color: report.submitted != null
                    ? AppColors.textGray
                    : AppColors.textSubtle,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 3, child: _StatusBadge(status: report.status)),
          // Fixed-width action icon — never shrinks or overflows
          GestureDetector(
            onTap: () => _showReportModal(context),
            child: const SizedBox(
              width: 36,
              child: Icon(
                Icons.remove_red_eye_outlined,
                color: AppColors.textGray,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportModal(BuildContext context) {
    // Determine if the report is submitted or not
    final isSubmitted = report.status == ReportStatus.submitted;

    showReviewReportModal(
      context,
      ReviewReportData(
        business: report.business,
        period: report.period,
        totalGuests: report.totalGuests,
        checkIns: report.checkIns,
        submitted: report.submitted,
        status: report.status,
      ),
      onApprove: isSubmitted
          ? () => onStatusUpdate(report, ReportStatus.approved)
          : null,
      onReject: isSubmitted
          ? () => onStatusUpdate(report, ReportStatus.rejected)
          : null,
    );
  }
}

// ─── Info Chip for Small Screens ─────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textGray, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  static _BadgeStyle _styleFor(ReportStatus s) {
    switch (s) {
      case ReportStatus.submitted:
        return const _BadgeStyle(label: 'Submitted', color: Color(0xFFFFB020));
      case ReportStatus.approved:
        return const _BadgeStyle(label: 'Approved', color: Color(0xFF00C48C));
      case ReportStatus.draft:
        return const _BadgeStyle(label: 'Draft', color: Color(0xFF8A9BB5));
      case ReportStatus.rejected:
        return const _BadgeStyle(label: 'Rejected', color: Color(0xFFFF4D6A));
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: style.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              style.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: style.color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({required this.label, required this.color});
  final String label;
  final Color color;
}
