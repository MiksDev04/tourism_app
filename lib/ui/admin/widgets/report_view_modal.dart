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

    // ── Responsive breakpoint ─────────────────────────────────────────────
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      // On mobile: full-screen (offset by status bar only).
      // On desktop: 20px inset on all sides.
      insetPadding: isMobile
          ? EdgeInsets.only(top: topPadding)
          : const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? size.width : size.width * 0.95,
        height: isMobile
            ? size.height - topPadding
            : size.height * 0.92,
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
// Desktop: single-row (icon | info | buttons | close).
// Mobile:  two-row  (icon + info + close) / (PDF btn | Excel btn).

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

  // ── Shared sub-widgets ────────────────────────────────────────────────────

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

    // ── Mobile layout ─────────────────────────────────────────────────────
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: icon | info | close
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
            // Row 2: PDF and Excel buttons, each fills half
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

    // ── Desktop layout ────────────────────────────────────────────────────
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
    // When true (mobile), the button fills its parent width and centers content.
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

// ── Sheet Tab Bar (responsive) ────────────────────────────────────────────────
// Desktop → TabBar; Mobile → styled DropdownButton.

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

// ── Desktop tab bar (unchanged from original) ─────────────────────────────────

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

// ── Mobile sheet dropdown ─────────────────────────────────────────────────────

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
          // Custom display for the currently selected item
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
          // Dropdown menu items
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
// SCROLLING:
//   • Vertical Scrollbar is outermost → renders at the absolute right edge
//     of the modal content area.
//   • Horizontal Scrollbar is inner   → renders at the bottom.
//
// ZOOM:
//   • All dimensions (row height, column widths, font sizes, padding) are
//     multiplied by _scale directly — no Transform.scale wrapper.
//   • This means the SingleChildScrollViews report the correct (scaled) extents,
//     so both scrollbars appear and resize properly as the user zooms.
//
// GESTURE:
//   • Pinch-to-zoom is handled by GestureDetector (touch only).
//   • Scroll wheel / trackpad pan normally (no accidental zoom).

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

  // ── Zoom actions ──────────────────────────────────────────────────────────
  void _zoomIn() =>
      setState(() => _scale = (_scale + _scaleStep).clamp(_minScale, _maxScale));
  void _zoomOut() =>
      setState(() => _scale = (_scale - _scaleStep).clamp(_minScale, _maxScale));
  void _zoomReset() => setState(() => _scale = 1.0);

  // ── Excel exact colours ───────────────────────────────────────────────────
  static const Color _cBlue = Color(0xFF0070C0);
  static const Color _cGreen = Color(0xFF92D050);
  static const Color _cLightBlue = Color(0xFF00B0F0);
  static const Color _cYellow = Color(0xFFFFFF00);
  static const Color _cLightYellow = Color(0xFFFFFF66);
  static const Color _cWhite = Color(0xFFFFFFFF);
  static const Color _cGridBorder = Color(0xFFBFBFBF);

  static Color _textOn(Color bg) =>
      bg == _cBlue ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  Color _bgForRow(String label, int rowIndex, {bool isPartII = false}) {
    if (rowIndex < 10) return _cWhite;
    final u = label.trim().toUpperCase();

    if (u == 'COUNTRY OF RESIDENCE') return _cLightYellow;
    if (u.contains('GRAND TOTAL')) return _cYellow;
    if (u == 'A. DAE2:' || u.contains('VOLUME PER SEX')) return _cYellow;

    if (u == 'TOTAL PHILIPPINE RESIDENTS' ||
        u == 'TOTAL NON-PHILIPPINE RESIDENTS' ||
        u == 'TOTAL OVERSEAS FILIPINOS' ||
        u.startsWith('   TOTAL PHILIPPINE') ||
        u.startsWith('   TOTAL NON-PHILIPPINE') ||
        u.startsWith('   TOTAL OVERSEAS') ||
        u.startsWith('   TOTAL GUEST')) return _cGreen;

    if (u.contains('SUB-TOTAL')) return _cLightBlue;

    if (u == 'PHILIPPINE RESIDENTS' ||
        u == 'NON-PHILIPPINE RESIDENTS' ||
        u == 'ASIA' ||
        u == 'AMERICA' ||
        u == 'EUROPE' ||
        u == 'AFRICA' ||
        u.startsWith('AUSTRALASIA') ||
        u.trimLeft().startsWith('ASEAN') ||
        u.trimLeft().startsWith('EAST ASIA') ||
        u.trimLeft().startsWith('SOUTH ASIA') ||
        u.trimLeft().startsWith('MIDDLE EAST') ||
        u.trimLeft().startsWith('NORTH AMERICA') ||
        u.trimLeft().startsWith('SOUTH AMERICA') ||
        u.trimLeft().startsWith('WESTERN EUROPE') ||
        u.trimLeft().startsWith('NORTHERN EUROPE') ||
        u.trimLeft().startsWith('SOUTHERN EUROPE') ||
        u.trimLeft().startsWith('EASTERN EUROPE') ||
        u.trimLeft().startsWith('AUSTRALASIA') ||
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

  // ── Base (unscaled) column widths ─────────────────────────────────────────
  static const double _colLabelW = 320.0;
  static const double _colDayW = 33.0;
  static const double _colTotalW = 101.0;
  static const double _rowH = 18.0;

  double _colWidth(int colIndex, int maxCols) {
    if (colIndex == 0) return _colLabelW;
    if (colIndex == maxCols - 1) return _colTotalW;
    if (maxCols == 14) return 52.0;
    if (maxCols == 2) return _colTotalW;
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

    // ── Scaled total width ────────────────────────────────────────────────
    // Multiplying each column by _scale so SingleChildScrollView reports the
    // correct (zoomed) extent → horizontal scrollbar appears when needed.
    double totalW = 0;
    for (int c = 0; c < maxCols; c++) {
      totalW += _colWidth(c, maxCols) * _scale;
    }

    // ── PART II range detection (unchanged logic) ─────────────────────────
    int partIIStart = rows.length;
    int partIIEnd = rows.length;
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
        // ── Zoom toolbar ────────────────────────────────────────────────
        _ZoomBar(
          scale: _scale,
          onZoomIn: _zoomIn,
          onZoomOut: _zoomOut,
          onZoomReset: _zoomReset,
        ),

        // ── Scrollable sheet ────────────────────────────────────────────
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
              // ── Vertical scrollbar OUTERMOST → always at modal right edge ──
              child: Scrollbar(
                controller: _vertScrollCtrl,
                scrollbarOrientation: ScrollbarOrientation.right,
                notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 11,
                radius: const Radius.circular(6),
                // ── Horizontal scrollbar inside, renders at bottom ──────────
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
                          // totalW is already scaled — the scroll view will
                          // report the correct extent and show the scrollbar.
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
      ],
    );
  }

  // ── Row builder ───────────────────────────────────────────────────────────
  // All dimensions are multiplied by _scale so layout size (and scroll extent)
  // matches the visual zoom level — no Transform.scale wrapper needed.

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
      return _MetaRow(
        rowIndex: rowIndex,
        value: firstVal,
        totalW: totalW,
        scale: _scale,
      );
    }

    final bg = _bgForRow(firstVal, rowIndex, isPartII: isPartII);
    final bold = _isBold(firstVal, rowIndex, isPartII: isPartII);
    final tc = _textOn(bg);
    final isColHdrRow =
        firstVal.trim().toUpperCase() == 'COUNTRY OF RESIDENCE';

    final scaledRowH = _rowH * _scale;

    return SizedBox(
      height: scaledRowH,
      child: Row(
        children: List.generate(maxCols, (colIndex) {
          final cell = colIndex < cells.length ? cells[colIndex] : null;
          final raw = cell?.value?.toString() ?? '';
          final isFirst = colIndex == 0;
          final colW = _colWidth(colIndex, maxCols) * _scale;

          return Container(
            width: colW,
            height: scaledRowH,
            decoration: BoxDecoration(
              color: bg,
              border: const Border(
                top: BorderSide(color: _cGridBorder, width: 0.5),
                bottom: BorderSide(color: _cGridBorder, width: 0.5),
                left: BorderSide(color: _cGridBorder, width: 0.5),
                right: BorderSide(color: _cGridBorder, width: 0.5),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isFirst ? 4 * _scale : 1 * _scale,
              vertical: 1 * _scale,
            ),
            alignment: isFirst ? Alignment.centerLeft : Alignment.center,
            child: Text(
              raw,
              style: TextStyle(
                fontFamily:
                    (isColHdrRow && !isFirst) ? 'Bell MT' : 'Calibri',
                fontSize: 8.5 * _scale,
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
    required this.scale,
  });

  final int rowIndex;
  final String value;
  final double totalW;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isBigTitle = rowIndex == 4;
    final isCentered = rowIndex >= 1 && rowIndex <= 4;

    return SizedBox(
      width: totalW,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6 * scale,
          vertical: isBigTitle ? 3 * scale : 1.5 * scale,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: isBigTitle ? 11.0 * scale : 9.0 * scale,
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
          _ZoomBtn(
              icon: Icons.remove_rounded, onTap: onZoomOut, tooltip: 'Zoom out'),
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
