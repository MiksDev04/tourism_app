import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../shared/layouts/admin_layout.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum ReportStatus { submitted, approved, draft, rejected }

class Report {
  const Report({
    required this.business,
    required this.period,
    required this.totalGuests,
    required this.checkIns,
    this.submitted,
    required this.status,
  });

  final String business;
  final String period;
  final int totalGuests;
  final int checkIns;
  final String? submitted; // null = draft/no date
  final ReportStatus status;
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

const _reports = [
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

// ─── Admin Reports Page ───────────────────────────────────────────────────────

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Report> get _filtered {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _reports;
    return _reports
        .where((r) => r.business.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Reports',
      selectedIndex: 2,
      onNavSelected: (_) {},
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(),
            const SizedBox(height: 16),
            _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 14),
            Expanded(child: _ReportsTable(rows: _filtered)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth < 900;
    
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Reports',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
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
              label: isMediumScreen ? null : 'Filters',
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _HeaderButton(
              icon: Icons.download_rounded,
              label: isMediumScreen ? null : 'Export',
              onTap: () {},
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
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textGray, size: 16),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
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
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSubtle, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

// ─── Reports Table ────────────────────────────────────────────────────────────

class _ReportsTable extends StatelessWidget {
  const _ReportsTable({required this.rows});

  final List<Report> rows;

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isMediumScreen = constraints.maxWidth < 800;
              return _TableHeader(isMediumScreen: isMediumScreen);
            },
          ),
          const Divider(color: AppColors.cardBorder, height: 1),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No reports found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.cardBorder, height: 1),
                    itemBuilder: (_, i) => LayoutBuilder(
                      builder: (context, constraints) {
                        final isMediumScreen = constraints.maxWidth < 800;
                        return _TableRow(
                          report: rows[i],
                          isMediumScreen: isMediumScreen,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.isMediumScreen});

  final bool isMediumScreen;

  @override
  Widget build(BuildContext context) {
    if (isMediumScreen) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 3, child: _HeaderCell('Business')),
            Expanded(flex: 2, child: _HeaderCell('Period')),
            Expanded(flex: 1, child: _HeaderCell('Status')),
            Expanded(flex: 1, child: _HeaderCell('Actions')),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: _HeaderCell('Business')),
          Expanded(flex: 3, child: _HeaderCell('Period')),
          Expanded(flex: 2, child: _HeaderCell('Total Guests')),
          Expanded(flex: 2, child: _HeaderCell('Check-ins')),
          Expanded(flex: 3, child: _HeaderCell('Submitted')),
          Expanded(flex: 2, child: _HeaderCell('Status')),
          Expanded(flex: 1, child: _HeaderCell('Actions')),
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

// ─── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.report,
    required this.isMediumScreen,
  });

  final Report report;
  final bool isMediumScreen;

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
                Expanded(
                  flex: 1,
                  child: _StatusBadge(status: report.status),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.textGray,
                    size: 20,
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
                _InfoChip(
                  label: 'Check-ins',
                  value: '${report.checkIns}',
                ),
                if (report.submitted != null)
                  _InfoChip(
                    label: 'Submitted',
                    value: report.submitted!,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              report.business,
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
              report.period,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
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
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusBadge(status: report.status),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {},
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.textGray,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip for Small Screens ─────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

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
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 11,
            ),
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
        return const _BadgeStyle(
          label: 'Submitted',
          color: Color(0xFFFFB020),
        );
      case ReportStatus.approved:
        return const _BadgeStyle(
          label: 'Approved',
          color: Color(0xFF00C48C),
        );
      case ReportStatus.draft:
        return const _BadgeStyle(
          label: 'Draft',
          color: Color(0xFF8A9BB5),
        );
      case ReportStatus.rejected:
        return const _BadgeStyle(
          label: 'Rejected',
          color: Color(0xFFFF4D6A),
        );
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
  const _BadgeStyle({required this.label, required this.color});
  final String label;
  final Color color;
}