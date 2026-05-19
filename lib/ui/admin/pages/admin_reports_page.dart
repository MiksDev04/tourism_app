// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/review_report_modal.dart';
import '../../shared/layouts/admin_layout.dart';
import '../models/report_models.dart';
import '../../../core/services/excel_generator_service.dart';

// ─── Generated Report Model (maps to public.reports table) ───────────────────
// TODO: Move this to report_models.dart

class GeneratedReport {
  final String id; // uuid
  final String businessId; // references businesses(id)
  final String businessName; // joined from businesses
  final String reportType; // 'DAE-1B'
  final int periodMonth; // 1–12
  final int periodYear;
  final String? fileUrl; // Supabase Storage URL
  final DateTime generatedAt;
  final String? generatedBy; // profile_id

  const GeneratedReport({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.reportType,
    required this.periodMonth,
    required this.periodYear,
    this.fileUrl,
    required this.generatedAt,
    this.generatedBy,
  });

  String get periodLabel => '${_monthName(periodMonth)} $periodYear';
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  static String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return (month >= 1 && month <= 12) ? names[month] : '—';
  }
}

// ─── Admin Reports Page ───────────────────────────────────────────────────────

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  bool _showFilters = false;
  String _filterBusiness = '';
  String _filterMonth = '';
  String _filterYear = '';
  String _filterStatus = '';
  bool _isGenerating = false;

  final List<String> _months = [
    'All Months', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final List<String> _years = ['All Years', '2025', '2024', '2023', '2022'];
  final List<String> _statuses = [
    'All Statuses', 'Submitted', 'Approved', 'Rejected', 'Draft',
  ];

  // ── Submissions (existing review workflow) ──
  late List<Report> _reports;
  final Set<String> _selectedReportKeys = <String>{};

  // ── Generated Reports (maps to public.reports table) ──
  // TODO: Replace with real Supabase fetch — see _fetchGeneratedReports()
  List<GeneratedReport> _generatedReports = [
    GeneratedReport(
      id: 'gr-001',
      businessId: 'biz-001',
      businessName: 'Grand Hotel San Pablo',
      reportType: 'DAE-1B',
      periodMonth: 4,
      periodYear: 2024,
      fileUrl: 'https://your-project.supabase.co/storage/v1/object/public/reports/DAE-1B_Grand_Hotel_April_2024.xlsx',
      generatedAt: DateTime(2024, 5, 2, 10, 30),
    ),
    GeneratedReport(
      id: 'gr-002',
      businessId: 'biz-002',
      businessName: 'Sampaloc Lake Resort',
      reportType: 'DAE-1B',
      periodMonth: 3,
      periodYear: 2024,
      fileUrl: 'https://your-project.supabase.co/storage/v1/object/public/reports/DAE-1B_Sampaloc_March_2024.xlsx',
      generatedAt: DateTime(2024, 4, 1, 9, 15),
    ),
    GeneratedReport(
      id: 'gr-003',
      businessId: 'biz-001',
      businessName: 'Grand Hotel San Pablo',
      reportType: 'DAE-1B',
      periodMonth: 3,
      periodYear: 2024,
      fileUrl: null, // generation failed — no file
      generatedAt: DateTime(2024, 4, 3, 14, 0),
    ),
  ];

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

    // TODO: Call _fetchGeneratedReports() here once Supabase is wired up
    // _fetchGeneratedReports();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── TODO: Fetch generated reports from Supabase ───────────────────────────
  // Future<void> _fetchGeneratedReports() async {
  //   final supabase = Supabase.instance.client;
  //   final data = await supabase
  //       .from('reports')
  //       .select('*, businesses(business_name)')
  //       .order('generated_at', ascending: false);
  //
  //   setState(() {
  //     _generatedReports = (data as List).map((row) => GeneratedReport(
  //       id: row['id'],
  //       businessId: row['business_id'],
  //       businessName: row['businesses']['business_name'],
  //       reportType: row['report_type'] ?? 'DAE-1B',
  //       periodMonth: row['period_month'],
  //       periodYear: row['period_year'],
  //       fileUrl: row['file_url'],
  //       generatedAt: DateTime.parse(row['generated_at']),
  //       generatedBy: row['generated_by'],
  //     )).toList();
  //   });
  // }

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

  List<Report> get _filteredSubmissions {
    List<Report> filtered = _reports;
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((r) => r.business.toLowerCase().contains(q)).toList();
    }
    if (_filterBusiness.isNotEmpty && _filterBusiness != 'All Businesses') {
      filtered = filtered.where((r) => r.business.contains(_filterBusiness)).toList();
    }
    if (_filterMonth.isNotEmpty && _filterMonth != 'All Months') {
      filtered = filtered.where((r) => r.period.contains(_filterMonth)).toList();
    }
    if (_filterYear.isNotEmpty && _filterYear != 'All Years') {
      filtered = filtered.where((r) => r.period.contains(_filterYear)).toList();
    }
    if (_filterStatus.isNotEmpty && _filterStatus != 'All Statuses') {
      final statusMap = {
        'Submitted': ReportStatus.submitted,
        'Approved': ReportStatus.approved,
        'Rejected': ReportStatus.rejected,
        'Draft': ReportStatus.draft,
      };
      final s = statusMap[_filterStatus];
      if (s != null) filtered = filtered.where((r) => r.status == s).toList();
    }
    return filtered;
  }

  List<GeneratedReport> get _filteredGeneratedReports {
    List<GeneratedReport> filtered = _generatedReports;
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((r) => r.businessName.toLowerCase().contains(q)).toList();
    }
    if (_filterBusiness.isNotEmpty && _filterBusiness != 'All Businesses') {
      filtered = filtered.where((r) => r.businessName.contains(_filterBusiness)).toList();
    }
    if (_filterMonth.isNotEmpty && _filterMonth != 'All Months') {
      filtered = filtered.where((r) => r.periodLabel.contains(_filterMonth)).toList();
    }
    if (_filterYear.isNotEmpty && _filterYear != 'All Years') {
      final year = int.tryParse(_filterYear);
      if (year != null) filtered = filtered.where((r) => r.periodYear == year).toList();
    }
    return filtered;
  }

  List<String> get _businessNames {
    final names = _reports.map((r) => r.business).toSet().toList();
    names.sort();
    return ['All Businesses', ...names];
  }

  String _reportKey(Report r) => '${r.business}||${r.period}';
  bool _isReportSelected(Report r) => _selectedReportKeys.contains(_reportKey(r));

  bool? _selectAllValue(List<Report> rows) {
    if (rows.isEmpty) return false;
    final selected = rows.where(_isReportSelected).length;
    if (selected == 0) return false;
    if (selected == rows.length) return true;
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
        for (final r in rows) _selectedReportKeys.add(_reportKey(r));
      } else {
        for (final r in rows) _selectedReportKeys.remove(_reportKey(r));
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${report.business} — ${report.period} has been ${newStatus.name}'),
        backgroundColor: newStatus == ReportStatus.approved
            ? const Color(0xFF00C48C)
            : const Color(0xFFFF4D6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Generate Report → Upload to Supabase Storage → Insert reports row ──────
  Future<void> _onGenerateReport({
    required String businessId,
    required String businessName,
    required int month,
    required int year,
  }) async {
    setState(() => _isGenerating = true);
    try {
      final fileName = 'DAE-1B_${businessName.replaceAll(' ', '_')}_'
          '${GeneratedReport._monthName(month)}_$year';

      // Step 1 — Generate the .xlsx file
      final excelGenerator = ExcelGeneratorService();
      final localPath = await excelGenerator.generateDailyAccommodationReport(
        reportData: {
          'businessId': businessId,
          'businessName': businessName,
          'periodMonth': month,
          'periodYear': year,
        },
        fileName: fileName,
      );

      // TODO: Step 2 — Upload to Supabase Storage bucket "reports/"
      // final supabase = Supabase.instance.client;
      // final fileBytes = await File(localPath).readAsBytes();
      // final storagePath = 'reports/$fileName.xlsx';
      // await supabase.storage.from('reports').uploadBinary(
      //   storagePath,
      //   fileBytes,
      //   fileOptions: const FileOptions(contentType:
      //     'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      // );
      // final fileUrl = supabase.storage.from('reports').getPublicUrl(storagePath);

      // TODO: Step 3 — Insert row into public.reports
      // final currentUser = supabase.auth.currentUser;
      // await supabase.from('reports').insert({
      //   'business_id': businessId,
      //   'report_type': 'DAE-1B',
      //   'period_month': month,
      //   'period_year': year,
      //   'file_url': fileUrl,
      //   'generated_by': currentUser?.id,
      // });

      // TODO: Step 4 — Refresh list from Supabase
      // await _fetchGeneratedReports();

      // ── Stub: add to local state until Supabase is wired ──
      const stubUrl = 'https://your-project.supabase.co/storage/v1/object/public/reports/';
      setState(() {
        _generatedReports.insert(
          0,
          GeneratedReport(
            id: 'gr-${DateTime.now().millisecondsSinceEpoch}',
            businessId: businessId,
            businessName: businessName,
            reportType: 'DAE-1B',
            periodMonth: month,
            periodYear: year,
            fileUrl: '$stubUrl$fileName.xlsx',
            generatedAt: DateTime.now(),
          ),
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report generated and saved: $localPath'),
          backgroundColor: const Color(0xFF00C48C),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: const Color(0xFFFF4D6A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showGenerateReportDialog() {
    showDialog(
      context: context,
      builder: (_) => _GenerateReportDialog(
        businessNames: _businessNames.where((b) => b != 'All Businesses').toList(),
        months: _months.where((m) => m != 'All Months').toList(),
        years: _years.where((y) => y != 'All Years').toList(),
        isGenerating: _isGenerating,
        onGenerate: ({
          required String businessId,
          required String businessName,
          required int month,
          required int year,
        }) {
          Navigator.pop(context);
          _onGenerateReport(
            businessId: businessId,
            businessName: businessName,
            month: month,
            year: year,
          );
        },
      ),
    );
  }

  // ── TODO: Launch file URL for re-download ─────────────────────────────────
  Future<void> _downloadReport(GeneratedReport report) async {
    if (!report.hasFile) return;
    // TODO: Use url_launcher to open report.fileUrl in browser for download
    // await launchUrl(Uri.parse(report.fileUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${report.fileUrl}'),
        backgroundColor: const Color(0xFF00C48C),
        duration: const Duration(seconds: 2),
      ),
    );
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
                // ── Page Header ──
                _PageHeader(
                  onFilterTap: () => setState(() => _showFilters = !_showFilters),
                  showFilters: _showFilters,
                  onGenerateReport: _showGenerateReportDialog,
                  isGenerating: _isGenerating,
                ),
                const SizedBox(height: 16),

                // ── Filters ──
                if (_showFilters) ...[
                  _FilterSection(
                    businessNames: _businessNames,
                    months: _months,
                    years: _years,
                    statuses: _statuses,
                    selectedBusiness: _filterBusiness,
                    selectedMonth: _filterMonth,
                    selectedYear: _filterYear,
                    selectedStatus: _filterStatus,
                    onBusinessChanged: (v) => setState(() => _filterBusiness = v ?? ''),
                    onMonthChanged: (v) => setState(() => _filterMonth = v ?? ''),
                    onYearChanged: (v) => setState(() => _filterYear = v ?? ''),
                    onStatusChanged: (v) => setState(() => _filterStatus = v ?? ''),
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Search ──
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 20),

                // ── Section 1: Business Submissions (review workflow) ──
                _SectionLabel(
                  icon: Icons.inbox_rounded,
                  label: 'Business Submissions',
                  subtitle: 'Review and approve monthly reports from businesses',
                ),
                const SizedBox(height: 12),
                _ReportsTable(
                  rows: _filteredSubmissions,
                  selectAllValue: _selectAllValue(_filteredSubmissions),
                  isSelected: _isReportSelected,
                  onRowSelectionChanged: _toggleReportSelection,
                  onSelectAllChanged: _toggleSelectAll,
                  onStatusUpdate: _updateReportStatus,
                ),
                const SizedBox(height: 28),

                // ── Section 2: Generated Reports (Supabase Storage) ──
                _SectionLabel(
                  icon: Icons.folder_zip_rounded,
                  label: 'Generated Reports',
                  subtitle: 'DAE-1B Excel files saved to Supabase Storage',
                  trailing: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryCyan,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                _GeneratedReportsTable(
                  rows: _filteredGeneratedReports,
                  onDownload: _downloadReport,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryCyan, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Generated Reports Table ──────────────────────────────────────────────────

class _GeneratedReportsTable extends StatelessWidget {
  const _GeneratedReportsTable({
    required this.rows,
    required this.onDownload,
  });

  final List<GeneratedReport> rows;
  final Future<void> Function(GeneratedReport) onDownload;

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
          // Table header
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              return _GenReportTableHeader(isNarrow: isNarrow);
            },
          ),
          const Divider(color: AppColors.cardBorder, height: 1),

          // Table body
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No generated reports yet. Use "Generate Report" to create one.',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.cardBorder, height: 1),
              itemBuilder: (_, i) => LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;
                  return _GenReportTableRow(
                    report: rows[i],
                    isNarrow: isNarrow,
                    onDownload: () => onDownload(rows[i]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _GenReportTableHeader extends StatelessWidget {
  const _GenReportTableHeader({required this.isNarrow});
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 4, child: _HeaderCell('Business')),
            Expanded(flex: 2, child: _HeaderCell('Period')),
            SizedBox(width: 60),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: _HeaderCell('Business')),
          Expanded(flex: 2, child: _HeaderCell('Type')),
          Expanded(flex: 2, child: _HeaderCell('Period')),
          Expanded(flex: 3, child: _HeaderCell('Generated At')),
          SizedBox(width: 80, child: _HeaderCell('File')),
        ],
      ),
    );
  }
}

class _GenReportTableRow extends StatelessWidget {
  const _GenReportTableRow({
    required this.report,
    required this.isNarrow,
    required this.onDownload,
  });

  final GeneratedReport report;
  final bool isNarrow;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final generatedAtStr = '${report.generatedAt.year}-'
        '${report.generatedAt.month.toString().padLeft(2, '0')}-'
        '${report.generatedAt.day.toString().padLeft(2, '0')}';

    if (isNarrow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.businessName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    generatedAtStr,
                    style: const TextStyle(color: AppColors.textGray, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                report.periodLabel,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 60,
              child: _DownloadButton(hasFile: report.hasFile, onTap: onDownload),
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
              report.businessName,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primaryCyan.withOpacity(0.25)),
              ),
              child: Text(
                report.reportType,
                style: const TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              report.periodLabel,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              generatedAtStr,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 80,
            child: _DownloadButton(hasFile: report.hasFile, onTap: onDownload),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.hasFile, required this.onTap});

  final bool hasFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasFile) {
      return const Tooltip(
        message: 'File unavailable',
        child: Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D6A), size: 18),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryCyan.withOpacity(0.10),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, color: AppColors.primaryCyan, size: 14),
            SizedBox(width: 4),
            Text(
              '.xlsx',
              style: TextStyle(
                color: AppColors.primaryCyan,
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

// ─── Generate Report Dialog ───────────────────────────────────────────────────

class _GenerateReportDialog extends StatefulWidget {
  const _GenerateReportDialog({
    required this.businessNames,
    required this.months,
    required this.years,
    required this.isGenerating,
    required this.onGenerate,
  });

  final List<String> businessNames;
  final List<String> months;
  final List<String> years;
  final bool isGenerating;
  final void Function({
    required String businessId,
    required String businessName,
    required int month,
    required int year,
  }) onGenerate;

  @override
  State<_GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<_GenerateReportDialog> {
  String? _selectedBusiness;
  String? _selectedMonth;
  String? _selectedYear;

  bool get _canGenerate =>
      _selectedBusiness != null &&
      _selectedMonth != null &&
      _selectedYear != null;

  int _monthIndex(String name) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names.indexOf(name) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primaryCyan,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate DAE-1B Report',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Generates .xlsx and saves to Supabase Storage',
                        style: TextStyle(color: AppColors.textGray, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Business dropdown
              _DialogDropdown(
                label: 'Business',
                hint: 'Select a business',
                value: _selectedBusiness,
                items: widget.businessNames,
                onChanged: (v) => setState(() => _selectedBusiness = v),
              ),
              const SizedBox(height: 14),

              // Month + Year row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _DialogDropdown(
                      label: 'Month',
                      hint: 'Month',
                      value: _selectedMonth,
                      items: widget.months,
                      onChanged: (v) => setState(() => _selectedMonth = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _DialogDropdown(
                      label: 'Year',
                      hint: 'Year',
                      value: _selectedYear,
                      items: widget.years,
                      onChanged: (v) => setState(() => _selectedYear = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryCyan.withOpacity(0.18)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primaryCyan, size: 15),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The report will be uploaded to Supabase Storage and saved in the Generated Reports table below.',
                        style: TextStyle(color: AppColors.textGray, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textGray, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _canGenerate
                        ? () => widget.onGenerate(
                              // TODO: Replace stub businessId with real UUID from Supabase query
                              businessId: 'biz-stub-id',
                              businessName: _selectedBusiness!,
                              month: _monthIndex(_selectedMonth!),
                              year: int.parse(_selectedYear!),
                            )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: _canGenerate
                            ? AppColors.primaryCyan
                            : AppColors.primaryCyan.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: _canGenerate ? Colors.black : Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Generate & Save',
                            style: TextStyle(
                              color: _canGenerate ? Colors.black : Colors.black45,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogDropdown extends StatelessWidget {
  const _DialogDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String? value;
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
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              hint: Text(hint, style: const TextStyle(color: AppColors.textSubtle, fontSize: 13)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGray, size: 20),
              style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
              dropdownColor: AppColors.cardBackground,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
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

// ─── Filter Section ───────────────────────────────────────────────────────────

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
    if (!isLargeScreen && isMediumScreen) crossAxisCount = 2;
    else if (screenWidth < 600) crossAxisCount = 1;

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
                style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
                child: const Text('Clear All', style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              mainAxisExtent: 73,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _FilterDropdown(
                    label: 'Business',
                    value: selectedBusiness.isEmpty ? 'All Businesses' : selectedBusiness,
                    items: businessNames,
                    onChanged: onBusinessChanged,
                  );
                case 1:
                  return _FilterDropdown(
                    label: 'Month',
                    value: selectedMonth.isEmpty ? 'All Months' : selectedMonth,
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
                    value: selectedStatus.isEmpty ? 'All Statuses' : selectedStatus,
                    items: statuses,
                    onChanged: onStatusChanged,
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
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
        Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          alignment: Alignment.centerLeft,
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
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGray, size: 20),
              style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
              dropdownColor: AppColors.cardBackground,
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(color: AppColors.textWhite, fontSize: 13), overflow: TextOverflow.ellipsis),
              )).toList(),
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
    required this.onGenerateReport,
    required this.isGenerating,
  });

  final VoidCallback onFilterTap;
  final bool showFilters;
  final VoidCallback onGenerateReport;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth < 900;
    final isSmallScreen = screenWidth <= 700;

    final filterBtn = _HeaderButton(
      icon: Icons.filter_list_rounded,
      label: isMediumScreen ? null : 'Filters',
      isActive: showFilters,
      onTap: onFilterTap,
    );

    final generateBtn = _HeaderButton(
      icon: Icons.description_rounded,
      label: isMediumScreen ? null : 'Generate Report',
      onTap: onGenerateReport,
      isLoading: isGenerating,
      isPrimary: true,
    );

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageTitleBlock(),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              filterBtn,
              const SizedBox(width: 10),
              generateBtn,
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _PageTitleBlock(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            filterBtn,
            const SizedBox(width: 10),
            generateBtn,
          ],
        ),
      ],
    );
  }
}

class _PageTitleBlock extends StatelessWidget {
  const _PageTitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Reports',
          style: TextStyle(color: AppColors.textWhite, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'Review submissions and manage generated DAE-1B reports',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
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
    this.isPrimary = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLoading;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final Color borderColor;
    final Color bgColor;
    final Color textColor;

    if (isPrimary) {
      iconColor = Colors.black;
      borderColor = AppColors.primaryCyan;
      bgColor = AppColors.primaryCyan;
      textColor = Colors.black;
    } else if (isActive) {
      iconColor = AppColors.primaryCyan;
      borderColor = AppColors.primaryCyan;
      bgColor = AppColors.primaryCyan.withOpacity(0.15);
      textColor = AppColors.primaryCyan;
    } else {
      iconColor = AppColors.textGray;
      borderColor = AppColors.cardBorder;
      bgColor = AppColors.cardBackground;
      textColor = AppColors.textGray;
    }

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
              )
            else
              Icon(icon, color: iconColor, size: 16),
            if (label != null && !isLoading) ...[
              const SizedBox(width: 6),
              Text(label!, style: TextStyle(color: textColor, fontSize: 13, fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal)),
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

// ─── Submissions Reports Table (unchanged review workflow) ────────────────────

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
  final bool Function(Report) isSelected;
  final void Function(Report, bool?) onRowSelectionChanged;
  final void Function(List<Report>, bool?) onSelectAllChanged;
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
                LayoutBuilder(builder: (context, constraints) {
                  return _TableHeader(
                    isMediumScreen: constraints.maxWidth < 800,
                    selectAllValue: selectAllValue,
                    onSelectAllChanged: (s) => onSelectAllChanged(rows, s),
                  );
                }),
                const Divider(color: AppColors.cardBorder, height: 1),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No reports found.', style: TextStyle(color: AppColors.textGray)),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  return _TableHeader(
                    isMediumScreen: constraints.maxWidth < 800,
                    selectAllValue: selectAllValue,
                    onSelectAllChanged: (s) => onSelectAllChanged(rows, s),
                  );
                }),
                const Divider(color: AppColors.cardBorder, height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder, height: 1),
                  itemBuilder: (_, i) => LayoutBuilder(
                    builder: (context, constraints) => _TableRow(
                      report: rows[i],
                      isMediumScreen: constraints.maxWidth < 800,
                      isSelected: isSelected(rows[i]),
                      onSelectionChanged: (s) => onRowSelectionChanged(rows[i], s),
                      onStatusUpdate: onStatusUpdate,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

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
            const SizedBox(width: 32),
          ],
        ),
      );
    }
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
          const SizedBox(width: 36),
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
      style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}

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
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.business, style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 2),
                      const SizedBox(height: 4),
                      Text(report.period, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _StatusBadge(status: report.status)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showReportModal(context),
                  child: const SizedBox(width: 24, child: Icon(Icons.remove_red_eye_outlined, color: AppColors.textGray, size: 20)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'Total Guests', value: '${report.totalGuests}'),
                _InfoChip(label: 'Check-ins', value: '${report.checkIns}'),
                if (report.submitted != null) _InfoChip(label: 'Submitted', value: report.submitted!),
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
          Expanded(flex: 5, child: Text(report.business, style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1)),
          Expanded(flex: 3, child: Text(report.period, style: const TextStyle(color: AppColors.textGray, fontSize: 13), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('${report.totalGuests}', style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('${report.checkIns}', style: const TextStyle(color: AppColors.textGray, fontSize: 13))),
          Expanded(
            flex: 3,
            child: Text(
              report.submitted ?? '—',
              style: TextStyle(color: report.submitted != null ? AppColors.textGray : AppColors.textSubtle, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 3, child: _StatusBadge(status: report.status)),
          GestureDetector(
            onTap: () => _showReportModal(context),
            child: const SizedBox(width: 36, child: Icon(Icons.remove_red_eye_outlined, color: AppColors.textGray, size: 20)),
          ),
        ],
      ),
    );
  }

  void _showReportModal(BuildContext context) {
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
      onApprove: isSubmitted ? () => onStatusUpdate(report, ReportStatus.approved) : null,
      onReject: isSubmitted ? () => onStatusUpdate(report, ReportStatus.rejected) : null,
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────

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
          Text('$label: ', style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
          Text(value, style: const TextStyle(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
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
            Container(width: 6, height: 6, decoration: BoxDecoration(color: style.color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(
              style.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(color: style.color, fontSize: 11.5, fontWeight: FontWeight.w600),
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