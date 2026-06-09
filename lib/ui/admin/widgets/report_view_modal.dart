// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/core/services/file_saver.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
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
          includeDailySheet:
              row['include_sheet_establishment'] as bool? ?? true,
          includeCountrySumSheet:
              row['include_sheet_country_sum'] as bool? ?? true,
          includeMonthlySummarySheet:
              row['include_sheet_monthly'] as bool? ?? true,
        ),
      );
}

// ─── Report Viewer Modal ──────────────────────────────────────────────────────

class ReportViewerModal extends StatefulWidget {
  const ReportViewerModal({
    super.key,
    required this.report,
    required this.supabase,
    required this.onDownloadExcel,
  });

  final GeneratedReport report;
  final SupabaseClient supabase;
  final VoidCallback onDownloadExcel;

  @override
  State<ReportViewerModal> createState() => _ReportViewerModalState();
}

class _ReportViewerModalState extends State<ReportViewerModal>
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
      final bytes =
          await widget.supabase.storage.from('reports').download(filePath);
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
      final fileName = 'Report_${widget.report.shortId}_'
          '${widget.report.periodLabel.replaceAll(' ', '_')}.pdf';

      if (kIsWeb) {
        await saveFileToDownloads(fileName, pdfBytes);
        if (mounted) _showModalSnack('PDF downloaded: $fileName');
      } else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          if (mounted) {
            _showModalSnack('Could not access Downloads folder.',
                isError: true);
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
    final topPadding = MediaQuery.of(context).padding.top;

    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile
          ? EdgeInsets.only(top: topPadding)
          : const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? size.width : size.width * 0.95,
        height: isMobile ? size.height - topPadding : size.height * 0.92,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
          border: isMobile ? null : Border.all(color: AppColors.cardBorder),
          boxShadow: isMobile
              ? null
              : [
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

  Widget _buildIcon() => Container(
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
      );

  Widget _buildInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  report.reportType,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
      );

  Widget _buildCloseBtn() => GestureDetector(
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
      );

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 10),
                Expanded(child: _buildInfo()),
                const SizedBox(width: 8),
                _buildCloseBtn(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ExportButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Export PDF',
                    color: const Color(0xFFD32F2F),
                    borderColor: const Color(0xFFD32F2F),
                    isLoading: exportingPdf,
                    onTap: onExportPdf,
                    expand: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ExportButton(
                    icon: Icons.table_rows_rounded,
                    label: 'Export Excel',
                    color: const Color(0xFF1D6F42),
                    borderColor: const Color(0xFF1D6F42),
                    isLoading: exportingExcel,
                    onTap: onExportExcel,
                    expand: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(child: _buildInfo()),
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
              _buildCloseBtn(),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Export Button ─────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.isLoading = false,
    this.expand = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool expand;

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
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return isMobile
        ? _MobileSheetDropdown(
            sheetNames: sheetNames,
            tabController: tabController,
          )
        : _DesktopSheetTabBar(
            sheetNames: sheetNames,
            tabController: tabController,
          );
  }
}

class _DesktopSheetTabBar extends StatelessWidget {
  const _DesktopSheetTabBar(
      {required this.sheetNames, required this.tabController});

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
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
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

class _MobileSheetDropdown extends StatefulWidget {
  const _MobileSheetDropdown(
      {required this.sheetNames, required this.tabController});

  final List<String> sheetNames;
  final TabController tabController;

  @override
  State<_MobileSheetDropdown> createState() => _MobileSheetDropdownState();
}

class _MobileSheetDropdownState extends State<_MobileSheetDropdown> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.tabController.index;
    widget.tabController.addListener(_sync);
  }

  void _sync() {
    if (mounted && _selected != widget.tabController.index) {
      setState(() => _selected = widget.tabController.index);
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_sync);
    super.dispose();
  }

  IconData _icon(int i) {
    switch (i) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selected,
          isExpanded: true,
          dropdownColor: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textGray,
            size: 18,
          ),
          selectedItemBuilder: (context) {
            return widget.sheetNames.asMap().entries.map((e) {
              return Row(
                children: [
                  Icon(_icon(e.key), size: 13, color: AppColors.primaryCyan),
                  const SizedBox(width: 8),
                  Text(
                    e.value,
                    style: const TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: widget.sheetNames.asMap().entries.map((e) {
            final isActive = e.key == _selected;
            return DropdownMenuItem<int>(
              value: e.key,
              child: Row(
                children: [
                  Icon(
                    _icon(e.key),
                    size: 13,
                    color: isActive
                        ? AppColors.primaryCyan
                        : AppColors.textGray,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primaryCyan
                            : AppColors.textWhite,
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isActive)
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.primaryCyan,
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            widget.tabController.animateTo(value);
            setState(() => _selected = value);
          },
        ),
      ),
    );
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
//
// DESIGN: Faithfully replicates the ON Blank Form (DAE-1B) Excel design:
//   • All text is BLACK — matches the actual Excel exactly (no white-on-blue)
//   • Font: Arial 8pt for data rows, Bell MT bold+italic for day-number headers
//   • Font sizes: 8pt (data), 9pt (PART II items), 12pt (PART II section headers)
//   • Bold+Italic: country names, sub-region headers (ASEAN, EAST ASIA, etc.),
//     SUB-TOTAL rows, OVERSEAS FILIPINOS, OTHERS AND UNSPECIFIED
//   • Bold only: main region headers (ASIA, AMERICA, etc.), TOTAL rows
//   • Colors: Blue=#0070C0, Green=#92D050, LightBlue=#00B0F0,
//             Yellow=#FFFF00, LightYellow=#FFFF66
//   • Meta header rows (form ID, title, fields) styled faithfully by content
//   • firstDataRow detected dynamically — robust for any report file

class _SheetGridView extends StatefulWidget {
  const _SheetGridView({required this.sheetName, required this.sheet});

  final String sheetName;
  final Sheet sheet;

  @override
  State<_SheetGridView> createState() => _SheetGridViewState();
}

class _SheetGridViewState extends State<_SheetGridView> {
  // ── Zoom ──────────────────────────────────────────────────────────────────
  double _scale = 1.0;
  double _startScale = 1.0;
  static const double _minScale = 0.4;
  static const double _maxScale = 3.0;
  static const double _scaleStep = 0.2;

  // ── Scroll controllers ────────────────────────────────────────────────────
  late final ScrollController _vertScrollCtrl;
  late final ScrollController _horizScrollCtrl;

  @override
  void initState() {
    super.initState();
    _vertScrollCtrl = ScrollController();
    _horizScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _vertScrollCtrl.dispose();
    _horizScrollCtrl.dispose();
    super.dispose();
  }

  void _zoomIn() =>
      setState(() => _scale = (_scale + _scaleStep).clamp(_minScale, _maxScale));
  void _zoomOut() =>
      setState(() => _scale = (_scale - _scaleStep).clamp(_minScale, _maxScale));
  void _zoomReset() => setState(() => _scale = 1.0);

  // ── Exact Excel color palette ─────────────────────────────────────────────
  // Sourced directly from openpyxl cell.fill.fgColor.rgb values in ON Blank Form
  static const Color _cBlue        = Color(0xFF0070C0); // FF0070C0
  static const Color _cGreen       = Color(0xFF92D050); // FF92D050
  static const Color _cLightBlue   = Color(0xFF00B0F0); // FF00B0F0
  static const Color _cYellow      = Color(0xFFFFFF00); // FFFFFF00
  static const Color _cLightYellow = Color(0xFFFFFF66); // FFFFFF66
  static const Color _cWhite       = Color(0xFFFFFFFF);
  // ALL text is black — matches Excel exactly (no white text on blue rows)
  static const Color _cBlack       = Color(0xFF000000);
  static const Color _cGridBorder  = Color(0xFF000000);

  // ── Row background ────────────────────────────────────────────────────────
  // Color rules exactly as in ON Blank Form (DAE-1B):
  //   LightYellow → COUNTRY OF RESIDENCE header (repeating column header)
  //   Yellow      → GRAND TOTAL, A. DAE2:, B. VOLUME PER SEX
  //   Green       → TOTAL PHILIPPINE/NON-PHILIPPINE RESIDENTS + grand-total sub-rows
  //   LightBlue   → SUB-TOTAL (all sub-region totals)
  //   Blue        → Main regions + sub-regions + OVERSEAS FILIPINOS + OTHERS AND UNSPECIFIED
  //   White       → Individual country/nationality rows + meta rows
  Color _bgForRow(String label, int rowIndex,
      {bool isPartII = false, required int firstDataRow}) {
    if (rowIndex < firstDataRow) return _cWhite;
    final u = label.trim().toUpperCase();

    // ── Yellow rows ───────────────────────────────────────────────────────
    if (u.contains('GRAND TOTAL')) return _cYellow;
    if (u.startsWith('A. DAE') || u.contains('VOLUME PER SEX')) return _cYellow;

    // ── Column header (repeating) ─────────────────────────────────────────
    if (u == 'COUNTRY OF RESIDENCE') return _cLightYellow;

    // ── Green: total aggregation rows ─────────────────────────────────────
    if (u == 'TOTAL PHILIPPINE RESIDENTS' ||
        u == 'TOTAL NON-PHILIPPINE RESIDENTS' ||
        u.startsWith('   TOTAL PHILIPPINE') ||
        u.startsWith('   TOTAL NON-PHILIPPINE') ||
        u.startsWith('   TOTAL OVERSEAS') ||
        u.startsWith('   TOTAL GUEST')) return _cGreen;

    // ── Light Blue: sub-region totals ─────────────────────────────────────
    if (u.contains('SUB-TOTAL')) return _cLightBlue;

    // ── Blue: main regions (bold, NOT italic) ─────────────────────────────
    if (u == 'PHILIPPINE RESIDENTS' ||
        u == 'NON-PHILIPPINE RESIDENTS' ||
        u == 'ASIA' ||
        u == 'AMERICA' ||
        u == 'EUROPE' ||
        u == 'AFRICA' ||
        u.startsWith('AUSTRALASIA')) return _cBlue;

    // ── Blue: sub-regions (bold + italic) ────────────────────────────────
    if (u.startsWith('ASEAN') ||
        u.startsWith('EAST ASIA') ||
        u.startsWith('SOUTH ASIA') ||
        u.startsWith('MIDDLE EAST') ||
        u.startsWith('NORTH AMERICA') ||
        u.startsWith('SOUTH AMERICA') ||
        u.startsWith('WESTERN EUROPE') ||
        u.startsWith('NORTHERN EUROPE') ||
        u.startsWith('SOUTHERN EUROPE') ||
        u.startsWith('EASTERN EUROPE')) return _cBlue;

    // ── Blue: special rows (bold + italic) ───────────────────────────────
    if (!isPartII && u.contains('OVERSEAS FILIPINOS')) return _cBlue;
    if (u.contains('OTHERS AND UNSPECIFIED')) return _cBlue;

    return _cWhite;
  }

  // ── Bold ──────────────────────────────────────────────────────────────────
  // Rules from Excel:
  //   • All colored rows → bold
  //   • Main section white rows → bold (country/nationality names are all bold)
  //   • PART II: only 'PART II.' header, 'Alternative Submission', '1. Male',
  //     '2. Female' are bold; DAE2 items and a/b/c/d sub-items are NOT bold
  bool _isBold(String label, int rowIndex,
      {bool isPartII = false, required int firstDataRow}) {
    if (rowIndex < firstDataRow) return false;
    final bg =
        _bgForRow(label, rowIndex, isPartII: isPartII, firstDataRow: firstDataRow);
    // All colored rows are bold
    if (bg != _cWhite) return true;

    if (isPartII) {
      final u = label.trim().toUpperCase();
      // Bold PART II rows (white background)
      if (u.startsWith('PART II') ||
          u == 'ALTERNATIVE SUBMISSION' ||
          u.startsWith('1. MALE') ||
          u.startsWith('2. FEMALE')) return true;
      // Everything else in PART II (DAE2 items, sub-items, x. Total,
      // footnotes, Prepared by) → NOT bold
      return false;
    }

    // Main data section (white bg): all non-empty rows are bold
    // (Filipino Nationality, Foreign Nationality, Brunei, etc. — all bold in Excel)
    return label.trim().isNotEmpty;
  }

  // ── Italic ────────────────────────────────────────────────────────────────
  // Rules from Excel (verified via openpyxl):
  //   • Sub-region blue headers → italic (ASEAN, EAST ASIA, SOUTH ASIA…)
  //   • OVERSEAS FILIPINOS* → italic (blue row, italic=True)
  //   • OTHERS AND UNSPECIFIED → italic (blue row, italic=True)
  //   • SUB-TOTAL rows → italic (light-blue, italic=True)
  //   • All country/nationality names (leading spaces, white bg) → italic
  //     Excludes: grand-total sub-rows like '   Total Philippine Residents'
  //   • PART II: only Alternative Submission → italic
  //   • Main regions (PHILIPPINE RESIDENTS, ASIA, etc.) → NOT italic
  //   • TOTAL rows (green) → NOT italic
  bool _isItalic(String label, int rowIndex,
      {bool isPartII = false, required int firstDataRow}) {
    if (rowIndex < firstDataRow) return false;
    final u = label.trim().toUpperCase();

    // Sub-region blue headers (bold + italic)
    if (u.startsWith('ASEAN') ||
        u.startsWith('EAST ASIA') ||
        u.startsWith('SOUTH ASIA') ||
        u.startsWith('MIDDLE EAST') ||
        u.startsWith('NORTH AMERICA') ||
        u.startsWith('SOUTH AMERICA') ||
        u.startsWith('WESTERN EUROPE') ||
        u.startsWith('NORTHERN EUROPE') ||
        u.startsWith('SOUTHERN EUROPE') ||
        u.startsWith('EASTERN EUROPE')) return true;

    // Special blue rows confirmed italic in Excel
    if (!isPartII && u.contains('OVERSEAS FILIPINOS')) return true;
    if (u.contains('OTHERS AND UNSPECIFIED')) return true;

    // SUB-TOTAL rows (light-blue, italic)
    if (u.contains('SUB-TOTAL')) return true;

    // Individual country/nationality rows in main section
    // These are indented with leading spaces; green grand-total sub-rows
    // also have leading spaces but start with "TOTAL" so we exclude them
    if (label.startsWith(' ') &&
        label.trim().isNotEmpty &&
        !isPartII &&
        !u.startsWith('TOTAL ') &&
        !u.startsWith('GRAND')) return true;

    // PART II: Alternative Submission only
    if (u == 'ALTERNATIVE SUBMISSION') return true;

    return false;
  }

  // ── Data font size ────────────────────────────────────────────────────────
  // Excel uses: 8pt for all main data rows; 12pt for PART II section headers;
  // 9pt for all PART II detail items (rooms, sex breakdown, footnotes)
  double _dataFontSize(String label, {bool isPartII = false}) {
    if (!isPartII) return 8.0;
    final u = label.trim().toUpperCase();
    if (u.startsWith('PART II') ||
        u.startsWith('A. DAE') ||
        u.startsWith('B. VOLUME') ||
        u == 'ALTERNATIVE SUBMISSION') return 12.0;
    return 9.0;
  }

  // ── Base (unscaled) column widths ─────────────────────────────────────────
  // Calibrated from ON Blank Form column dimensions:
  //   Col A  = 45.66 chars × 7px ≈ 320px  (label column)
  //   Day cols = 4.66 chars × 7px ≈ 33px  (columns B–AF)
  //   TOTAL col = 14.44 chars × 7px ≈ 101px (last column)
  static const double _colLabelW = 320.0;
  static const double _colDayW   = 33.0;
  static const double _colTotalW = 101.0;
  // Row height: Excel default 13.8pt → ~18px at 96 dpi
  static const double _rowH = 18.0;

  double _colWidth(int colIndex, int maxCols) {
    if (colIndex == 0) return _colLabelW;
    if (colIndex == maxCols - 1) return _colTotalW;
    if (maxCols == 14) return 52.0; // Monthly summary sheet (12 months + label + total)
    if (maxCols == 2) return _colTotalW; // Country-sum sheet (label + total only)
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

    // ── Dynamically detect first data row ────────────────────────────────
    // Walk rows until we find "COUNTRY OF RESIDENCE" or "PHILIPPINE RESIDENTS"
    // which always marks the start of the actual data table. Fall back to 10
    // if the sheet is in an unexpected format.
    int firstDataRow = 10;
    for (int i = 0; i < rows.length; i++) {
      final val =
          rows[i].isNotEmpty ? (rows[i][0]?.value?.toString() ?? '') : '';
      final u = val.trim().toUpperCase();
      if (u == 'COUNTRY OF RESIDENCE' || u == 'PHILIPPINE RESIDENTS') {
        firstDataRow = i;
        break;
      }
    }

    // ── Scaled total width ────────────────────────────────────────────────
    double totalW = 0;
    for (int c = 0; c < maxCols; c++) {
      totalW += _colWidth(c, maxCols) * _scale;
    }

    // ── PART II range detection ───────────────────────────────────────────
    int partIIStart = rows.length;
    int partIIEnd   = rows.length;
    for (int i = 0; i < rows.length; i++) {
      final first = rows[i].isNotEmpty
          ? (rows[i][0]?.value?.toString() ?? '').trim().toUpperCase()
          : '';
      if (first.startsWith('PART II')) {
        partIIStart = i;
        break;
      }
    }
    if (partIIStart < rows.length) {
      for (int i = partIIStart + 1; i < rows.length; i++) {
        final first = rows[i].isNotEmpty
            ? (rows[i][0]?.value?.toString() ?? '').trim().toUpperCase()
            : '';
        if (first.startsWith('PART ') && !first.startsWith('PART II')) {
          partIIEnd = i;
          break;
        }
      }
    }

    return Column(
      children: [
        _ZoomBar(
          scale: _scale,
          onZoomIn: _zoomIn,
          onZoomOut: _zoomOut,
          onZoomReset: _zoomReset,
        ),
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
                if (details.pointerCount >= 2) {
                  setState(() {
                    _scale = (_startScale * details.scale)
                        .clamp(_minScale, _maxScale);
                  });
                }
              },
              child: Scrollbar(
                controller: _vertScrollCtrl,
                scrollbarOrientation: ScrollbarOrientation.right,
                notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 11,
                radius: const Radius.circular(6),
                child: Scrollbar(
                  controller: _horizScrollCtrl,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 11,
                  radius: const Radius.circular(6),
                  child: SingleChildScrollView(
                    controller: _vertScrollCtrl,
                    child: SingleChildScrollView(
                      controller: _horizScrollCtrl,
                      scrollDirection: Axis.horizontal,
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
                                firstDataRow: firstDataRow,
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
      ],
    );
  }

  // ── Row builder ───────────────────────────────────────────────────────────
  Widget _buildRow(
    int rowIndex,
    List<Data?> cells,
    int maxCols,
    double totalW, {
    bool isPartII = false,
    required int firstDataRow,
  }) {
    final firstVal =
        cells.isNotEmpty ? (cells[0]?.value?.toString() ?? '') : '';

    // Meta header rows (before COUNTRY OF RESIDENCE) → faithful Excel styling
    if (rowIndex < firstDataRow) {
      return _MetaRow(
        rowIndex: rowIndex,
        value: firstVal,
        totalW: totalW,
        scale: _scale,
      );
    }

    // ── Compute row-level style ───────────────────────────────────────────
    final bg = _bgForRow(firstVal, rowIndex,
        isPartII: isPartII, firstDataRow: firstDataRow);
    final bold = _isBold(firstVal, rowIndex,
        isPartII: isPartII, firstDataRow: firstDataRow);
    final italic = _isItalic(firstVal, rowIndex,
        isPartII: isPartII, firstDataRow: firstDataRow);
    final fontSize = _dataFontSize(firstVal, isPartII: isPartII);

    // Repeating column-header row ("COUNTRY OF RESIDENCE" with day numbers)
    final isColHdrRow = firstVal.trim().toUpperCase() == 'COUNTRY OF RESIDENCE';

    final scaledRowH = _rowH * _scale;

    return SizedBox(
      height: scaledRowH,
      child: Row(
        children: List.generate(maxCols, (colIndex) {
          final cell   = colIndex < cells.length ? cells[colIndex] : null;
          final raw    = cell?.value?.toString() ?? '';
          final isFirst = colIndex == 0;
          final colW   = _colWidth(colIndex, maxCols) * _scale;

          // Day-number header cells use Bell MT bold+italic (matches Excel exactly)
          final isDayNumCol = isColHdrRow && !isFirst;

          return Container(
            width: colW,
            height: scaledRowH,
            decoration: BoxDecoration(
              color: bg,
              border: const Border(
                top:    BorderSide(color: _cGridBorder, width: 0.5),
                bottom: BorderSide(color: _cGridBorder, width: 0.5),
                left:   BorderSide(color: _cGridBorder, width: 0.5),
                right:  BorderSide(color: _cGridBorder, width: 0.5),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isFirst ? 4 * _scale : 1 * _scale,
              vertical:   1 * _scale,
            ),
            alignment: isFirst ? Alignment.centerLeft : Alignment.center,
            child: Text(
              raw,
              style: TextStyle(
                // Bell MT for day-number column headers, Arial for everything else
                fontFamily: isDayNumCol ? 'Bell MT' : 'Arial',
                fontSize:   (isDayNumCol ? 8.0 : fontSize) * _scale,
                fontWeight: (bold || isDayNumCol)
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: (italic || isDayNumCol)
                    ? FontStyle.italic
                    : FontStyle.normal,
                // ALL text black — matches ON Blank Form Excel exactly
                color: _cBlack,
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

// ─── Meta Header Rows ─────────────────────────────────────────────────────────
//
// Faithfully reproduces the ON Blank Form header section (rows 1–24 in Excel):
//
//   Row 1  : DAE-1B (Manual)        → Arial 10, left, not bold
//   Row 3  : Region: __4-A          → Arial 10, bold, centered
//   Row 4  : __________________     → Arial 10, bold, centered (date underline)
//   Row 5  : (Month, Year)          → Arial 10, italic, centered
//   Row 7  : REPORT ON THE...       → Arial 12, bold, centered  ← main title
//   Row 9  : Type of Accommodation  → Arial 10, bold, left
//   Row 10-15: Accommodation items  → Arial 10, normal, left (indented)
//   Row 17 : DOT Accreditation...   → Arial 10, bold, left
//   Row 19-20: AE ID Code...        → Arial 10, bold, left
//   Row 22-23: City/Province        → Arial 10, bold, left
//
// Style is detected from content rather than row index for robustness across
// different generated report file structures.

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.rowIndex,
    required this.value,
    required this.totalW,
    required this.scale,
  });

  final int    rowIndex;
  final String value;
  final double totalW;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final v = value.trim();

    // ── Style detection from content ──────────────────────────────────────

    // Row 7 in Excel: "REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS"
    // Arial 12, bold, centered
    final bool isMainTitle = v.toUpperCase().contains('REPORT ON THE REGIONAL');

    // Rows that are centered + bold: "Region: ..." and underline lines (all _)
    final bool isRegionLine = v.startsWith('Region:');
    final bool isUnderlineLine = v.isNotEmpty &&
        v.replaceAll('_', '').replaceAll(' ', '').isEmpty;

    // "(Month, Year)" — italic, centered
    final bool isMonthYear = v.startsWith('(Month') || v == '(Month, Year)';

    // Bold section-level field labels (left-aligned)
    final bool isSectionField = v.startsWith('Type of Accommodation') ||
        v.startsWith('DOT Accreditation') ||
        v.startsWith('AE ID Code') ||
        v.startsWith('City/Municipality') ||
        v.startsWith('Province:');

    // Derived styles
    final double fontSize = isMainTitle ? 12.0 : 10.0;
    final bool bold = isMainTitle ||
        isRegionLine ||
        isUnderlineLine ||
        isSectionField;
    final bool italic = isMonthYear;
    final TextAlign align =
        (isMainTitle || isRegionLine || isUnderlineLine || isMonthYear)
            ? TextAlign.center
            : TextAlign.left;

    return SizedBox(
      width: totalW,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6 * scale,
          vertical: isMainTitle ? 3 * scale : 1.5 * scale,
        ),
        child: Text(
          // Use raw `value` (not trimmed) to preserve indentation for
          // accommodation-type items like "                Hotel"
          value,
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize:   fontSize * scale,
            fontWeight: bold   ? FontWeight.bold   : FontWeight.normal,
            fontStyle:  italic ? FontStyle.italic  : FontStyle.normal,
            color: const Color(0xFF000000),
          ),
          textAlign: align,
        ),
      ),
    );
  }
}

// ─── Zoom Toolbar ─────────────────────────────────────────────────────────────

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
          _ZoomBtn(
              icon: Icons.remove_rounded,
              onTap: onZoomOut,
              tooltip: 'Zoom out'),
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
          _ZoomBtn(
              icon: Icons.add_rounded, onTap: onZoomIn, tooltip: 'Zoom in'),
          const SizedBox(width: 8),
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
              style:
                  const TextStyle(color: AppColors.textGray, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}