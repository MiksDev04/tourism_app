// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';
import '../../../api/business_dashboard_api.dart';
import '../../../core/services/session_service.dart';

// ─── Business Dashboard Page ──────────────────────────────────────────────────

class BusinessDashboardPage extends StatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  final _api = BusinessDashboardApi();

  // Business info loaded from SessionService
  String? _businessId;
  String _businessName = '';
  String _businessType = '';
  String _address = '';
  int _totalRooms = 0;

  // ── Filter state ─────────────────────────────────────────────────────────────

  int _selectedMonth = DateTime.now().month; // 0 = all year
  int _selectedYear = DateTime.now().year;

  int _trendYear1 = DateTime.now().year - 1;
  int _trendYear2 = DateTime.now().year;

  // ── Data state ────────────────────────────────────────────────────────────────

  DashboardData? _dashData;
  Map<int, List<MonthlyCount>> _trendData = {};
  bool _loadingDash = true;
  bool _loadingTrend = true;
  bool _exporting = false;
  String? _dashError;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initBusinessFromSession();
  }

  Future<void> _initBusinessFromSession() async {
    final session =
        SessionService.instance.current ??
        await SessionService.instance.loadAndCache();
    if (!mounted) return;
    setState(() {
      _businessId = session?.businessId;
      _businessName = session?.businessName ?? '';
      _businessType = session?.businessType ?? '';
    });

    if (_businessId != null) {
      try {
        final details = await _api.fetchBusinessDetails(_businessId!);
        if (!mounted) return;
        setState(() {
          _address = details.address;
          _totalRooms = details.totalRooms;
        });
      } catch (_) {
        // Keep defaults if the lookup fails.
      }
    }

    await _loadDashboard();
    await _loadTrend();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loadingDash = true;
      _dashError = null;
    });
    try {
      if (_businessId == null) throw Exception('Business account not found.');
      final data = await _api.fetchDashboardData(
        businessId: _businessId!,
        totalRooms: _totalRooms,
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) setState(() => _dashData = data);
    } catch (e) {
      if (mounted) setState(() => _dashError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDash = false);
    }
  }

  Future<void> _loadTrend() async {
    setState(() => _loadingTrend = true);
    try {
      if (_businessId == null) throw Exception('Business account not found.');
      final data = await _api.fetchYearlyComparison(
        businessId: _businessId!,
        years: [_trendYear1, _trendYear2],
      );
      if (mounted) setState(() => _trendData = data);
    } catch (_) {
      // trend is non-critical; silently fail
    } finally {
      if (mounted) setState(() => _loadingTrend = false);
    }
  }

  // ── Exports ───────────────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      if (_businessId == null) throw Exception('Business account not found.');
      final csv = await _api.generateCsv(
        businessId: _businessId!,
        businessName: _businessName,
        month: _selectedMonth,
        year: _selectedYear,
      );
      final dir = await getTemporaryDirectory();
      final label = _selectedMonth == 0
          ? '$_selectedYear'
          : '${_monthShort(_selectedMonth)}_$_selectedYear';
      final file = File('${dir.path}/guests_$label.csv')
        ..writeAsStringSync(csv);
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Guest Report – ${_businessName} ($label)');
    } catch (e) {
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final d = _dashData;
      if (d == null) return;

      final doc = pw.Document();
      final label = _selectedMonth == 0
          ? 'Full Year $_selectedYear'
          : '${_monthName(_selectedMonth)} $_selectedYear';

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _businessName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${_businessType} •  ${_address}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.Text(
                'Dashboard Report – $label',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Divider(),
            ],
          ),
          build: (_) => [
            // Stats
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Guests This Month/Period', '${d.stats.guestsThisMonth}'],
                ['Guests This Year', '${d.stats.guestsThisYear}'],
                [
                  'Avg. Length of Stay',
                  '${d.stats.avgLengthOfStay.toStringAsFixed(1)} nights',
                ],
                ['Total Rooms', '${d.stats.totalRooms}'],
              ],
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 16),

            // sex
            pw.Text(
              'Sex Distribution',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Sex', 'Count', 'Percentage'],
              data: [
                [
                  'Male',
                  '${d.sexDistribution.male}',
                  '${(d.sexDistribution.maleRatio * 100).toStringAsFixed(1)}%',
                ],
                [
                  'Female',
                  '${d.sexDistribution.female}',
                  '${(d.sexDistribution.femaleRatio * 100).toStringAsFixed(1)}%',
                ],
              ],
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 16),

            // Countries
            pw.Text(
              'Top Countries',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Country', 'Guests'],
              data: d.topCountries
                  .map((c) => [c.country, '${c.count}'])
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 16),

            // Regions
            pw.Text(
              'Top Local Regions (Philippine Visitors)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Region', 'Guests'],
              data: d.topRegions.map((r) => [r.region, '${r.count}']).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final label2 = _selectedMonth == 0
          ? '$_selectedYear'
          : '${_monthShort(_selectedMonth)}_$_selectedYear';
      final file = File('${dir.path}/dashboard_$label2.pdf');
      await file.writeAsBytes(await doc.save());
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Dashboard Report – ${_businessName} ($label)');
    } catch (e) {
      _showSnack('PDF export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Export Report',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _selectedMonth == 0
                    ? 'Full Year $_selectedYear'
                    : '${_monthName(_selectedMonth)} $_selectedYear',
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            _ExportTile(
              icon: Icons.table_chart_rounded,
              color: AppColors.accentGreen,
              title: 'Export as CSV',
              subtitle: 'Spreadsheet-ready guest data',
              onTap: () {
                Navigator.pop(sheetCtx);
                _exportCsv();
              },
            ),
            _ExportTile(
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.accentOrange,
              title: 'Export as PDF',
              subtitle: 'Formatted report document',
              onTap: () {
                Navigator.pop(sheetCtx);
                _exportPdf();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
  if (!mounted) return;   // ADD THIS
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.cardBackground,
    ),
  );
}

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Dashboard',
      selectedIndex: 0,
      onNavSelected: (_) {},
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 980;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNarrow) ...[
                      _HotelHeader(
                        name: _businessName,
                        type: _businessType,
                        rooms: _totalRooms,
                        address: _address,
                      ),
                      const SizedBox(height: 16),
                      _FilterRow(
                        selectedMonth: _selectedMonth,
                        selectedYear: _selectedYear,
                        onMonthChanged: (m) {
                          setState(() => _selectedMonth = m);
                          _loadDashboard();
                        },
                        onYearChanged: (y) {
                          setState(() => _selectedYear = y);
                          _loadDashboard();
                        },
                        onExport: _exporting ? null : _showExportMenu,
                        isExporting: _exporting,
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _HotelHeader(
                              name: _businessName,
                              type: _businessType,
                              rooms: _totalRooms,
                              address: _address,
                            ),
                          ),
                          const SizedBox(width: 16),
                          _FilterRow(
                            selectedMonth: _selectedMonth,
                            selectedYear: _selectedYear,
                            onMonthChanged: (m) {
                              setState(() => _selectedMonth = m);
                              _loadDashboard();
                            },
                            onYearChanged: (y) {
                              setState(() => _selectedYear = y);
                              _loadDashboard();
                            },
                            onExport: _exporting ? null : _showExportMenu,
                            isExporting: _exporting,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_loadingDash)
                      const _LoadingSection(height: 100)
                    else if (_dashError != null)
                      _ErrorSection(message: _dashError!)
                    else ...[
                      _StatCards(
                        stats: _dashData!.stats,
                        selectedMonth: _selectedMonth,
                      ),
                      const SizedBox(height: 20),
                      _DonutChartsRow(
                        sexDist: _dashData!.sexDistribution,
                        topCountries: _dashData!.topCountries,
                        topRegions: _dashData!.topRegions,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _TouristTrendCard(
                      trendData: _trendData,
                      year1: _trendYear1,
                      year2: _trendYear2,
                      isLoading: _loadingTrend,
                      onYear1Changed: (y) {
                        setState(() => _trendYear1 = y);
                        _loadTrend();
                      },
                      onYear2Changed: (y) {
                        setState(() => _trendYear2 = y);
                        _loadTrend();
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
          if (_exporting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryCyan),
              ),
            ),
        ],
      ),
    );
  }

  // ── Label helpers ─────────────────────────────────────────────────────────────

  static String _monthName(int m) => const [
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
  ][m];

  static String _monthShort(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

// ─── Hotel Header ─────────────────────────────────────────────────────────────

class _HotelHeader extends StatelessWidget {
  const _HotelHeader({
    required this.name,
    required this.type,
    required this.rooms,
    required this.address,
  });

  final String name;
  final String type;
  final int rooms;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_capitalize(type)}  •  $rooms Rooms  •  $address',
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onExport,
    required this.isExporting,
  });

  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final VoidCallback? onExport;
  final bool isExporting;

  static const _months = [
    (0, 'All Months'),
    (1, 'January'),
    (2, 'February'),
    (3, 'March'),
    (4, 'April'),
    (5, 'May'),
    (6, 'June'),
    (7, 'July'),
    (8, 'August'),
    (9, 'September'),
    (10, 'October'),
    (11, 'November'),
    (12, 'December'),
  ];

  List<int> get _years {
    final now = DateTime.now().year;
    return List.generate(5, (i) => now - i);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 170,
          child: _FilterDropdown<int>(
            value: selectedMonth,
            items: _months.map((m) => (m.$1, m.$2)).toList(),
            onChanged: onMonthChanged,
            icon: Icons.calendar_month_rounded,
          ),
        ),
        SizedBox(
          width: 110,
          child: _FilterDropdown<int>(
            value: selectedYear,
            items: _years.map((y) => (y, '$y')).toList(),
            onChanged: onYearChanged,
            icon: Icons.event_rounded,
          ),
        ),
        _ExportButton(onTap: onExport, isLoading: isExporting),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primaryCyan),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.cardBackground,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textGray,
                  size: 18,
                ),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                ),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                items: items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item.$1,
                        child: Text(item.$2, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onTap, required this.isLoading});

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.upload_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            const Text(
              'Export',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Cards ───────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  const _StatCards({required this.stats, required this.selectedMonth});

  final DashboardStats stats;
  final int selectedMonth;

  String get _monthLabel => selectedMonth == 0 ? 'This Year' : 'This Month';

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.people_alt_rounded,
        iconColor: AppColors.primaryCyan,
        value: '${stats.guestsThisMonth}',
        label: 'Guests $_monthLabel',
      ),
      _StatCard(
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.primaryBlue,
        value: '${stats.guestsThisYear}',
        label: 'Guests This Year',
      ),
      _StatCard(
        icon: Icons.schedule_rounded,
        iconColor: AppColors.accentGreen,
        value: '${stats.avgLengthOfStay.toStringAsFixed(1)} nights',
        label: 'Avg. Length of Stay',
      ),
      _StatCard(
        icon: Icons.bed_rounded,
        iconColor: AppColors.accentOrange,
        value: '${stats.totalRooms}',
        label: 'Total Rooms',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards
              .expand(
                (c) => [
                  Expanded(child: c),
                  if (c != cards.last) const SizedBox(width: 14),
                ],
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textGray, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Donut Charts Row ─────────────────────────────────────────────────────────

class _DonutChartsRow extends StatelessWidget {
  const _DonutChartsRow({
    required this.sexDist,
    required this.topCountries,
    required this.topRegions,
  });

  final SexDistribution sexDist;
  final List<CountryCount> topCountries;
  final List<RegionCount> topRegions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sexCard = _sexDonut(dist: sexDist);
        final countriesCard = _CountriesDonut(countries: topCountries);
        final regionsCard = _RegionsDonut(regions: topRegions);

        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              sexCard,
              const SizedBox(height: 14),
              countriesCard,
              const SizedBox(height: 14),
              regionsCard,
            ],
          );
        } else if (constraints.maxWidth < 900) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: sexCard),
                  const SizedBox(width: 14),
                  Expanded(child: countriesCard),
                ],
              ),
              const SizedBox(height: 14),
              regionsCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sexCard),
            const SizedBox(width: 14),
            Expanded(child: countriesCard),
            const SizedBox(width: 14),
            Expanded(child: regionsCard),
          ],
        );
      },
    );
  }
}

// ─── sex Donut ─────────────────────────────────────────────────────────────

class _sexDonut extends StatelessWidget {
  const _sexDonut({required this.dist});

  final SexDistribution dist;

  @override
  Widget build(BuildContext context) {
    final total = dist.total;
    final maleP = total == 0 ? 0 : ((dist.maleRatio * 100).round());
    final femaleP = total == 0 ? 0 : ((dist.femaleRatio * 100).round());
    final otherP = total == 0 ? 0 : (100 - maleP - femaleP);

    final segments = [
      _Segment(
        value: total == 0 ? 0.34 : dist.maleRatio,
        color: AppColors.chartCyan,
        label: 'Male',
        percentage: '$maleP%',
        count: dist.male, // ADD
        isEmpty: total == 0,
      ),
      _Segment(
        value: total == 0 ? 0.33 : dist.femaleRatio,
        color: AppColors.chartPurple,
        label: 'Female',
        percentage: '$femaleP%',
        count: dist.female, // ADD
        isEmpty: total == 0,
      ),
    ];

    return _DonutCard(
      title: 'Sex Distribution',
      emptyHint: total == 0 ? 'No data for this period' : null,
      segments: segments,
      legend: const [
        _LegendItem(label: 'Male', color: AppColors.chartCyan),
        _LegendItem(label: 'Female', color: AppColors.chartPurple),
      ],
    );
  }
}

// ─── Countries Donut ──────────────────────────────────────────────────────────

class _CountriesDonut extends StatelessWidget {
  const _CountriesDonut({required this.countries});

  final List<CountryCount> countries;

  static const _colors = [
    AppColors.chartGreen,
    AppColors.chartBlue,
    AppColors.chartOrange,
    AppColors.chartPurple,
    AppColors.chartGray,
  ];

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return _DonutCard(
        title: 'Top 5 Countries',
        emptyHint: 'No data for this period',
        segments: const [
          _Segment(value: 0.2, color: AppColors.chartGreen, isEmpty: true),
          _Segment(value: 0.2, color: AppColors.chartBlue, isEmpty: true),
          _Segment(value: 0.2, color: AppColors.chartOrange, isEmpty: true),
          _Segment(value: 0.2, color: AppColors.chartPurple, isEmpty: true),
          _Segment(value: 0.2, color: AppColors.chartGray, isEmpty: true),
        ],
        legend: const [],
      );
    }

    final total = countries.fold<int>(0, (s, c) => s + c.count);
    final segments = countries.asMap().entries.map((e) {
      final ratio = total == 0 ? 1 / countries.length : e.value.count / total;
      final pct = (ratio * 100).round();
      return _Segment(
        value: ratio,
        color: _colors[e.key % _colors.length],
        label: e.value.country,
        percentage: '$pct%',
        count: e.value.count, // ADD
      );
    }).toList();

    final legendItems = countries
        .asMap()
        .entries
        .map(
          (e) => _LegendItem(
            label: e.value.country,
            color: _colors[e.key % _colors.length],
          ),
        )
        .toList();

    return _DonutCard(
      title: 'Top 5 Countries',
      segments: segments,
      legend: legendItems,
    );
  }
}

// ─── Regions Donut ────────────────────────────────────────────────────────────

class _RegionsDonut extends StatelessWidget {
  const _RegionsDonut({required this.regions});

  final List<RegionCount> regions;

  static const _colors = [
    AppColors.chartCyan,
    AppColors.chartGreen,
    AppColors.chartOrange,
    AppColors.chartPurple,
    AppColors.chartGray,
  ];

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) {
      return _DonutCard(
        title: 'Top Local Regions',
        emptyHint: 'No Philippine visitors this period',
        segments: List.generate(
          5,
          (i) => _Segment(value: 0.2, color: _colors[i], isEmpty: true),
        ),
        legend: const [],
      );
    }

    final total = regions.fold<int>(0, (s, r) => s + r.count);
    final segments = regions.asMap().entries.map((e) {
      final ratio = total == 0 ? 1 / regions.length : e.value.count / total;
      final pct = (ratio * 100).round();
      return _Segment(
        value: ratio,
        color: _colors[e.key % _colors.length],
        label: e.value.region,
        percentage: '$pct%',
        count: e.value.count, 
      );
    }).toList();

    final legendItems = regions
        .asMap()
        .entries
        .map(
          (e) => _LegendItem(
            label: e.value.region,
            color: _colors[e.key % _colors.length],
          ),
        )
        .toList();

    return _DonutCard(
      title: 'Top Local Regions',
      segments: segments,
      legend: legendItems,
    );
  }
}

// ─── Shared Donut Card ────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  const _DonutCard({
    required this.title,
    required this.segments,
    required this.legend,
    this.emptyHint,
  });

  final String title;
  final List<_Segment> segments;
  final List<_LegendItem> legend;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    final chartSize = isSmall ? 120.0 : 140.0;

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title: title),
          if (emptyHint != null) ...[
            const SizedBox(height: 6),
            Text(
              emptyHint!,
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: _DonutChart(segments: segments, size: chartSize),
          ),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Legend(items: legend),
          ],
        ],
      ),
    );
  }
}

// ─── Tourist Trend Card ───────────────────────────────────────────────────────

class _TouristTrendCard extends StatelessWidget {
  const _TouristTrendCard({
    required this.trendData,
    required this.year1,
    required this.year2,
    required this.isLoading,
    required this.onYear1Changed,
    required this.onYear2Changed,
  });

  final Map<int, List<MonthlyCount>> trendData;
  final int year1;
  final int year2;
  final bool isLoading;
  final ValueChanged<int> onYear1Changed;
  final ValueChanged<int> onYear2Changed;

  List<int> get _availableYears {
    final now = DateTime.now().year;
    return List.generate(8, (i) => now - i);
  }

  @override
  Widget build(BuildContext context) {
    final chartHeight = MediaQuery.of(context).size.width < 500 ? 180.0 : 220.0;
    final y1Data =
        trendData[year1] ??
        List.generate(12, (i) => MonthlyCount(month: i + 1, count: 0));
    final y2Data =
        trendData[year2] ??
        List.generate(12, (i) => MonthlyCount(month: i + 1, count: 0));

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Expanded(child: _CardTitle(title: 'Tourist Trend')),
              // Year pickers
              _YearPill(
                year: year1,
                color: AppColors.chartPurple,
                years: _availableYears,
                onChanged: onYear1Changed,
              ),
              const SizedBox(width: 8),
              _YearPill(
                year: year2,
                color: AppColors.chartCyan,
                years: _availableYears,
                onChanged: onYear2Changed,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Monthly guest arrivals — year-over-year comparison',
            style: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            SizedBox(
              height: chartHeight,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryCyan),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              child: _ComparisonBarChart(
                year1: year1,
                year2: year2,
                year1Data: y1Data,
                year2Data: y2Data,
              ),
            ),
        ],
      ),
    );
  }
}

class _YearPill extends StatelessWidget {
  const _YearPill({
    required this.year,
    required this.color,
    required this.years,
    required this.onChanged,
  });

  final int year;
  final Color color;
  final List<int> years;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: year,
          dropdownColor: AppColors.cardBackground,
          icon: Icon(Icons.arrow_drop_down_rounded, color: color, size: 18),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: years
              .map((y) => DropdownMenuItem<int>(value: y, child: Text('$y')))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Comparison Bar Chart ─────────────────────────────────────────────────────

class _ComparisonBarChart extends StatefulWidget {
  const _ComparisonBarChart({
    required this.year1,
    required this.year2,
    required this.year1Data,
    required this.year2Data,
  });

  final int year1;
  final int year2;
  final List<MonthlyCount> year1Data;
  final List<MonthlyCount> year2Data;

  @override
  State<_ComparisonBarChart> createState() => _ComparisonBarChartState();
}

class _ComparisonBarChartState extends State<_ComparisonBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _hoveredBar = -1; // encodes month*2 + yearIndex
  bool _hoveredIsYear2 = false;
  int _hoveredMonth = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(_ComparisonBarChart old) {
    super.didUpdateWidget(old);
    if (old.year1 != widget.year1 || old.year2 != widget.year2) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              _detectHover(
                box.globalToLocal(event.position),
                constraints.biggest,
              );
            }
          },
          onExit: (_) => setState(() {
            _hoveredMonth = -1;
          }),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _ComparisonBarPainter(
                year1: widget.year1,
                year2: widget.year2,
                year1Data: widget.year1Data,
                year2Data: widget.year2Data,
                animValue: _ctrl.value,
                hoveredMonth: _hoveredMonth,
                hoveredIsYear2: _hoveredIsYear2,
              ),
              size: constraints.biggest,
            ),
          ),
        );
      },
    );
  }

  void _detectHover(Offset pos, Size size) {
    const leftPad = 42.0;
    const bottomPad = 36.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    if (pos.dy < 0 || pos.dy > chartH) {
      if (_hoveredMonth != -1) setState(() => _hoveredMonth = -1);
      return;
    }

    final groupW = chartW / 12;
    final barW = groupW * 0.30;
    const gap = 2.0;

    final allVals = [
      ...widget.year1Data.map((d) => d.count),
      ...widget.year2Data.map((d) => d.count),
    ];
    final maxVal = allVals.isEmpty ? 1 : allVals.reduce(math.max);
    final effectiveMax = (maxVal * 1.2).ceilToDouble();

    for (int i = 0; i < 12; i++) {
      final groupX = leftPad + i * groupW + groupW / 2 - barW - gap / 2;

      // Year1 bar
      final x1 = groupX;
      final h1 =
          (widget.year1Data[i].count / effectiveMax) * chartH * _ctrl.value;
      if (pos.dx >= x1 && pos.dx <= x1 + barW && pos.dy >= chartH - h1) {
        if (_hoveredMonth != i || _hoveredIsYear2) {
          setState(() {
            _hoveredMonth = i;
            _hoveredIsYear2 = false;
          });
        }
        return;
      }

      // Year2 bar
      final x2 = groupX + barW + gap;
      final h2 =
          (widget.year2Data[i].count / effectiveMax) * chartH * _ctrl.value;
      if (pos.dx >= x2 && pos.dx <= x2 + barW && pos.dy >= chartH - h2) {
        if (_hoveredMonth != i || !_hoveredIsYear2) {
          setState(() {
            _hoveredMonth = i;
            _hoveredIsYear2 = true;
          });
        }
        return;
      }
    }

    if (_hoveredMonth != -1) setState(() => _hoveredMonth = -1);
  }
}

class _ComparisonBarPainter extends CustomPainter {
  const _ComparisonBarPainter({
    required this.year1,
    required this.year2,
    required this.year1Data,
    required this.year2Data,
    required this.animValue,
    required this.hoveredMonth,
    required this.hoveredIsYear2,
  });

  final int year1;
  final int year2;
  final List<MonthlyCount> year1Data;
  final List<MonthlyCount> year2Data;
  final double animValue;
  final int hoveredMonth;
  final bool hoveredIsYear2;

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _color1 = AppColors.chartPurple;
  static const _color2 = AppColors.chartCyan;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 42.0;
    const bottomPad = 36.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    final allVals = [
      ...year1Data.map((d) => d.count),
      ...year2Data.map((d) => d.count),
    ];
    final maxVal = allVals.isEmpty ? 0 : allVals.reduce(math.max);
    final effectiveMax = maxVal == 0 ? 10.0 : (maxVal * 1.25).ceilToDouble();

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 0.5;
    final labelStyle = TextStyle(
      color: AppColors.textSubtle,
      fontSize: size.width < 400 ? 8.5 : 10,
    );

    final ySteps = 5;
    for (int i = 0; i <= ySteps; i++) {
      final val = (effectiveMax * i / ySteps).round();
      final y = chartH - (val / effectiveMax) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _drawText(canvas, '$val', Offset(0, y - 6), labelStyle, leftPad - 4);
    }

    final groupW = chartW / 12;
    const gap = 2.0;
    final barW = groupW * 0.30;

    for (int i = 0; i < 12; i++) {
      final groupX = leftPad + i * groupW + groupW / 2 - barW - gap / 2;

      // ── Year 1 bar ───────────────────────────────────────────────────────────
      final v1 = year1Data[i].count;
      final h1 = (v1 / effectiveMax) * chartH * animValue;
      final isHov1 = hoveredMonth == i && !hoveredIsYear2;

      if (h1 > 0) {
        final rect1 = Rect.fromLTWH(groupX, chartH - h1, barW, h1);
        final paint1 = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isHov1 ? _color1 : _color1.withOpacity(0.9),
              _color1.withOpacity(isHov1 ? 0.8 : 0.4),
            ],
          ).createShader(rect1);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect1,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          paint1,
        );
      }

      // ── Year 2 bar ───────────────────────────────────────────────────────────
      final v2 = year2Data[i].count;
      final h2 = (v2 / effectiveMax) * chartH * animValue;
      final isHov2 = hoveredMonth == i && hoveredIsYear2;
      final x2 = groupX + barW + gap;

      if (h2 > 0) {
        final rect2 = Rect.fromLTWH(x2, chartH - h2, barW, h2);
        final paint2 = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isHov2 ? _color2 : _color2.withOpacity(0.9),
              _color2.withOpacity(isHov2 ? 0.8 : 0.4),
            ],
          ).createShader(rect2);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect2,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          paint2,
        );
      }

      // ── Tooltip ──────────────────────────────────────────────────────────────
      if (hoveredMonth == i) {
        final isY2 = hoveredIsYear2;
        final hov = isY2 ? h2 : h1;
        final hovVal = isY2 ? v2 : v1;
        final hovYear = isY2 ? year2 : year1;
        final hovX = isY2 ? x2 : groupX;
        final hovColor = isY2 ? _color2 : _color1;
        _drawTooltip(
          canvas,
          '$hovYear: $hovVal guests',
          hovColor,
          Offset(hovX + barW / 2, chartH - hov - 8),
          size.width,
        );
      }

      // ── Month label ──────────────────────────────────────────────────────────
      final labelX = leftPad + i * groupW + groupW / 2 - 10;
      _drawText(
        canvas,
        _monthLabels[i],
        Offset(labelX, chartH + 8),
        labelStyle,
        groupW,
      );
    }

    // ── Legend ───────────────────────────────────────────────────────────────────
    _drawLegend(canvas, size, chartH + 22);
  }

  void _drawLegend(Canvas canvas, Size size, double y) {
    const dotR = 5.0;
    const spacing = 12.0;

    final style = TextStyle(
      color: AppColors.textGray,
      fontSize: size.width < 400 ? 9 : 11,
    );

    // Year 1 dot + label
    final p1 = Paint()..color = _color1;
    canvas.drawCircle(Offset(size.width / 2 - 60, y + dotR), dotR, p1);
    _drawText(
      canvas,
      '$year1',
      Offset(size.width / 2 - 60 + dotR * 2 + 2, y),
      style,
      60,
    );

    // Year 2 dot + label
    final p2 = Paint()..color = _color2;
    canvas.drawCircle(
      Offset(size.width / 2 + spacing + 20, y + dotR),
      dotR,
      p2,
    );
    _drawText(
      canvas,
      '$year2',
      Offset(size.width / 2 + spacing + 20 + dotR * 2 + 2, y),
      style,
      60,
    );
  }

  void _drawTooltip(
    Canvas canvas,
    String text,
    Color color,
    Offset anchor,
    double maxWidth,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tw = tp.width + 14;
    final th = tp.height + 8;
    var tx = anchor.dx - tw / 2;
    final ty = anchor.dy - th - 4;

    tx = tx.clamp(0, maxWidth - tw);

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tx, ty, tw, th),
      const Radius.circular(5),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(tx + 7, ty + 4));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
    double maxW,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ComparisonBarPainter old) =>
      old.animValue != animValue ||
      old.hoveredMonth != hoveredMonth ||
      old.hoveredIsYear2 != hoveredIsYear2 ||
      old.year1 != year1 ||
      old.year2 != year2;
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  const _DashCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 500;
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 500;
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textWhite,
        fontSize: isSmall ? 12 : 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _LegendItem {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 500;
    return Wrap(
      spacing: isSmall ? 8 : 12,
      runSpacing: 6,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: isSmall ? 10 : 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Donut Chart ──────────────────────────────────────────────────────────────

class _Segment {
  const _Segment({
    required this.value,
    required this.color,
    this.label,
    this.percentage,
    this.count, // ADD THIS
    this.isEmpty = false,
  });

  final double value;
  final Color color;
  final String? label;
  final String? percentage;
  final int? count; // ADD THIS
  final bool isEmpty;
}

class _DonutChart extends StatefulWidget {
  const _DonutChart({required this.segments, required this.size});

  final List<_Segment> segments;
  final double size;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _hoveredIdx = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(_DonutChart old) {
    super.didUpdateWidget(old);
    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _checkHover(Offset pos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final strokeW = size.width * 0.17;
    final inner = size.width / 2 - strokeW;
    final outer = size.width / 2;

    if (dist < inner || dist > outer) {
      if (_hoveredIdx != -1) setState(() => _hoveredIdx = -1);
      return;
    }

    final angle = math.atan2(dy, dx);
    final startAngle = (angle + math.pi / 2 + math.pi * 2) % (math.pi * 2);

    double acc = 0;
    for (int i = 0; i < widget.segments.length; i++) {
      final seg = widget.segments[i].value * math.pi * 2;
      if (startAngle >= acc && startAngle <= acc + seg) {
        if (_hoveredIdx != i) setState(() => _hoveredIdx = i);
        return;
      }
      acc += seg;
    }

    if (_hoveredIdx != -1) setState(() => _hoveredIdx = -1);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          _checkHover(
            box.globalToLocal(e.position),
            Size(widget.size, widget.size),
          );
        }
      },
      onExit: (_) => setState(() => _hoveredIdx = -1),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _ctrl.value,
          child: Transform.scale(
            scale: 0.95 + _ctrl.value * 0.05,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: _DonutPainter(
                      segments: widget.segments,
                      animValue: _ctrl.value,
                      hoveredIdx: _hoveredIdx,
                    ),
                    size: Size(widget.size, widget.size),
                  ),
                  if (_hoveredIdx != -1 &&
                      widget.segments[_hoveredIdx].label != null &&
                      !widget.segments[_hoveredIdx].isEmpty)
                    _DonutTooltip(segment: widget.segments[_hoveredIdx]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutTooltip extends StatelessWidget {
  const _DonutTooltip({required this.segment});

  final _Segment segment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            segment.label!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            segment.count != null
                ? '${segment.count} guests'
                : segment.percentage!,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.animValue,
    required this.hoveredIdx,
  });

  final List<_Segment> segments;
  final double animValue;
  final int hoveredIdx;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeW = size.width * 0.17;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeW / 2);

    double startAngle = -math.pi / 2;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweep = seg.value * 2 * math.pi * animValue;
      final isHov = hoveredIdx == i;
      final currentStroke = isHov ? strokeW + 5 : strokeW;
      final color = seg.isEmpty
          ? seg.color.withOpacity(0.15)
          : (isHov ? seg.color : seg.color.withOpacity(0.85));
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.animValue != animValue || old.hoveredIdx != hoveredIdx;
}

// ─── Export Tile ──────────────────────────────────────────────────────────────

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textGray, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

// ─── Loading / Error States ───────────────────────────────────────────────────

class _LoadingSection extends StatelessWidget {
  const _LoadingSection({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load data: $message',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
