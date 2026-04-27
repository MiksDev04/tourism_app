import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
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
  final bool isNarrow ;
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
          1200 > MediaQuery.of(context).size.width
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

  // ── PDF export ────────────────────────────────────────────────────────
  Future<void> _exportPdf(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'report_${report.period.replaceAll(' ', '_').toLowerCase()}.pdf';
      final file = File('${dir.path}/$fileName');

      // Build minimal PDF bytes manually (no external pdf package needed)
      final content = '''%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 595 842]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length 220>>
stream
BT /F1 16 Tf 50 800 Td (Monthly Report - ${report.period}) Tj
0 -30 Td /F1 12 Tf (Period: ${report.period}) Tj
0 -20 Td (Total Guests: ${report.totalGuests}) Tj
0 -20 Td (Check-ins: ${report.checkIns}) Tj
0 -20 Td (Submitted: ${report.submitted}) Tj
0 -20 Td (Status: ${report.status.name}) Tj
ET
endstream
endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
xref
0 6
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000274 00000 n
0000000546 00000 n
trailer<</Size 6/Root 1 0 R>>
startxref
625
%%EOF''';

      await file.writeAsString(content);
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('PDF exported successfully.'),
            ]),
            backgroundColor: const Color(0xFF1A7F4B),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ── CSV export ────────────────────────────────────────────────────────
  Future<void> _exportCsv(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'report_${report.period.replaceAll(' ', '_').toLowerCase()}.csv';
      final file = File('${dir.path}/$fileName');

      final csv = [
        'Period,Total Guests,Check-ins,Submitted,Status',
        '${report.period},${report.totalGuests},${report.checkIns},${report.submitted},${report.status.name}',
      ].join('\n');

      await file.writeAsString(csv);
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: AppColors.textWhite, size: 16),
              SizedBox(width: 8),
              Text('CSV exported successfully.'),
            ]),
            backgroundColor: AppColors.primaryCyan,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ── Submit confirmation ───────────────────────────────────────────────
  Future<void> _confirmAndSubmit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submit Report?',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You are about to submit the report for ${report.period}. '
                  'Once submitted, the data will be locked and sent to the '
                  'Tourism Office for review.',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(false),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(true),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.gradientStart,
                                AppColors.gradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('Report for ${report.period} submitted successfully.'),
        ]),
        backgroundColor: const Color(0xFF1A7F4B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
          onTap: () => _exportPdf(context),       // ← was () {}
        ),
        _OutlineBtn(
          icon: Icons.download_rounded,
          label: 'Excel',
          onTap: () => _exportCsv(context),       // ← was () {}
        ),
        if (showAwaitingReview) _AwaitingReviewBtn(),
        if (showSubmit)
          _SubmitBtn(
            onTap: () => _confirmAndSubmit(context), // ← was () {}
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
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