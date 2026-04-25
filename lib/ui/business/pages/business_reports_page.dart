import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum ReportStatus { submitted, approved, rejected, draft }

class MonthlyReport {
  const MonthlyReport({
    required this.period,
    required this.totalGuests,
    required this.checkIns,
    required this.submitted,
    required this.status,
    this.feedback,
  });

  final String period;
  final int totalGuests;
  final int checkIns;
  final String submitted;
  final ReportStatus status;
  final String? feedback;
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

const _reports = [
  MonthlyReport(
    period: 'April 2024',
    totalGuests: 39,
    checkIns: 4,
    submitted: '2024-05-02',
    status: ReportStatus.submitted,
  ),
  MonthlyReport(
    period: 'March 2024',
    totalGuests: 16,
    checkIns: 2,
    submitted: '2024-04-03',
    status: ReportStatus.approved,
    feedback: 'Report reviewed and approved. Good submission.',
  ),
  MonthlyReport(
    period: 'February 2024',
    totalGuests: 28,
    checkIns: 5,
    submitted: '2024-03-02',
    status: ReportStatus.approved,
  ),
  MonthlyReport(
    period: 'January 2024',
    totalGuests: 22,
    checkIns: 4,
    submitted: '2024-02-03',
    status: ReportStatus.rejected,
    feedback:
        'Data inconsistencies found. Total guest count does not match breakdown totals. Please resubmit.',
  ),
];

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _years = ['2024', '2023', '2022'];

// ─── Business Reports Page ────────────────────────────────────────────────────

class BusinessReportsPage extends StatefulWidget {
  const BusinessReportsPage({super.key});

  @override
  State<BusinessReportsPage> createState() => _BusinessReportsPageState();
}

class _BusinessReportsPageState extends State<BusinessReportsPage> {
  String _selectedMonth = 'April';
  String _selectedYear  = '2024';

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Reports',
      selectedIndex: 3,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(),
                const SizedBox(height: 20),
                _GenerateCard(
                  selectedMonth: _selectedMonth,
                  selectedYear: _selectedYear,
                  isNarrow: isNarrow,
                  onMonthChanged: (v) => setState(() => _selectedMonth = v!),
                  onYearChanged: (v) => setState(() => _selectedYear = v!),
                  onGenerate: () {},
                ),
                const SizedBox(height: 16),
                ..._reports.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReportCard(report: r, isNarrow: isNarrow),
                  ),
                ),
                const SizedBox(height: 8),
                _HowItWorksNote(),
              ],
            ),
          );
        },
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
          'Monthly Reports',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Generate, submit, and track your monthly tourism reports',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Generate Card ────────────────────────────────────────────────────────────

class _GenerateCard extends StatelessWidget {
  const _GenerateCard({
    required this.selectedMonth,
    required this.selectedYear,
    required this.isNarrow,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onGenerate,
  });

  final String selectedMonth;
  final String selectedYear;
  final bool isNarrow;
  final ValueChanged<String?> onMonthChanged;
  final ValueChanged<String?> onYearChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: AppColors.primaryCyan, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Generate New Report',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Controls
          isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DropdownGroup(
                      monthValue: selectedMonth,
                      yearValue: selectedYear,
                      onMonthChanged: onMonthChanged,
                      onYearChanged: onYearChanged,
                    ),
                    const SizedBox(height: 12),
                    _GenerateButton(onPressed: onGenerate, fullWidth: true),
                  ],
                )
              : Row(
                  children: [
                    _DropdownGroup(
                      monthValue: selectedMonth,
                      yearValue: selectedYear,
                      onMonthChanged: onMonthChanged,
                      onYearChanged: onYearChanged,
                    ),
                    const SizedBox(width: 16),
                    _GenerateButton(onPressed: onGenerate, fullWidth: false),
                  ],
                ),
        ],
      ),
    );
  }
}

class _DropdownGroup extends StatelessWidget {
  const _DropdownGroup({
    required this.monthValue,
    required this.yearValue,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final String monthValue;
  final String yearValue;
  final ValueChanged<String?> onMonthChanged;
  final ValueChanged<String?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DropLabel('Month'),
            const SizedBox(height: 6),
            SizedBox(
              width: 140,
              child: _Dropdown(
                value: monthValue,
                items: _months,
                onChanged: onMonthChanged,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DropLabel('Year'),
            const SizedBox(height: 6),
            SizedBox(
              width: 100,
              child: _Dropdown(
                value: yearValue,
                items: _years,
                onChanged: onYearChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DropLabel extends StatelessWidget {
  const _DropLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onPressed, required this.fullWidth});
  final VoidCallback onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      height: 42,
      width: fullWidth ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.description_outlined,
              size: 16, color: Colors.white),
          label: const Text(
            'Generate Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9)),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
      ),
    );
    return fullWidth ? btn : btn;
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.isNarrow});

  final MonthlyReport report;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final r = report;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PeriodTitle(period: r.period),
                        const SizedBox(width: 10),
                        _StatusBadge(status: r.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(report: r),
                    const SizedBox(height: 10),
                    _ActionButtons(report: r, isNarrow: true),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PeriodTitle(period: r.period),
                    const SizedBox(width: 10),
                    _StatusBadge(status: r.status),
                    const SizedBox(width: 16),
                    _MetaRow(report: r),
                    const Spacer(),
                    _ActionButtons(report: r, isNarrow: false),
                  ],
                ),

          // Feedback banner
          if (r.feedback != null) ...[
            const SizedBox(height: 12),
            _FeedbackBanner(status: r.status, message: r.feedback!),
          ],
        ],
      ),
    );
  }
}

class _PeriodTitle extends StatelessWidget {
  const _PeriodTitle({required this.period});
  final String period;

  @override
  Widget build(BuildContext context) {
    return Text(
      period,
      style: const TextStyle(
        color: AppColors.textWhite,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.report});
  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        _MetaChip('Total Guests: ', '${report.totalGuests}'),
        _MetaChip('Check-ins: ', '${report.checkIns}'),
        _MetaChip('Submitted: ', report.submitted),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13),
        children: [
          TextSpan(
              text: label,
              style: const TextStyle(color: AppColors.textGray)),
          TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.report, required this.isNarrow});
  final MonthlyReport report;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final showSubmit = report.status == ReportStatus.rejected ||
        report.status == ReportStatus.draft;
    final showAwaitingReview = report.status == ReportStatus.submitted;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _OutlineBtn(
          icon: Icons.download_rounded,
          label: 'PDF',
          onTap: () {},
        ),
        _OutlineBtn(
          icon: Icons.download_rounded,
          label: 'Excel',
          onTap: () {},
        ),
        if (showAwaitingReview)
          _AwaitingReviewBtn(),
        if (showSubmit)
          _SubmitBtn(onTap: () {}),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textGray, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AwaitingReviewBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentOrange.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded,
              color: AppColors.accentOrange, size: 14),
          const SizedBox(width: 5),
          const Text(
            'Awaiting Review',
            style: TextStyle(
              color: AppColors.accentOrange,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBtn extends StatelessWidget {
  const _SubmitBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
          icon: Icons.schedule_rounded,
          color: Color(0xFFFFB020),
        );
      case ReportStatus.approved:
        return const _BadgeStyle(
          label: 'Approved',
          icon: Icons.check_circle_outline_rounded,
          color: Color(0xFF00C48C),
        );
      case ReportStatus.rejected:
        return const _BadgeStyle(
          label: 'Rejected',
          icon: Icons.cancel_outlined,
          color: Color(0xFFFF4D6A),
        );
      case ReportStatus.draft:
        return const _BadgeStyle(
          label: 'Draft',
          icon: Icons.edit_outlined,
          color: Color(0xFF8A9BB5),
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
        border: Border.all(color: style.color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.color, size: 12),
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
  const _BadgeStyle({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;
}

// ─── Feedback Banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.status, required this.message});
  final ReportStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isApproved = status == ReportStatus.approved;
    final color = isApproved ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── How It Works Note ────────────────────────────────────────────────────────

class _HowItWorksNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔖', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12.5, height: 1.5),
                children: [
                  TextSpan(
                    text: 'How it works: ',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Generate a report for the month you want to submit. The system automatically calculates totals from your guest entries. Review the report, then submit for Tourism Office approval. Once submitted, the data is locked for that period.',
                    style: TextStyle(color: AppColors.primaryCyan),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
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
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}