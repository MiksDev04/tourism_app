// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import 'package:tourism_app/core/services/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tourism_app/ui/shared/pages/error_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../../shared/widgets/paginator.dart';
import '../../../api/admin_report_api.dart';

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
      includeDailySheet: row['include_sheet_establishment'] as bool? ?? true,
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
  final ReportService _reportService = ReportService();
  final _supabase = Supabase.instance.client;

  List<GeneratedReport> _reports = [];

  bool _loadingReports = false;
  int? _errorCode;
  String? _fetchError;
  bool _isGenerating = false;
  bool _showFilters = false;
  String _searchQuery = '';
  String _filterMonth = '';
  String _filterYear = '';
  int _currentPage = 0;
  int _pageSize = 10;

  final _searchCtrl = TextEditingController();

  static const List<int> _pageSizeOptions = [10, 20, 30];

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

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() {
      _loadingReports = true;
      _fetchError = null;
      _errorCode = null;
    });
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
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _fetchError = 'no_internet';
        _errorCode = 503;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchError = e.toString();
        _errorCode = 500;
      });
    } finally {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

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
        onGenerate: ({
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

  // ── View Report ───────────────────────────────────────────────────────────

  void _viewReport(GeneratedReport report) {
    if (!report.hasFile) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ReportViewerModal(
        report: report,
        supabase: _supabase,
        onDownloadExcel: () => _downloadReport(report),
      ),
    );
  }

  // ── Download Excel ────────────────────────────────────────────────────────

  Future<void> _downloadReport(GeneratedReport report) async {
    if (!report.hasFile) return;
    try {
      _showSuccess('Downloading file...');
      String filePath = report.fileUrl!;
      if (filePath.contains('/')) {
        filePath = filePath.split('/reports/').last;
      }
      final fileData = await _supabase.storage
          .from('reports')
          .download(filePath);

      final fileName =
          'Report_${report.shortId}_${report.periodLabel.replaceAll(' ', '_')}.xlsx';

      if (kIsWeb) {
        await saveFileToDownloads(fileName, fileData);
        if (!mounted) return;
        _showSuccess('File downloaded: $fileName');
        return;
      }

      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        if (mounted) _showError('Could not access the Downloads folder.');
        return;
      }

      final localFile = File('${downloadsDir.path}/$fileName');
      await localFile.writeAsBytes(fileData);
      if (!mounted) return;
      await _openFile(localFile);
      _showSuccess('File saved to Downloads: $fileName');
    } catch (e) {
      if (mounted) _showError('Error downloading file: $e');
    }
  }

  Future<void> _openFile(File file) async {
    try {
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) _showError('Could not open file.');
      }
    } catch (e) {
      if (mounted) _showError('Could not open file: $e');
    }
  }

  void _clearFilters() {
    setState(() {
      _filterMonth = '';
      _filterYear = '';
      _searchQuery = '';
      _searchCtrl.clear();
      _currentPage = 0;
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

  int get _totalPages =>
      (_filteredReports.length / _pageSize).ceil().clamp(1, 999);

  int get _clampedPage => _currentPage.clamp(0, _totalPages - 1);

  List<GeneratedReport> get _pagedReports {
    final start = _clampedPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredReports.length);
    return _filteredReports.sublist(start, end);
  }

  void _resetPage() => _currentPage = 0;

  void _showSuccess(
    String msg, {
    String? actionText,
    VoidCallback? onActionPressed,
    Duration? duration,
    SnackBarBehavior? behavior,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00C48C),
        behavior: behavior ?? SnackBarBehavior.fixed,
        margin:
            (behavior ?? SnackBarBehavior.fixed) == SnackBarBehavior.floating
            ? const EdgeInsets.fromLTRB(16, 0, 16, 16)
            : null,
        duration: duration ?? const Duration(seconds: 3),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        action: (actionText != null && onActionPressed != null)
            ? SnackBarAction(
                label: actionText,
                onPressed: onActionPressed,
                textColor: Colors.white,
              )
            : null,
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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Report',
      selectedIndex: 2,
      onNavSelected: (_) {},
      child: _fetchError != null
          ? ErrorPage(statusCode: _errorCode ?? 500, onRetry: _fetchReports)
          : LayoutBuilder(
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
                        _PageHeader(
                          isNarrow: isNarrow,
                          showFilters: _showFilters,
                          isGenerating: _isGenerating,
                          onFilterTap: () =>
                              setState(() => _showFilters = !_showFilters),
                          onGenerateTap: _showGenerateDialog,
                        ),
                        const SizedBox(height: 16),
                        if (_showFilters) ...[
                          _FilterSection(
                            months: _months,
                            years: _years,
                            selectedMonth: _filterMonth,
                            selectedYear: _filterYear,
                            onMonthChanged: (v) => setState(() {
                              _filterMonth = v ?? '';
                              _resetPage();
                            }),
                            onYearChanged: (v) => setState(() {
                              _filterYear = v ?? '';
                              _resetPage();
                            }),
                            onClear: _clearFilters,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _SearchBar(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() {
                            _searchQuery = v;
                            _resetPage();
                          }),
                        ),
                        const SizedBox(height: 20),
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
                        if (_loadingReports)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryCyan,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          _GeneratedReportsTable(
                            rows: _pagedReports,
                            isLoading: false,
                            onView: _viewReport,
                          ),
                        if (!_loadingReports) ...[
                          const SizedBox(height: 12),
                          Paginator(
                            currentPage: _clampedPage,
                            totalPages: _totalPages,
                            totalItems: _filteredReports.length,
                            pageSize: _pageSize,
                            pageSizeOptions: _pageSizeOptions,
                            onPageSizeChanged: (size) => setState(() {
                              _pageSize = size;
                              _currentPage = 0;
                            }),
                            onPageChanged: (page) => setState(() {
                              _currentPage = page;
                            }),
                          ),
                        ],
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

// ─── Report Viewer Modal ──────────────────────────────────────────────────────

class _ReportViewerModal extends StatefulWidget {
  const _ReportViewerModal({
    required this.report,
    required this.supabase,
    required this.onDownloadExcel,
  });

  final GeneratedReport report;
  final SupabaseClient supabase;
  final VoidCallback onDownloadExcel;

  @override
  State<_ReportViewerModal> createState() => _ReportViewerModalState();
}

class _ReportViewerModalState extends State<_ReportViewerModal>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  Excel? _excel;

  Uint8List? _excelBytes;

  int _activeSheetIndex = 0;
  bool _exportingExcel = false;

  bool _exportingPdf = false;
  final _reportService = ReportService();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    try {
      String filePath = widget.report.fileUrl!;
      if (filePath.contains('/reports/')) {
        filePath = filePath.split('/reports/').last;
      }
      final bytes = await widget.supabase.storage
          .from('reports')
          .download(filePath);

      _excelBytes = bytes;

      final excel = Excel.decodeBytes(bytes);
      if (!mounted) return;
      setState(() {
        _excel = excel;
        _loading = false;
        _tabController = TabController(
          length: excel.sheets.length,
          vsync: this,
        );
        _tabController.addListener(() {
          if (!_tabController.indexIsChanging) {
            setState(() => _activeSheetIndex = _tabController.index);
          }
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exportingExcel = true);
    try {
      widget.onDownloadExcel();
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_excelBytes == null) return;
    setState(() => _exportingPdf = true);
    try {
      final pdfBytes = await _reportService.convertExcelToPdf(_excelBytes!);
      final fileName =
          'Report_${widget.report.shortId}_'
          '${widget.report.periodLabel.replaceAll(' ', '_')}.pdf';

      if (kIsWeb) {
        await saveFileToDownloads(fileName, pdfBytes);
        if (mounted) _showModalSnack('PDF downloaded: $fileName');
      } else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          if (mounted) {
            _showModalSnack('Could not access Downloads folder.', isError: true);
          }
          return;
        }
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        if (!mounted) return;
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        _showModalSnack('PDF saved: $fileName');
      }
    } catch (e) {
      if (mounted) _showModalSnack('Error exporting PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _showModalSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor:
            isError ? const Color(0xFFFF4D6A) : const Color(0xFF00C48C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: size.width * 0.95,
        height: size.height * 0.92,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            _ModalHeader(
              report: widget.report,
              onClose: () => Navigator.pop(context),
              onExportExcel: _exportingExcel ? null : _exportExcel,
              exportingExcel: _exportingExcel,
              onExportPdf:
                  (_exportingPdf || _excelBytes == null) ? null : _exportPdf,
              exportingPdf: _exportingPdf,
            ),

            const Divider(color: AppColors.cardBorder, height: 1),

            if (!_loading && _error == null && _excel != null)
              _SheetTabBar(
                sheetNames: _excel!.sheets.keys.toList(),
                tabController: _tabController,
              ),

            Expanded(
              child: _loading
                  ? const _LoadingView()
                  : _error != null
                  ? _ErrorView(error: _error!)
                  : _SheetTabView(
                      excel: _excel!,
                      tabController: _tabController,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modal Header ──────────────────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.report,
    required this.onClose,
    required this.onExportExcel,
    required this.exportingExcel,
    required this.onExportPdf,
    required this.exportingPdf,
  });

  final GeneratedReport report;
  final VoidCallback onClose;
  final VoidCallback? onExportExcel;
  final bool exportingExcel;
  final VoidCallback? onExportPdf;
  final bool exportingPdf;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.table_chart_rounded,
              color: AppColors.primaryCyan,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      report.reportType,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        report.periodLabel,
                        style: const TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Report ID: ${report.shortId}',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ExportButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Export PDF',
                color: const Color(0xFFD32F2F),
                borderColor: const Color(0xFFD32F2F),
                isLoading: exportingPdf,
                onTap: onExportPdf,
              ),
              const SizedBox(width: 8),

              _ExportButton(
                icon: Icons.table_rows_rounded,
                label: 'Export Excel',
                color: const Color(0xFF1D6F42),
                borderColor: const Color(0xFF1D6F42),
                isLoading: exportingExcel,
                onTap: onExportExcel,
              ),
              const SizedBox(width: 10),

              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textGray,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
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

// ── Sheet Tab Bar ─────────────────────────────────────────────────────────────

class _SheetTabBar extends StatelessWidget {
  const _SheetTabBar({required this.sheetNames, required this.tabController});

  final List<String> sheetNames;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: AppColors.cardBorder,
        indicatorColor: AppColors.primaryCyan,
        indicatorWeight: 2,
        labelColor: AppColors.primaryCyan,
        unselectedLabelColor: AppColors.textGray,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        tabs: sheetNames.asMap().entries.map((e) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_sheetIcon(e.key), size: 13),
                const SizedBox(width: 6),
                Text(e.value),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _sheetIcon(int index) {
    switch (index) {
      case 0:
        return Icons.calendar_today_rounded;
      case 1:
        return Icons.public_rounded;
      case 2:
        return Icons.bar_chart_rounded;
      default:
        return Icons.grid_on_rounded;
    }
  }
}

// ── Sheet Tab View ────────────────────────────────────────────────────────────

class _SheetTabView extends StatelessWidget {
  const _SheetTabView({required this.excel, required this.tabController});

  final Excel excel;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final sheets = excel.sheets.entries.toList();
    return TabBarView(
      controller: tabController,
      children: sheets.map((entry) {
        return _SheetGridView(sheetName: entry.key, sheet: entry.value);
      }).toList(),
    );
  }
}

// ─── Sheet Grid View ──────────────────────────────────────────────────────────
// Scrolling: normal vertical + horizontal ScrollViews with visible scrollbars.
// Zoom: + / − toolbar buttons and pinch-to-zoom on touch only.
//       Scroll wheel / trackpad scrolls normally and does NOT zoom.

class _SheetGridView extends StatefulWidget {
  const _SheetGridView({required this.sheetName, required this.sheet});

  final String sheetName;
  final Sheet sheet;

  @override
  State<_SheetGridView> createState() => _SheetGridViewState();
}

class _SheetGridViewState extends State<_SheetGridView> {
  // ── Zoom state ────────────────────────────────────────────────────────────
  double _scale = 1.0;
  double _startScale = 1.0;   // captured at the start of each pinch gesture

  // ── Scroll controllers for the two scrollbars ─────────────────────────────
  late final ScrollController _vertScrollCtrl;
  late final ScrollController _horizScrollCtrl;

  static const double _minScale = 0.4;
  static const double _maxScale = 3.0;
  static const double _scaleStep = 0.2;

  @override
  void initState() {
    super.initState();
    _vertScrollCtrl  = ScrollController();
    _horizScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _vertScrollCtrl.dispose();
    _horizScrollCtrl.dispose();
    super.dispose();
  }

  // ── Toolbar zoom actions ──────────────────────────────────────────────────
  void _zoomIn() =>
      setState(() => _scale = (_scale + _scaleStep).clamp(_minScale, _maxScale));

  void _zoomOut() =>
      setState(() => _scale = (_scale - _scaleStep).clamp(_minScale, _maxScale));

  void _zoomReset() => setState(() => _scale = 1.0);

  // ── Excel exact colours ───────────────────────────────────────────────────
  static const Color _cBlue        = Color(0xFF0070C0);
  static const Color _cGreen       = Color(0xFF92D050);
  static const Color _cLightBlue   = Color(0xFF00B0F0);
  static const Color _cYellow      = Color(0xFFFFFF00);
  static const Color _cLightYellow = Color(0xFFFFFF66);
  static const Color _cWhite       = Color(0xFFFFFFFF);
  static const Color _cGridBorder  = Color(0xFFBFBFBF);

  static Color _textOn(Color bg) =>
      bg == _cBlue ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  Color _bgForRow(String label, int rowIndex, {bool isPartII = false}) {
    if (rowIndex < 10) return _cWhite;
    final u = label.trim().toUpperCase();

    if (u == 'COUNTRY OF RESIDENCE')   return _cLightYellow;
    if (u.contains('GRAND TOTAL'))      return _cYellow;
    if (u == 'A. DAE2:' || u.contains('VOLUME PER SEX')) return _cYellow;

    if (u == 'TOTAL PHILIPPINE RESIDENTS'      ||
        u == 'TOTAL NON-PHILIPPINE RESIDENTS'  ||
        u == 'TOTAL OVERSEAS FILIPINOS'         ||
        u.startsWith('   TOTAL PHILIPPINE')    ||
        u.startsWith('   TOTAL NON-PHILIPPINE') ||
        u.startsWith('   TOTAL OVERSEAS')       ||
        u.startsWith('   TOTAL GUEST'))          return _cGreen;

    if (u.contains('SUB-TOTAL')) return _cLightBlue;

    if (u == 'PHILIPPINE RESIDENTS'            ||
        u == 'NON-PHILIPPINE RESIDENTS'         ||
        u == 'ASIA'   || u == 'AMERICA'         ||
        u == 'EUROPE' || u == 'AFRICA'          ||
        u.startsWith('AUSTRALASIA')             ||
        u.trimLeft().startsWith('ASEAN')        ||
        u.trimLeft().startsWith('EAST ASIA')    ||
        u.trimLeft().startsWith('SOUTH ASIA')   ||
        u.trimLeft().startsWith('MIDDLE EAST')  ||
        u.trimLeft().startsWith('NORTH AMERICA') ||
        u.trimLeft().startsWith('SOUTH AMERICA') ||
        u.trimLeft().startsWith('WESTERN EUROPE') ||
        u.trimLeft().startsWith('NORTHERN EUROPE') ||
        u.trimLeft().startsWith('SOUTHERN EUROPE')  ||
        u.trimLeft().startsWith('EASTERN EUROPE')   ||
        u.trimLeft().startsWith('AUSTRALASIA')       ||
        (!isPartII && u.contains('OVERSEAS FILIPINOS')) ||
        u.contains('OTHERS AND UNSPECIFIED NON-PHILIPPINE')) return _cBlue;

    return _cWhite;
  }

  bool _isBold(String label, int rowIndex, {bool isPartII = false}) {
    if (rowIndex < 10) return false;
    final bg = _bgForRow(label, rowIndex, isPartII: isPartII);
    if (bg != _cWhite) return true;
    if (label.startsWith('       ') && label.trim().isNotEmpty) return true;
    if (label.trim().toUpperCase() == 'X. TOTAL') return true;
    return false;
  }

  // ── Column widths (Excel units → logical pixels) ──────────────────────────
  static const double _colLabelW = 320.0;
  static const double _colDayW   =  33.0;
  static const double _colTotalW = 101.0;
  static const double _rowH      =  18.0;

  double _colWidth(int colIndex, int maxCols) {
    if (colIndex == 0)           return _colLabelW;
    if (colIndex == maxCols - 1) return _colTotalW;
    if (maxCols == 14)           return 52.0;
    if (maxCols == 2)            return _colTotalW;
    return _colDayW;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.sheet.rows;
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'This sheet is empty.',
          style: TextStyle(color: Color(0xFF888888), fontSize: 13),
        ),
      );
    }

    int maxCols = 0;
    for (final row in rows) {
      if (row.length > maxCols) maxCols = row.length;
    }
    if (maxCols == 0) maxCols = 1;

    double totalW = 0;
    for (int c = 0; c < maxCols; c++) {
      totalW += _colWidth(c, maxCols);
    }

    // Detect PART II range to suppress blue on "Overseas Filipinos" there.
    int partIIStart = rows.length;
    int partIIEnd   = rows.length;
    for (int i = 0; i < rows.length; i++) {
      final first = rows[i].isNotEmpty
          ? (rows[i][0]?.value?.toString() ?? '').trim().toUpperCase()
          : '';
      if (first == 'PART II.  OTHER INDICATORS') {
        partIIStart = i;
        break;
      }
    }
    if (partIIStart < rows.length) {
      for (int i = partIIStart + 1; i < rows.length; i++) {
        final first = rows[i].isNotEmpty
            ? (rows[i][0]?.value?.toString() ?? '').trim().toUpperCase()
            : '';
        if (first.startsWith('PART ')) {
          partIIEnd = i;
          break;
        }
      }
    }

    return Column(
      children: [
        // ── Zoom toolbar ──────────────────────────────────────────────────
        _ZoomBar(
          scale: _scale,
          onZoomIn: _zoomIn,
          onZoomOut: _zoomOut,
          onZoomReset: _zoomReset,
        ),

        // ── Scrollable sheet content with visible scrollbars ──────────────
        // GestureDetector only intercepts multi-pointer (pinch) gestures for
        // zoom.  Single-pointer touches are passed through to the scroll views.
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: MaterialStatePropertyAll(
                AppColors.primaryCyan.withOpacity(0.95),
              ),
              trackColor: MaterialStatePropertyAll(
                AppColors.backgroundDark.withOpacity(0.85),
              ),
              trackBorderColor: MaterialStatePropertyAll(
                AppColors.primaryCyan.withOpacity(0.18),
              ),
              thumbVisibility: const MaterialStatePropertyAll(true),
              trackVisibility: const MaterialStatePropertyAll(true),
              thickness: const MaterialStatePropertyAll(11),
              radius: const Radius.circular(6),
              minThumbLength: 48,
            ),
            child: GestureDetector(
              onScaleStart: (details) => _startScale = _scale,
              onScaleUpdate: (details) {
                // Only react when two or more fingers are on screen (pinch).
                if (details.pointerCount >= 2) {
                  setState(() {
                    _scale = (_startScale * details.scale)
                        .clamp(_minScale, _maxScale);
                  });
                }
              },
              child: Scrollbar(
                controller: _horizScrollCtrl,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 11,
                radius: const Radius.circular(6),
                child: Scrollbar(
                  controller: _vertScrollCtrl,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.vertical,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 11,
                  radius: const Radius.circular(6),
                  child: SingleChildScrollView(
                    controller: _vertScrollCtrl,
                    child: SingleChildScrollView(
                      controller: _horizScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      child: Transform.scale(
                        scale: _scale,
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
                          child: SizedBox(
                            width: totalW,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rows.asMap().entries.map((entry) {
                                final isPartII = entry.key >= partIIStart &&
                                    entry.key < partIIEnd;
                                return _buildRow(
                                  entry.key,
                                  entry.value,
                                  maxCols,
                                  totalW,
                                  isPartII: isPartII,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
          ],
            );
  }

  Widget _buildRow(
    int rowIndex,
    List<Data?> cells,
    int maxCols,
    double totalW, {
    bool isPartII = false,
  }) {
    final firstVal =
        cells.isNotEmpty ? (cells[0]?.value?.toString() ?? '') : '';

    if (rowIndex < 10) {
      return _MetaRow(rowIndex: rowIndex, value: firstVal, totalW: totalW);
    }

    final bg   = _bgForRow(firstVal, rowIndex, isPartII: isPartII);
    final bold = _isBold(firstVal, rowIndex, isPartII: isPartII);
    final tc   = _textOn(bg);
    final isColHdrRow =
        firstVal.trim().toUpperCase() == 'COUNTRY OF RESIDENCE';

    return SizedBox(
      height: _rowH,
      child: Row(
        children: List.generate(maxCols, (colIndex) {
          final cell    = colIndex < cells.length ? cells[colIndex] : null;
          final raw     = cell?.value?.toString() ?? '';
          final isFirst = colIndex == 0;
          final colW    = _colWidth(colIndex, maxCols);

          return Container(
            width:  colW,
            height: _rowH,
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top:    BorderSide(color: _cGridBorder, width: 0.5),
                bottom: BorderSide(color: _cGridBorder, width: 0.5),
                left:   BorderSide(color: _cGridBorder, width: 0.5),
                right:  BorderSide(color: _cGridBorder, width: 0.5),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isFirst ? 4 : 1,
              vertical: 1,
            ),
            alignment: isFirst ? Alignment.centerLeft : Alignment.center,
            child: Text(
              raw,
              style: TextStyle(
                fontFamily:
                    (isColHdrRow && !isFirst) ? 'Bell MT' : 'Calibri',
                fontSize: 8.5,
                fontWeight: bold || isColHdrRow
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: tc,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isFirst ? TextAlign.left : TextAlign.center,
            ),
          );
        }),
      ),
    );
  }
}

// ─── Metadata header rows (0–9) ───────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.rowIndex,
    required this.value,
    required this.totalW,
  });

  final int rowIndex;
  final String value;
  final double totalW;

  @override
  Widget build(BuildContext context) {
    final isBigTitle = rowIndex == 4;
    final isCentered = rowIndex >= 1 && rowIndex <= 4;

    return SizedBox(
      width: totalW,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: isBigTitle ? 3 : 1.5,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: isBigTitle ? 11.0 : 9.0,
            fontWeight: (rowIndex >= 5 || isBigTitle)
                ? FontWeight.bold
                : FontWeight.normal,
            color: const Color(0xFF000000),
          ),
          textAlign: isCentered ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }
}

// ─── Zoom toolbar ─────────────────────────────────────────────────────────────

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomReset,
  });

  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomReset;

  @override
  Widget build(BuildContext context) {
    final pct = '${(scale * 100).round()}%';
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2332),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2D3F55), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Zoom out
          _ZoomBtn(
            icon: Icons.remove_rounded,
            onTap: onZoomOut,
            tooltip: 'Zoom out',
          ),
          // Percentage label — tap to reset to 100 %
          GestureDetector(
            onTap: onZoomReset,
            child: Container(
              width: 52,
              alignment: Alignment.center,
              child: Text(
                pct,
                style: const TextStyle(
                  color: Color(0xFFCDD6E0),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          // Zoom in
          _ZoomBtn(
            icon: Icons.add_rounded,
            onTap: onZoomIn,
            tooltip: 'Zoom in',
          ),
          const SizedBox(width: 8),
          // Reset label
          GestureDetector(
            onTap: onZoomReset,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFF5DADE2),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          // Hints — updated to reflect new scroll + pinch-only zoom behaviour
          const Icon(Icons.open_with_rounded,
              color: Color(0xFF4A6580), size: 13),
          const SizedBox(width: 3),
          const Text(
            'scroll to pan',
            style: TextStyle(color: Color(0xFF4A6580), fontSize: 10.5),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.pinch_rounded, color: Color(0xFF4A6580), size: 13),
          const SizedBox(width: 3),
          const Text(
            'pinch to zoom',
            style: TextStyle(color: Color(0xFF4A6580), fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF243447),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF2D3F55)),
          ),
          child: Icon(icon, color: const Color(0xFFCDD6E0), size: 14),
        ),
      ),
    );
  }
}

// ── Loading & Error Views ─────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryCyan,
            strokeWidth: 2,
          ),
          SizedBox(height: 14),
          Text(
            'Loading spreadsheet…',
            style: TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF4D6A),
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load the spreadsheet.',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                style:
                    const TextStyle(color: AppColors.textGray, fontSize: 12),
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
    required this.onView,
  });

  final List<GeneratedReport> rows;
  final bool isLoading;
  final void Function(GeneratedReport) onView;

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
            builder: (_, constraints) =>
                _TableHeader(isNarrow: constraints.maxWidth < 700),
          ),
          const Divider(color: AppColors.cardBorder, height: 1),
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
                  onView: () => onView(rows[i]),
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
            SizedBox(width: 72),
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
          SizedBox(width: 88, child: _HeaderCell('Actions')),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.report,
    required this.isNarrow,
    required this.onView,
  });

  final GeneratedReport report;
  final bool isNarrow;
  final VoidCallback onView;

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
                style:
                    const TextStyle(color: AppColors.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 72,
              child: _ViewButton(hasFile: report.hasFile, onTap: onView),
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
            child: Tooltip(
              message: report.id,
              child: _ReportIdBadge(shortId: report.shortId),
            ),
          ),
          Expanded(flex: 2, child: _TypeBadge(label: report.reportType)),
          Expanded(
            flex: 2,
            child: Text(
              report.periodLabel,
              style:
                  const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(flex: 2, child: _SheetPills(options: report.sheetOptions)),
          Expanded(
            flex: 3,
            child: Text(
              dateStr,
              style:
                  const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 88,
            child: _ViewButton(hasFile: report.hasFile, onTap: onView),
          ),
        ],
      ),
    );
  }
}

// ─── View Button ──────────────────────────────────────────────────────────────

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.hasFile, required this.onTap});
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
                Icons.open_in_full_rounded,
                color: AppColors.primaryCyan,
                size: 13,
              ),
              SizedBox(width: 5),
              Text(
                'View',
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

// ─── Small shared widgets ─────────────────────────────────────────────────────

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
        if (options!.includeDailySheet) const _Pill('S1'),
        if (options!.includeCountrySumSheet) const _Pill('S2'),
        if (options!.includeMonthlySummarySheet) const _Pill('S3'),
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
                        'All approved establishments · export as .xlsx',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
              const Text(
                'Include Sheets',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                      subtitle:
                          'One tab per establishment for selected month',
                      value: _sheet1,
                      onChanged: (v) => setState(() => _sheet1 = v),
                      isFirst: true,
                    ),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    _SheetToggle(
                      label: 'Country Summary',
                      subtitle:
                          'All establishments combined — selected month',
                      value: _sheet2,
                      onChanged: (v) => setState(() => _sheet2 = v),
                    ),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    _SheetToggle(
                      label: 'Monthly Summary',
                      subtitle:
                          'All 12 months of the year — all establishments',
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
                  child: Text(
                    'Select at least one sheet to generate.',
                    style:
                        TextStyle(color: Color(0xFFFF4D6A), fontSize: 11.5),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style:
                          TextStyle(color: AppColors.textGray, fontSize: 13),
                    ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
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
                            color: _canGenerate
                                ? Colors.black
                                : Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Generate & Save',
                            style: TextStyle(
                              color: _canGenerate
                                  ? Colors.black
                                  : Colors.black45,
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
                side:
                    const BorderSide(color: AppColors.textGray, width: 1.2),
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
                      color:
                          value ? AppColors.textWhite : AppColors.textGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: value
                          ? AppColors.textGray
                          : AppColors.textSubtle,
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

// ─── Shared small helpers ─────────────────────────────────────────────────────

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
            style: const TextStyle(
                color: AppColors.textSubtle, fontSize: 13),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textGray,
            size: 20,
          ),
          style:
              const TextStyle(color: AppColors.textWhite, fontSize: 13),
          dropdownColor: AppColors.cardBackground,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textWhite, fontSize: 13),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            mainAxisExtent: 58,
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
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  color: AppColors.textWhite, fontSize: 13),
              dropdownColor: AppColors.cardBackground,
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textWhite, fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
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
        style:
            const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Search by report ID…',
          hintStyle:
              TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSubtle,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isNarrow,
    required this.showFilters,
    required this.isGenerating,
    required this.onFilterTap,
    required this.onGenerateTap,
  });

  final bool isNarrow;
  final bool showFilters;
  final bool isGenerating;
  final VoidCallback onFilterTap;
  final VoidCallback onGenerateTap;

  @override
  Widget build(BuildContext context) {
    final filterBtn = _HeaderButton(
      icon: Icons.filter_list_rounded,
      label: isNarrow ? null : 'Filters',
      isActive: showFilters,
      onTap: onFilterTap,
    );

    final generateBtn = _HeaderButton(
      icon: Icons.description_rounded,
      label: isNarrow ? null : 'Generate Report',
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

    if (isNarrow) {
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
      fg = Colors.white;
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: isPrimary
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : BoxDecoration(
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
                  fontWeight:
                      isPrimary ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}