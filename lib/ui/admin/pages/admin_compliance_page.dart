import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum ComplianceStatus { compliant, nonCompliant }

class ComplianceRecord {
  const ComplianceRecord({
    required this.business,
    required this.period,
    required this.status,
    this.warnings,
    this.lastNotice,
    required this.notes,
  });

  final String business;
  final String period;
  final ComplianceStatus status;
  final int? warnings; // null = show dash
  final String? lastNotice; // null = show dash
  final String notes;
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

const _records = [
  ComplianceRecord(
    business: 'Grand Hotel San Pablo',
    period: 'April 2024',
    status: ComplianceStatus.compliant,
    warnings: null,
    lastNotice: null,
    notes: 'Report submitted on time.',
  ),
  ComplianceRecord(
    business: 'Sampaloc Lake Resort',
    period: 'April 2024',
    status: ComplianceStatus.compliant,
    warnings: null,
    lastNotice: null,
    notes: 'Report submitted on time.',
  ),
  ComplianceRecord(
    business: 'Paradise Resort & Spa',
    period: 'April 2024',
    status: ComplianceStatus.nonCompliant,
    warnings: 3,
    lastNotice: '2024-04-10',
    notes: 'Three consecutive months of non-compliance. Second notice s...',
  ),
  ComplianceRecord(
    business: 'Lakeview Boutique Hotel',
    period: 'April 2024',
    status: ComplianceStatus.nonCompliant,
    warnings: 1,
    lastNotice: '2024-05-01',
    notes: 'First notice sent. Business is newly registered.',
  ),
];

const _monthOptions = [
  'All Months',
  'April 2024',
  'March 2024',
  'February 2024',
];
const _yearOptions = ['All Years', '2024', '2023'];
const _businessOptions = [
  'All Businesses',
  'Grand Hotel San Pablo',
  'Sampaloc Lake Resort',
  'Paradise Resort & Spa',
  'Lakeview Boutique Hotel',
];
const _statusOptions = ['All Statuses', 'Compliant', 'Non-Compliant'];

// ─── Admin Compliance Page ────────────────────────────────────────────────────

class AdminCompliancePage extends StatefulWidget {
  const AdminCompliancePage({super.key});

  @override
  State<AdminCompliancePage> createState() => _AdminCompliancePageState();
}

class _AdminCompliancePageState extends State<AdminCompliancePage> {
  String _searchQuery = '';
  String _selectedMonth = 'All Months';
  String _selectedYear = 'All Years';
  String _selectedBusiness = 'All Businesses';
  String _selectedStatus = 'All Statuses';

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _compliantCount =>
      _records.where((r) => r.status == ComplianceStatus.compliant).length;

  int get _nonCompliantCount =>
      _records.where((r) => r.status == ComplianceStatus.nonCompliant).length;

  int get _warningCount => _records.where((r) => r.warnings != null).length;

  List<ComplianceRecord> get _filtered {
    return _records.where((r) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty || r.business.toLowerCase().contains(q);

      final matchesBusiness =
          _selectedBusiness == 'All Businesses' ||
          r.business == _selectedBusiness;

      final matchesStatus =
          _selectedStatus == 'All Statuses' ||
          (_selectedStatus == 'Compliant' &&
              r.status == ComplianceStatus.compliant) ||
          (_selectedStatus == 'Non-Compliant' &&
              r.status == ComplianceStatus.nonCompliant);

      return matchesSearch && matchesBusiness && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Compliance Tracker',
      selectedIndex: 4,
      onNavSelected: (_) {},
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeader(),
            const SizedBox(height: 20),
            _SummaryCards(
              compliant: _compliantCount,
              nonCompliant: _nonCompliantCount,
              warning: _warningCount,
            ),
            const SizedBox(height: 16),
            _FilterRow(
              searchCtrl: _searchCtrl,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              selectedMonth: _selectedMonth,
              onMonthChanged: (v) => setState(() => _selectedMonth = v!),
              selectedYear: _selectedYear,
              onYearChanged: (v) => setState(() => _selectedYear = v!),
              selectedBusiness: _selectedBusiness,
              onBusinessChanged: (v) => setState(() => _selectedBusiness = v!),
              selectedStatus: _selectedStatus,
              onStatusChanged: (v) => setState(() => _selectedStatus = v!),
            ),
            const SizedBox(height: 14),
            Expanded(child: _ComplianceTable(rows: _filtered)),
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
          'Compliance Tracker',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Monitor monthly report submission compliance of establishments',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.compliant,
    required this.nonCompliant,
    required this.warning,
  });

  final int compliant;
  final int nonCompliant;
  final int warning;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: Stack vertically

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.accentGreen,
                borderColor: AppColors.accentGreen,
                value: '$compliant',
                label: 'Compliant',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                icon: Icons.cancel_outlined,
                iconColor: AppColors.accentRed,
                borderColor: AppColors.accentRed,
                value: '$nonCompliant',
                label: 'Non-Compliant',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.accentOrange,
                borderColor: AppColors.accentOrange,
                value: '$warning',
                label: 'Warning',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.selectedYear,
    required this.onYearChanged,
    required this.selectedBusiness,
    required this.onBusinessChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final String selectedMonth;
  final ValueChanged<String?> onMonthChanged;
  final String selectedYear;
  final ValueChanged<String?> onYearChanged;
  final String selectedBusiness;
  final ValueChanged<String?> onBusinessChanged;
  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Wrap filters vertically
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SearchField(
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
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
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedYear,
                      items: _yearOptions,
                      onChanged: onYearChanged,
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
              const SizedBox(height: 10),
              _DropdownFilter(
                value: selectedStatus,
                items: _statusOptions,
                onChanged: onStatusChanged,
              ),
            ],
          );
        } else if (constraints.maxWidth < 1000) {
          // Tablet: Two rows
          return Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: _SearchField(
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
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
                      value: selectedYear,
                      items: _yearOptions,
                      onChanged: onYearChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedBusiness,
                      items: _businessOptions,
                      onChanged: onBusinessChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedStatus,
                      items: _statusOptions,
                      onChanged: onStatusChanged,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop: Full row
          return Row(
            children: [
              SizedBox(
                width: 200,
                child: _SearchField(
                  controller: searchCtrl,
                  onChanged: onSearchChanged,
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
                  value: selectedYear,
                  items: _yearOptions,
                  onChanged: onYearChanged,
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
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownFilter(
                  value: selectedStatus,
                  items: _statusOptions,
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          );
        }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
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

// ─── Compliance Table ─────────────────────────────────────────────────────────

class _ComplianceTable extends StatelessWidget {
  const _ComplianceTable({required this.rows});

  final List<ComplianceRecord> rows;

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
          _TableHeader(),
          const Divider(color: AppColors.cardBorder, height: 1),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No records found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.cardBorder, height: 1),
                    itemBuilder: (_, i) => _ComplianceRow(record: rows[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Header (Responsive columns) ────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          // Mobile: Show fewer columns
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 5, child: _HeaderCell('Business')),
                Expanded(flex: 3, child: _HeaderCell('Period')),
                Expanded(flex: 3, child: _HeaderCell('Status')),
                const SizedBox(width: 40), // Space for history icon
              ],
            ),
          );
        } else if (constraints.maxWidth < 900) {
          // Small tablet: Show all columns except maybe one
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 4, child: _HeaderCell('Business')),
                Expanded(flex: 2, child: _HeaderCell('Period')),
                Expanded(flex: 2, child: _HeaderCell('Status')),
                Expanded(flex: 2, child: _HeaderCell('Warnings')),
                Expanded(flex: 3, child: _HeaderCell('Notes')),
                Expanded(flex: 1, child: _HeaderCell('')),
              ],
            ),
          );
        } else {
          // Desktop: Full header
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 4, child: _HeaderCell('Business')),
                Expanded(flex: 3, child: _HeaderCell('Period')),
                Expanded(flex: 3, child: _HeaderCell('Status')),
                Expanded(flex: 2, child: _HeaderCell('Warnings')),
                Expanded(flex: 3, child: _HeaderCell('Last Notice')),
                Expanded(flex: 5, child: _HeaderCell('Notes')),
                Expanded(flex: 1, child: _HeaderCell('History')),
              ],
            ),
          );
        }
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

// ─── Compliance Row (Responsive) ──────────────────────────────────────────────

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({required this.record});

  final ComplianceRecord record;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          // Mobile: Compact card-like row
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.business,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.period,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 3, child: _StatusBadge(status: record.status)),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.textGray,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        } else if (constraints.maxWidth < 1000) {
          // Small tablet: Show most columns
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    record.business,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    record.period,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(flex: 2, child: _StatusBadge(status: record.status)),
                Expanded(
                  flex: 2,
                  child: record.warnings != null
                      ? _WarningBadge(count: record.warnings!)
                      : const Text(
                          '—',
                          style: TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 13,
                          ),
                        ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    record.notes,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.textGray,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Desktop: Full row
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    record.business,
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
                    record.period,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(flex: 3, child: _StatusBadge(status: record.status)),
                Expanded(
                  flex: 2,
                  child: record.warnings != null
                      ? _WarningBadge(count: record.warnings!)
                      : const Text(
                          '—',
                          style: TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 13,
                          ),
                        ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    record.lastNotice ?? '—',
                    style: TextStyle(
                      color: record.lastNotice != null
                          ? AppColors.textGray
                          : AppColors.textSubtle,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    record.notes,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {},
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
        }
      },
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ComplianceStatus status;

  @override
  Widget build(BuildContext context) {
    final isCompliant = status == ComplianceStatus.compliant;
    final color = isCompliant ? AppColors.accentGreen : AppColors.accentRed;
    final label = isCompliant ? 'Compliant' : 'Non-Compliant';
    final icon = isCompliant
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Warning Badge ────────────────────────────────────────────────────────────

class _WarningBadge extends StatelessWidget {
  const _WarningBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentRed.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.accentRed,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Color Extensions ─────────────────────────────────────────────────────────

extension _ExtraColors on AppColors {
  static const accentGreen = Color(0xFF00C48C);
  static const accentOrange = Color(0xFFFFB020);
  static const accentRed = Color(0xFFFF4D6A);
}
