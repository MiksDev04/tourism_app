// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../../../api/admin_report_api.dart'; // <-- updated import

// ─── Generated Report Model ───────────────────────────────────────────────────

class GeneratedReport {
  const GeneratedReport({
    required this.id,
    required this.reportType,
    required this.periodMonth,
    required this.periodYear,
    required this.generatedAt,
    this.fileUrl,
    this.generatedBy,
    this.sheetOptions,
  });

  final String id;
  final String reportType;
  final int periodMonth;
  final int periodYear;
  final String? fileUrl;
  final DateTime generatedAt;
  final String? generatedBy;
  final ReportSheetOptions? sheetOptions;

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  /// Short display ID — first 8 chars uppercased, e.g. "A1B2C3D4"
  String get shortId => id.replaceAll('-', '').substring(0, 8).toUpperCase();

  String get periodLabel => '${_monthName(periodMonth)} $periodYear';

  static String _monthName(int m) {
    const n = [
      '',
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
    return (m >= 1 && m <= 12) ? n[m] : '—';
  }

  static GeneratedReport fromRow(Map<String, dynamic> row) => GeneratedReport(
    id: row['id'] as String,
    reportType: row['report_type'] as String? ?? 'DAE-1B',
    periodMonth: row['period_month'] as int,
    periodYear: row['period_year'] as int,
    fileUrl: row['file_url'] as String?,
    generatedAt: DateTime.parse(row['generated_at'] as String),
    generatedBy: row['generated_by'] as String?,
    sheetOptions: ReportSheetOptions(
      includeDailySheet: // was: includeEstablishmentSheet
          row['include_sheet_establishment'] as bool? ?? true,
      includeCountrySumSheet: row['include_sheet_country_sum'] as bool? ?? true,
      includeMonthlySummarySheet: row['include_sheet_monthly'] as bool? ?? true,
    ),
  );
}

// ─── Admin Reports Page ───────────────────────────────────────────────────────

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  // ── API / Service ──────────────────────────────────────────────────────────
  final ReportService _reportService = ReportService(); // <-- updated
  final _supabase = Supabase.instance.client;

  // ── Data ─────────────────────────────────────────────────────────────────
  List<GeneratedReport> _reports = [];

  // ── UI State ─────────────────────────────────────────────────────────────
  bool _loadingReports = false;
  bool _isGenerating = false;
  bool _showFilters = false;
  String _searchQuery = '';
  String _filterMonth = '';
  String _filterYear = '';

  final _searchCtrl = TextEditingController();

  static const List<String> _months = [
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

  static const List<String> _years = [
    'All Years',
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Supabase Fetches ──────────────────────────────────────────────────────

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() => _loadingReports = true);
    try {
      final rows = await _supabase
          .from('reports')
          .select('*')
          .order('generated_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _reports = (rows as List)
            .map((r) => GeneratedReport.fromRow(r))
            .toList();
      });
    } catch (e) {
      _showError('Failed to load reports: $e');
    } finally {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

  // ── Generate Report ───────────────────────────────────────────────────────

  Future<void> _onGenerateReport({
    required int month,
    required int year,
    required ReportSheetOptions sheetOptions,
  }) async {
    setState(() => _isGenerating = true);
    try {
      await _reportService.generateAndUpload(
        ReportParams(month: month, year: year, sheetOptions: sheetOptions),
      );
      await _fetchReports();
      if (!mounted) return;
      _showSuccess('Report generated successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Error generating report: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showGenerateDialog() {
    showDialog(
      context: context,
      builder: (_) => _GenerateReportDialog(
        months: _months.where((m) => m != 'All Months').toList(),
        years: _years.where((y) => y != 'All Years').toList(),
        onGenerate:
            ({
              required int month,
              required int year,
              required ReportSheetOptions sheetOptions,
            }) {
              Navigator.pop(context);
              _onGenerateReport(
                month: month,
                year: year,
                sheetOptions: sheetOptions,
              );
            },
      ),
    );
  }

  // ── Download ──────────────────────────────────────────────────────────────

  Future<void> _downloadReport(GeneratedReport report) async {
    if (!report.hasFile) return;

    try {
      _showSuccess('Downloading file...');

      // Extract file path from URL or use as-is if it's already a path
      String filePath = report.fileUrl!;
      if (filePath.contains('/')) {
        // If it's a full URL, extract the path after the bucket name
        filePath = filePath.split('/reports/').last;
      }

      // Download from Supabase storage
      final fileData = await _supabase.storage
          .from('reports')
          .download(filePath);

      // Get local directory (works on all platforms)
      final Directory? downloadsDir = await getApplicationDocumentsDirectory();
      if (downloadsDir == null) {
        if (mounted) {
          _showError('Could not access storage folder.');
        }
        return;
      }

      // Create filename from report ID
      final fileName =
          'Report_${report.shortId}_${report.periodLabel.replaceAll(' ', '_')}.xlsx';
      final localFile = File('${downloadsDir.path}/$fileName');

      // Write file to local storage
      await localFile.writeAsBytes(fileData);

      // Open the file
      final result = await OpenFile.open(localFile.path);

      if (!mounted) return;

      if (result.type == ResultType.done) {
        _showSuccess('File opened: $fileName');
      } else {
        _showSuccess('File downloaded to: ${localFile.path}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error downloading file: $e');
      }
    }
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void _clearFilters() {
    setState(() {
      _filterMonth = '';
      _filterYear = '';
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  List<GeneratedReport> get _filteredReports {
    var list = _reports;
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) => r.id.toLowerCase().contains(q)).toList();
    }
    if (_filterMonth.isNotEmpty && _filterMonth != 'All Months') {
      list = list.where((r) => r.periodLabel.contains(_filterMonth)).toList();
    }
    if (_filterYear.isNotEmpty && _filterYear != 'All Years') {
      final y = int.tryParse(_filterYear);
      if (y != null) list = list.where((r) => r.periodYear == y).toList();
    }
    return list;
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF00C48C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4D6A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Reports',
      selectedIndex: 2,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return RefreshIndicator(
            onRefresh: _fetchReports,
            color: AppColors.primaryCyan,
            backgroundColor: AppColors.cardBackground,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isNarrow ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _PageHeader(
                    showFilters: _showFilters,
                    isGenerating: _isGenerating,
                    onFilterTap: () =>
                        setState(() => _showFilters = !_showFilters),
                    onGenerateTap: _showGenerateDialog,
                  ),
                  const SizedBox(height: 16),

                  // ── Filters ──
                  if (_showFilters) ...[
                    _FilterSection(
                      months: _months,
                      years: _years,
                      selectedMonth: _filterMonth,
                      selectedYear: _filterYear,
                      onMonthChanged: (v) =>
                          setState(() => _filterMonth = v ?? ''),
                      onYearChanged: (v) =>
                          setState(() => _filterYear = v ?? ''),
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

                  // ── Section Label ──
                  _SectionLabel(
                    icon: Icons.folder_zip_rounded,
                    label: 'Generated Reports',
                    subtitle: 'DAE-1B Excel files — pull down to refresh',
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

                  // ── Table ──
                  _GeneratedReportsTable(
                    rows: _filteredReports,
                    isLoading: _loadingReports,
                    onDownload: _downloadReport,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
    required this.isLoading,
    required this.onDownload,
  });

  final List<GeneratedReport> rows;
  final bool isLoading;
  final void Function(GeneratedReport) onDownload;

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
          // Header
          LayoutBuilder(
            builder: (_, constraints) =>
                _TableHeader(isNarrow: constraints.maxWidth < 700),
          ),
          const Divider(color: AppColors.cardBorder, height: 1),

          // Body
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryCyan,
              ),
            )
          else if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No reports yet. Use "Generate Report" to create one.',
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
                builder: (_, constraints) => _TableRow(
                  report: rows[i],
                  isNarrow: constraints.maxWidth < 700,
                  onDownload: () => onDownload(rows[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.isNarrow});
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 4, child: _HeaderCell('Report ID')),
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
          Expanded(flex: 4, child: _HeaderCell('Report ID')),
          Expanded(flex: 2, child: _HeaderCell('Type')),
          Expanded(flex: 2, child: _HeaderCell('Period')),
          Expanded(flex: 2, child: _HeaderCell('Sheets')),
          Expanded(flex: 3, child: _HeaderCell('Generated At')),
          SizedBox(width: 80, child: _HeaderCell('File')),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.report,
    required this.isNarrow,
    required this.onDownload,
  });

  final GeneratedReport report;
  final bool isNarrow;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${report.generatedAt.year}-'
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
                  _ReportIdBadge(shortId: report.shortId),
                  const SizedBox(height: 3),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11.5,
                    ),
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
              child: _DownloadButton(
                hasFile: report.hasFile,
                onTap: onDownload,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Report ID
          Expanded(
            flex: 4,
            child: Tooltip(
              message: report.id,
              child: _ReportIdBadge(shortId: report.shortId),
            ),
          ),
          // Report type badge
          Expanded(flex: 2, child: _TypeBadge(label: report.reportType)),
          // Period
          Expanded(
            flex: 2,
            child: Text(
              report.periodLabel,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          // Sheet pills
          Expanded(flex: 2, child: _SheetPills(options: report.sheetOptions)),
          // Generated date
          Expanded(
            flex: 3,
            child: Text(
              dateStr,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          // Download
          SizedBox(
            width: 80,
            child: _DownloadButton(hasFile: report.hasFile, onTap: onDownload),
          ),
        ],
      ),
    );
  }
}

// ─── Report ID Badge ──────────────────────────────────────────────────────────

class _ReportIdBadge extends StatelessWidget {
  const _ReportIdBadge({required this.shortId});
  final String shortId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.tag_rounded, color: AppColors.textSubtle, size: 13),
        const SizedBox(width: 4),
        Text(
          shortId,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryCyan.withOpacity(0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primaryCyan.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryCyan,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SheetPills extends StatelessWidget {
  const _SheetPills({this.options});
  final ReportSheetOptions? options;

  @override
  Widget build(BuildContext context) {
    if (options == null) {
      return const Text(
        '—',
        style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (options!.includeDailySheet) _Pill('S1'),
        if (options!.includeCountrySumSheet) _Pill('S2'),
        if (options!.includeMonthlySummarySheet) _Pill('S3'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryCyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primaryCyan.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryCyan,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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
        child: Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFFF4D6A),
          size: 18,
        ),
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
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download_rounded,
                color: AppColors.primaryCyan,
                size: 14,
              ),
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
      ),
    );
  }
}

// ─── Generate Report Dialog ───────────────────────────────────────────────────


class _GenerateReportDialog extends StatefulWidget {
  const _GenerateReportDialog({
    required this.months,
    required this.years,
    required this.onGenerate,
  });

  final List<String> months;
  final List<String> years;
  final void Function({
    required int month,
    required int year,
    required ReportSheetOptions sheetOptions,
  }) onGenerate;

  @override
  State<_GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<_GenerateReportDialog> {
  String? _selectedMonth;
  String? _selectedYear;

  bool _sheet1 = true;
  bool _sheet2 = true;
  bool _sheet3 = true;

  bool get _canGenerate =>
      _selectedMonth != null &&
      _selectedYear != null &&
      (_sheet1 || _sheet2 || _sheet3);

  static int _monthIndex(String name) {
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded,
                        color: AppColors.primaryCyan, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generate DAE-1B Report',
                          style: TextStyle(color: AppColors.textWhite,
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('All approved establishments · export as .xlsx',
                          style: TextStyle(color: AppColors.textGray, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Month
              const _DialogLabel('Month'),
              const SizedBox(height: 6),
              _DropdownField<String>(
                hint: 'Select month',
                value: _selectedMonth,
                items: widget.months,
                itemLabel: (m) => m,
                onChanged: (v) => setState(() => _selectedMonth = v),
              ),
              const SizedBox(height: 14),

              // Year
              const _DialogLabel('Year'),
              const SizedBox(height: 6),
              _DropdownField<String>(
                hint: 'Select year',
                value: _selectedYear,
                items: widget.years,
                itemLabel: (y) => y,
                onChanged: (v) => setState(() => _selectedYear = v),
              ),
              const SizedBox(height: 18),

              // Sheet selection
              const Text('Include Sheets',
                  style: TextStyle(color: AppColors.textGray,
                      fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _SheetToggle(
                      label: 'Daily Breakdown',
                      subtitle: 'One tab per establishment for selected month',
                      value: _sheet1,
                      onChanged: (v) => setState(() => _sheet1 = v),
                      isFirst: true,
                    ),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    _SheetToggle(
                      label: 'Country Summary',
                      subtitle: 'All establishments combined — selected month',
                      value: _sheet2,
                      onChanged: (v) => setState(() => _sheet2 = v),
                    ),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    _SheetToggle(
                      label: 'Monthly Summary',
                      subtitle: 'All 12 months of the year — all establishments',
                      value: _sheet3,
                      onChanged: (v) => setState(() => _sheet3 = v),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              if (!_sheet1 && !_sheet2 && !_sheet3)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Select at least one sheet to generate.',
                      style: TextStyle(color: Color(0xFFFF4D6A), fontSize: 11.5)),
                ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _canGenerate
                        ? () => widget.onGenerate(
                              month: _monthIndex(_selectedMonth!),
                              year: int.parse(_selectedYear!),
                              sheetOptions: ReportSheetOptions(
                                includeDailySheet: _sheet1,
                                includeCountrySumSheet: _sheet2,
                                includeMonthlySummarySheet: _sheet3,
                              ),
                            )
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
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
                          Icon(Icons.auto_awesome_rounded, size: 15,
                              color: _canGenerate ? Colors.black : Colors.black45),
                          const SizedBox(width: 6),
                          Text('Generate & Save',
                              style: TextStyle(
                                  color: _canGenerate ? Colors.black : Colors.black45,
                                  fontSize: 13, fontWeight: FontWeight.w600)),
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

class _SheetToggle extends StatelessWidget {
  const _SheetToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(10) : Radius.zero,
        bottom: isLast ? const Radius.circular(10) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primaryCyan,
                checkColor: Colors.black,
                side: const BorderSide(color: AppColors.textGray, width: 1.2),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: value ? AppColors.textWhite : AppColors.textGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: value ? AppColors.textGray : AppColors.textSubtle,
                      fontSize: 11,
                    ),
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

// ─── Shared small widget helpers ──────────────────────────────────────────────

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint,
            style: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textGray,
            size: 20,
          ),
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
          dropdownColor: AppColors.cardBackground,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Filter Section ───────────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.months,
    required this.years,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onClear,
  });

  final List<String> months;
  final List<String> years;
  final String selectedMonth;
  final String selectedYear;
  final void Function(String?) onMonthChanged;
  final void Function(String?) onYearChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width >= 600 ? 2 : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
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
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 4.2,
            children: [
              _FilterDropdown(
                label: 'Month',
                value: selectedMonth.isEmpty ? 'All Months' : selectedMonth,
                items: months,
                onChanged: onMonthChanged,
              ),
              _FilterDropdown(
                label: 'Year',
                value: selectedYear.isEmpty ? 'All Years' : selectedYear,
                items: years,
                onChanged: onYearChanged,
              ),
            ],
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
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Container(
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
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textGray,
                  size: 20,
                ),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                ),
                dropdownColor: AppColors.cardBackground,
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
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
          hintText: 'Search by report ID…',
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

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.showFilters,
    required this.isGenerating,
    required this.onFilterTap,
    required this.onGenerateTap,
  });

  final bool showFilters;
  final bool isGenerating;
  final VoidCallback onFilterTap;
  final VoidCallback onGenerateTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 700;

    final filterBtn = _HeaderButton(
      icon: Icons.filter_list_rounded,
      label: narrow ? null : 'Filters',
      isActive: showFilters,
      onTap: onFilterTap,
    );

    final generateBtn = _HeaderButton(
      icon: Icons.description_rounded,
      label: narrow ? null : 'Generate Report',
      isPrimary: true,
      isLoading: isGenerating,
      onTap: onGenerateTap,
    );

    const titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Generate and download DAE-1B Excel reports',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [filterBtn, generateBtn]),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        titleBlock,
        Row(children: [filterBtn, const SizedBox(width: 10), generateBtn]),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.isActive = false,
    this.isPrimary = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;

    if (isPrimary) {
      bg = AppColors.primaryCyan;
      border = AppColors.primaryCyan;
      fg = Colors.black;
    } else if (isActive) {
      bg = AppColors.primaryCyan.withOpacity(0.15);
      border = AppColors.primaryCyan;
      fg = AppColors.primaryCyan;
    } else {
      bg = AppColors.cardBackground;
      border = AppColors.cardBorder;
      fg = AppColors.textGray;
    }

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryCyan,
                ),
              )
            else
              Icon(icon, color: fg, size: 16),
            if (label != null && !isLoading) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
