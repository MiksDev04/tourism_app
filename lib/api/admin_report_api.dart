// ignore_for_file: deprecated_member_use

// admin_report_api.dart
// DAE-1B Excel Report Generator + PDF Converter

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SQL MIGRATION REQUIRED (run once in Supabase SQL editor):
//
//   ALTER TYPE guest_status ADD VALUE IF NOT EXISTS 'archived';
//
// ─────────────────────────────────────────────────────────────────────────────

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

// ─── Country / Region Definitions ────────────────────────────────────────────

class _CountryGroup {
  final String region;
  final String subRegion;
  final String country;
  const _CountryGroup(this.region, this.subRegion, this.country);
}

const List<_CountryGroup> kCountryRows = [
  _CountryGroup('ASIA', 'ASEAN', 'BRUNEI'),
  _CountryGroup('ASIA', 'ASEAN', 'CAMBODIA'),
  _CountryGroup('ASIA', 'ASEAN', 'INDONESIA'),
  _CountryGroup('ASIA', 'ASEAN', 'LAOS'),
  _CountryGroup('ASIA', 'ASEAN', 'MALAYSIA'),
  _CountryGroup('ASIA', 'ASEAN', 'MYANMAR'),
  _CountryGroup('ASIA', 'ASEAN', 'SINGAPORE'),
  _CountryGroup('ASIA', 'ASEAN', 'THAILAND'),
  _CountryGroup('ASIA', 'ASEAN', 'VIETNAM'),
  _CountryGroup('ASIA', 'EAST ASIA', 'CHINA'),
  _CountryGroup('ASIA', 'EAST ASIA', 'HONGKONG'),
  _CountryGroup('ASIA', 'EAST ASIA', 'JAPAN'),
  _CountryGroup('ASIA', 'EAST ASIA', 'KOREA'),
  _CountryGroup('ASIA', 'EAST ASIA', 'TAIWAN'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'BANGLADESH'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'INDIA'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'IRAN'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'NEPAL'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'PAKISTAN'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'SRI LANKA'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'BAHRAIN'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'EGYPT'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'ISRAEL'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'JORDAN'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'KUWAIT'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'SAUDI ARABIA'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'UNITED ARAB EMIRATES'),
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'CANADA'),
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'MEXICO'),
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'USA'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'ARGENTINA'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'BRAZIL'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'COLOMBIA'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'PERU'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'VENEZUELA'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'AUSTRIA'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'BELGIUM'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'FRANCE'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'GERMANY'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'LUXEMBOURG'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'NETHERLANDS'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'SWITZERLAND'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'DENMARK'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'FINLAND'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'IRELAND'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'NORWAY'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'SWEDEN'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'UNITED KINGDOM'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'GREECE'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'ITALY'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'PORTUGAL'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'SPAIN'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'UNION OF SERBIA AND MONTENEGRO'),
  _CountryGroup(
    'EUROPE',
    'EASTERN EUROPE',
    'COMMONWEALTH OF INDEPENDENT STATES',
  ),
  _CountryGroup('EUROPE', 'EASTERN EUROPE', 'POLAND'),
  _CountryGroup('EUROPE', 'EASTERN EUROPE', 'RUSSIA'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'AUSTRALIA'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'GUAM'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'NAURU'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'NEW ZEALAND'),
  _CountryGroup(
    'AUSTRALASIA/PACIFIC',
    'AUSTRALASIA/PACIFIC',
    'PAPUA NEW GUINEA',
  ),
  _CountryGroup('AFRICA', 'AFRICA', 'NIGERIA'),
  _CountryGroup('AFRICA', 'AFRICA', 'SOUTH AFRICA'),
];

const List<String> kMonthNames = [
  '',
  'JANUARY',
  'FEBRUARY',
  'MARCH',
  'APRIL',
  'MAY',
  'JUNE',
  'JULY',
  'AUGUST',
  'SEPTEMBER',
  'OCTOBER',
  'NOVEMBER',
  'DECEMBER',
];

// ─── Shared Types ─────────────────────────────────────────────────────────────

class ReportSheetOptions {
  final bool includeDailySheet;
  final bool includeCountrySumSheet;
  final bool includeMonthlySummarySheet;
  const ReportSheetOptions({
    this.includeDailySheet = true,
    this.includeCountrySumSheet = true,
    this.includeMonthlySummarySheet = true,
  });
}

class ReportParams {
  final int month;
  final int year;
  final ReportSheetOptions sheetOptions;
  const ReportParams({
    required this.month,
    required this.year,
    required this.sheetOptions,
  }) : assert(month >= 1 && month <= 12, 'month must be 1–12');
}

/// Updated: rawBusinessLines added for checkbox matching.
class _BusinessInfo {
  final String id;
  final String name;
  final String businessLine;
  final List<String> rawBusinessLines;
  final String region;
  final String cityMunicipality;
  final String province;
  final int totalRooms;
  _BusinessInfo({
    required this.id,
    required this.name,
    required this.businessLine,
    required this.rawBusinessLines,
    required this.region,
    required this.cityMunicipality,
    required this.province,
    required this.totalRooms,
  });
}

typedef _DayCountMap = Map<String, Map<int, int>>;

class _MonthData {
  final int month;
  final _DayCountMap countryByDay;
  final Map<int, Map<String, int>> residentsByDay;
  final Map<int, Map<String, Map<String, int>>> sexByDay;
  final Map<int, int> roomsOccupied;
  final Map<int, int> guestNightsByDay;
  final Map<int, int> guestNightsPerArrivalDay;
  final int guestNights;
  final int roomsAvailable;
  const _MonthData({
    required this.month,
    required this.countryByDay,
    required this.residentsByDay,
    required this.sexByDay,
    required this.roomsOccupied,
    required this.guestNightsByDay,
    required this.guestNightsPerArrivalDay,
    required this.guestNights,
    required this.roomsAvailable,
  });
}

// ─── Report Service ───────────────────────────────────────────────────────────

class ReportService {
  ReportService({SupabaseClient? client})
    : _sb = client ?? Supabase.instance.client;

  final SupabaseClient _sb;
  static const _bucket = 'reports';

  // ── Excel colour constants ─────────────────────────────────────────────────
  static const _kBlue = 'FF0070C0';
  static const _kGreen = 'FF92D050';
  static const _kOliveGreen = 'FFD8E4BC';
  static const _kLightBlue = 'FF00B0F0';
  static const _kYellow = 'FFFFFF00';
  static const _kLightYellow = 'FFFFFF66';
  static const _kWhite = 'FFFFFFFF';
  static final _kThinBorder = Border(borderStyle: BorderStyle.Thin);

  // ── Pre-computed sets for italic detection in PDF ─────────────────────────
  // Sub-regions that are distinct from their region name (i.e., they get their
  // own indented sub-region header row in the sheet).
  static final Set<String> _pdfItalicSubRegions = kCountryRows
      .where((cg) => cg.subRegion != cg.region)
      .map((cg) => cg.subRegion.toUpperCase())
      .toSet();

  // All country names (always italic).
  static final Set<String> _pdfItalicCountries = kCountryRows
      .map((cg) => cg.country.toUpperCase())
      .toSet();

  // Accommodation type key → display label pairs used across sheet builders.
  static const List<List<String>> _kAccTypes = [
    ['hotel', 'Hotel'],
    ['resort', 'Resort'],
    ['pension_inn', 'Pension Inn/ Lodge'],
    ['youth_hostel', 'Youth Hostel/ Dormitory'],
    ['apartment', 'Apartel/ Rented Homes/ Apartment'],
    ['others', 'Others, please specify: _________________________'],
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches all generated reports from the database, newest first.
  Future<List<GeneratedReport>> fetchReports() async {
    final rows = await _sb
        .from('reports')
        .select('*')
        .order('generated_at', ascending: false);
    return (rows as List)
        .map((r) => GeneratedReport.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Downloads a report file from Supabase storage and returns its raw bytes.
  /// Accepts either a full public URL or a storage path.
  Future<Uint8List> downloadReportFile(String fileUrl) async {
    String filePath = fileUrl;
    if (filePath.contains('/reports/')) {
      filePath = filePath.split('/reports/').last;
    }
    return _sb.storage.from(_bucket).download(filePath);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXCEL → PDF CONVERSION
  // ══════════════════════════════════════════════════════════════════════════

  /// Converts already-downloaded Excel bytes into a PDF document.
  ///
  /// Sheet detection by column count:
  ///  ≥ 30 cols → A3 landscape daily sheet  (headerRows = 24)
  ///  ≥ 10 cols → A3 landscape monthly sheet (headerRows = 7)
  ///   < 10 cols → A4 portrait summary sheet  (headerRows = 7)
  ///
  /// Row colors, bold and italic styling mirror the Excel export exactly.
  Future<Uint8List> convertExcelToPdf(Uint8List excelBytes) async {
    final excel = Excel.decodeBytes(excelBytes);
    final doc = pw.Document();

    for (final entry in excel.sheets.entries) {
      final sheet = entry.value;
      final sheetRows = sheet.rows;
      if (sheetRows.isEmpty) continue;

      int maxCols = 0;
      for (final row in sheetRows) {
        if (row.length > maxCols) maxCols = row.length;
      }
      if (maxCols == 0) continue;

      final PdfPageFormat pageFormat;
      final List<double> colWidths;
      final int headerRows;

      if (maxCols >= 30) {
        // Daily establishment sheet – 33 cols (label + 31 days + total)
        // Header occupies rows 0-23; col-header row is 24.
        pageFormat = PdfPageFormat.a3.landscape;
        colWidths = _pdfDailyColWidths(maxCols);
        headerRows = 26;
      } else if (maxCols >= 10) {
        // Monthly summary sheet – 14 cols (label + 12 months + total)
        pageFormat = PdfPageFormat.a3.landscape;
        colWidths = _pdfMonthlyColWidths(maxCols);
        headerRows = 7;
      } else {
        // Country summary sheet – 2 cols
        pageFormat = PdfPageFormat.a4;
        colWidths = _pdfSummaryColWidths(maxCols);
        headerRows = 7;
      }

      final sheetName = entry.key;

      doc.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(12),
          header: (ctx) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            ),
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  sheetName,
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 8,
                  ),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber}',
                  style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          build: (ctx) => sheetRows.asMap().entries.map((e) {
            return _buildPdfRow(e.value, e.key, maxCols, colWidths, headerRows);
          }).toList(),
        ),
      );
    }

    return doc.save();
  }

  // ── PDF column-width helpers ───────────────────────────────────────────────
  // A3 landscape usable width ≈ 1190 pt − 24 pt margins = 1166 pt
  // A4 portrait  usable width ≈  595 pt − 24 pt margins =  571 pt

  List<double> _pdfDailyColWidths(int maxCols) {
    return List.generate(maxCols, (c) {
      if (c == 0) return 350.0;
      if (c == maxCols - 1) return 120.0;
      return 22.5;
    });
  }

  List<double> _pdfMonthlyColWidths(int maxCols) {
    return List.generate(maxCols, (c) {
      if (c == 0) return 350.0;
      if (c == maxCols - 1) return 120.0;
      return 58.0;
    });
  }

  List<double> _pdfSummaryColWidths(int maxCols) {
    if (maxCols <= 1) return [571.0];
    return List.generate(maxCols, (c) => c == 0 ? 451.0 : 120.0);
  }

  // ── PDF row builder ────────────────────────────────────────────────────────

  pw.Widget _buildPdfRow(
    List<Data?> cells,
    int rowIndex,
    int maxCols,
    List<double> colWidths,
    int headerRows,
  ) {
    final firstVal = cells.isNotEmpty
        ? (cells[0]?.value?.toString() ?? '')
        : '';
    final lastVal = (maxCols > 1 && cells.length >= maxCols)
        ? (cells[maxCols - 1]?.value?.toString() ?? '')
        : '';

    final f = firstVal.trim();
    final l = lastVal.trim();

    // ── Footer row detection ─────────────────────────────────────────────────
    // These rows are rendered as plain text (no cell grid) with optional
    // right-aligned content (Date Submitted / date signature line).
    final isFooter =
        f.startsWith('* Philippine') ||
        f.startsWith('and Former Filipinos') ||
        f.startsWith('Prepared by:') ||
        f.startsWith('Signature over') ||
        (f.startsWith('_') && f.length > 5) ||
        f == 'Position/Designation' ||
        l.startsWith('Date Submitted') ||
        (f.isEmpty && l.startsWith('________________'));

    if (isFooter) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
        child: pw.Row(
          mainAxisAlignment: (f.isNotEmpty && l.isNotEmpty)
              ? pw.MainAxisAlignment.spaceBetween
              : (l.isNotEmpty
                    ? pw.MainAxisAlignment.end
                    : pw.MainAxisAlignment.start),
          children: [
            if (f.isNotEmpty)
              pw.Text(
                firstVal,
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7.0),
              ),
            if (l.isNotEmpty)
              pw.Text(
                lastVal,
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7.0),
              ),
          ],
        ),
      );
    }

    // ── Metadata / header rows (plain text, no grid) ───────────────────────
    if (rowIndex < headerRows) {
      final isBigTitle = f.startsWith('REPORT ON');
      final isBold =
          isBigTitle ||
          f.startsWith('Region:') ||
          f == 'Type of Accommodation' ||
          f.startsWith('DOT Accreditation') ||
          f.startsWith('AE ID Code') ||
          f.startsWith('City/Municipality') ||
          f.startsWith('Province:') ||
          f.startsWith('All Accommodation') ||
          f.startsWith('DAE-1B');

      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(
          horizontal: 2,
          vertical: isBigTitle ? 3 : 0.8,
        ),
        child: pw.Text(
          firstVal,
          style: pw.TextStyle(
            font: isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
            fontSize: isBigTitle ? 9.0 : 7.0,
          ),
          textAlign: pw.TextAlign.left,
        ),
      );
    }

    // ── Normal data rows ───────────────────────────────────────────────────
    final bg = _pdfColorForRow(firstVal, rowIndex, headerRows);
    final bold = _pdfIsBold(firstVal, rowIndex, headerRows);
    final isItalic = _pdfIsItalic(firstVal, rowIndex, headerRows);
    final isBlue = _pdfIsBlueRow(firstVal, rowIndex, headerRows);
    final txtClr = isBlue ? PdfColors.white : PdfColors.black;

    return pw.Container(
      decoration: pw.BoxDecoration(color: bg),
      child: pw.Row(
        children: List.generate(maxCols, (c) {
          final cell = c < cells.length ? cells[c] : null;
          final raw = cell?.value?.toString() ?? '';
          final w = c < colWidths.length ? colWidths[c] : 15.0;

          // Italic applies only to the label column (col 0).
          final cellItalic = isItalic && c == 0;
          final cellFont = (bold && cellItalic)
              ? pw.Font.helveticaBoldOblique()
              : bold
              ? pw.Font.helveticaBold()
              : cellItalic
              ? pw.Font.helveticaOblique()
              : pw.Font.helvetica();

          return pw.Container(
            width: w,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 1.5,
              vertical: 0.8,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: c == 0
                    ? const pw.BorderSide(color: PdfColors.grey400, width: 0.3)
                    : pw.BorderSide.none,
                right: const pw.BorderSide(
                  color: PdfColors.grey400,
                  width: 0.3,
                ),
                top: const pw.BorderSide(color: PdfColors.grey400, width: 0.3),
                bottom: const pw.BorderSide(
                  color: PdfColors.grey400,
                  width: 0.3,
                ),
              ),
            ),
            child: pw.Text(
              raw,
              style: pw.TextStyle(font: cellFont, fontSize: 5.5, color: txtClr),
              textAlign: c == 0 ? pw.TextAlign.left : pw.TextAlign.center,
              overflow: pw.TextOverflow.clip,
              maxLines: 1,
            ),
          );
        }),
      ),
    );
  }

  // ── PDF colour / style logic ───────────────────────────────────────────────

  PdfColor _pdfColorForRow(String label, int rowIndex, int headerRows) {
    if (rowIndex < headerRows) return PdfColors.white;
    final u = label.trim().toUpperCase();

    if (u == 'COUNTRY OF RESIDENCE') return PdfColor.fromHex('#FFFF66');
    if (u.contains('GRAND TOTAL')) return PdfColor.fromHex('#FFFF00');
    if (u == 'A. DAE2:' || u.contains('VOLUME PER SEX'))
      return PdfColor.fromHex('#FFFF00');
    if (_pdfIsGreenLabel(u)) return PdfColor.fromHex('#92D050');
    if (u.contains('SUB-TOTAL')) return PdfColor.fromHex('#00B0F0');
    if (_pdfIsBlueLabel(u)) return PdfColor.fromHex('#0070C0');
    return PdfColors.white;
  }

  bool _pdfIsGreenLabel(String u) =>
      u == 'TOTAL PHILIPPINE RESIDENTS' ||
      u == 'TOTAL NON-PHILIPPINE RESIDENTS' ||
      u.startsWith('   TOTAL PHILIPPINE') ||
      u.startsWith('   TOTAL NON-PHILIPPINE') ||
      u.startsWith('   TOTAL OVERSEAS') ||
      u.startsWith('   TOTAL GUEST');

  bool _pdfIsBlueLabel(String u) =>
      u == 'PHILIPPINE RESIDENTS' ||
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
      u.contains('OVERSEAS FILIPINOS') ||
      // UPDATED: replaces the old single-row 'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES'
      u == 'OTHERS AND UNSPECIFIED' ||
      u == 'NON-PHILIPPINE RESIDENCES';

  bool _pdfIsBlueRow(String label, int rowIndex, int headerRows) {
    if (rowIndex < headerRows) return false;
    return _pdfIsBlueLabel(label.trim().toUpperCase());
  }

  bool _pdfIsBold(String label, int rowIndex, int headerRows) {
    if (rowIndex < headerRows) return false;
    final u = label.trim().toUpperCase();
    if (u == 'COUNTRY OF RESIDENCE') return true;
    if (u.contains('GRAND TOTAL')) return true;
    if (u == 'A. DAE2:' || u.contains('VOLUME PER SEX')) return true;
    if (_pdfIsGreenLabel(u)) return true;
    if (u.contains('SUB-TOTAL')) return true;
    if (_pdfIsBlueLabel(u)) return true;
    // Country rows are indented with 7 spaces.
    if (label.startsWith('       ') && label.trim().isNotEmpty) return true;
    if (u == 'X. TOTAL') return true;
    return false;
  }

  /// Returns true when the label cell (col 0) should be italic.
  /// Applies to: COUNTRY OF RESIDENCE header, FILIPINO/FOREIGN NATIONALITY
  /// rows, all sub-region header rows, and all country rows.
  bool _pdfIsItalic(String label, int rowIndex, int headerRows) {
    if (rowIndex < headerRows) return false;
    final u = label.trim().toUpperCase();
    if (u == 'COUNTRY OF RESIDENCE') return true;
    if (u == 'FILIPINO NATIONALITY' || u == 'FOREIGN NATIONALITY') return true;
    if (_pdfItalicSubRegions.contains(u)) return true;
    if (_pdfItalicCountries.contains(u)) return true;
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENERATE & UPLOAD
  // ══════════════════════════════════════════════════════════════════════════

  Future<String> generateAndUpload(ReportParams params) async {
    await _checkDuplicateReport(params.month, params.year);

    final businesses = await _fetchAllBusinesses();
    if (businesses.isEmpty) throw Exception('No approved businesses found.');

    final List<_MonthData> selectedMonthPerBiz = await Future.wait(
      businesses.map((b) => _fetchMonthData(b.id, params.month, params.year)),
    );

    List<_MonthData>? allTwelveMonthsMerged;
    if (params.sheetOptions.includeMonthlySummarySheet) {
      allTwelveMonthsMerged = [];
      for (int m = 1; m <= 12; m++) {
        if (m == params.month) {
          allTwelveMonthsMerged.add(_mergeMonthData(m, selectedMonthPerBiz));
        } else {
          final perBiz = await Future.wait(
            businesses.map((b) => _fetchMonthData(b.id, m, params.year)),
          );
          allTwelveMonthsMerged.add(_mergeMonthData(m, perBiz));
        }
      }
    }

    final totalRoomsAll = businesses.fold<int>(0, (s, b) => s + b.totalRooms);
    final bytes = _buildWorkbook(
      businesses: businesses,
      selectedMonthPerBiz: selectedMonthPerBiz,
      allTwelveMonthsMerged: allTwelveMonthsMerged,
      totalRoomsAll: totalRoomsAll,
      params: params,
    );

    final fileName =
        'DAE1B_ALL_${params.year}_${params.month.toString().padLeft(2, '0')}'
        '_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final storagePath = 'dae1b/$fileName';

    await _sb.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        );

    final fileUrl = _sb.storage.from(_bucket).getPublicUrl(storagePath);

    List<String> archivedIds = [];
    try {
      archivedIds = await _archiveMonthRecords(params.month, params.year);
    } catch (archiveErr) {
      try {
        await _sb.storage.from(_bucket).remove([storagePath]);
      } catch (_) {}
      throw Exception(
        'Report generation rolled back: could not archive guest records.\n'
        'Details: $archiveErr',
      );
    }

    try {
      await _sb.from('reports').insert({
        'report_type': 'DAE-1B',
        'period_month': params.month,
        'period_year': params.year,
        'file_url': fileUrl,
        'generated_by': _sb.auth.currentUser?.id,
        'include_sheet_establishment': params.sheetOptions.includeDailySheet,
        'include_sheet_country_sum': params.sheetOptions.includeCountrySumSheet,
        'include_sheet_monthly': params.sheetOptions.includeMonthlySummarySheet,
      });
    } catch (insertErr) {
      await _unarchiveRecords(archivedIds);
      try {
        await _sb.storage.from(_bucket).remove([storagePath]);
      } catch (_) {}
      throw Exception(
        'Report generation rolled back: could not save report record.\n'
        'Details: $insertErr',
      );
    }

    return fileUrl;
  }

  // ── Archiving ──────────────────────────────────────────────────────────────

  Future<void> _checkDuplicateReport(int month, int year) async {
    final existing = await _sb
        .from('reports')
        .select('id')
        .eq('report_type', 'DAE-1B')
        .eq('period_month', month)
        .eq('period_year', year)
        .limit(1);
    if ((existing as List).isNotEmpty) {
      throw Exception(
        'A DAE-1B report for ${kMonthNames[month]} $year already exists. '
        'Re-generating the same month is blocked to prevent duplicate archiving.',
      );
    }
  }

  Future<List<String>> _archiveMonthRecords(int month, int year) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final firstStr = firstDay.toIso8601String().substring(0, 10);
    final lastStr = lastDay.toIso8601String().substring(0, 10);

    final rows = await _sb
        .from('guest_records')
        .select('id')
        .eq('status', 'active')
        .eq('is_deleted', false)
        .gte('check_in', firstStr)
        .lte('check_in', lastStr);

    final ids = (rows as List).map((r) => r['id'] as String).toList();
    if (ids.isEmpty) return [];

    const chunkSize = 100;
    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));
      await _sb
          .from('guest_records')
          .update({'status': 'archived'})
          .inFilter('id', chunk);
    }
    return ids;
  }

  Future<void> _unarchiveRecords(List<String> ids) async {
    if (ids.isEmpty) return;
    const chunkSize = 100;
    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));
      try {
        await _sb
            .from('guest_records')
            .update({'status': 'active'})
            .inFilter('id', chunk);
      } catch (_) {}
    }
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────

  Future<List<_BusinessInfo>> _fetchAllBusinesses() async {
    final rows = await _sb
        .from('businesses')
        .select(
          'id, business_name, business_line, region, '
          'city_municipality, province, total_rooms',
        )
        .eq('status', 'approved')
        .order('business_name');
    return (rows as List)
        .map(
          (r) => _BusinessInfo(
            id: r['id'] as String,
            name: r['business_name'] as String? ?? 'Unknown',
            businessLine: _displayBusinessLine(r['business_line']),
            rawBusinessLines: _extractRawBusinessLines(r['business_line']),
            region: r['region'] as String? ?? '4-A',
            cityMunicipality: r['city_municipality'] as String? ?? '',
            province: r['province'] as String? ?? '',
            totalRooms: r['total_rooms'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<_MonthData> _fetchMonthData(
    String businessId,
    int month,
    int year,
  ) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final records = await _sb
        .from('guest_records')
        .select('id, check_in, check_out, rooms_occupied')
        .eq('business_id', businessId)
        .eq('status', 'active')
        .eq('is_deleted', false)
        .gte('check_in', firstDay.toIso8601String().substring(0, 10))
        .lte('check_in', lastDay.toIso8601String().substring(0, 10));

    final recordIds = (records as List).map((r) => r['id'] as String).toList();
    List breakdowns = [];
    if (recordIds.isNotEmpty) {
      breakdowns = await _sb
          .from('guest_breakdowns')
          .select(
            'guest_record_id, country, sex, nationality, count, is_overseas',
          )
          .inFilter('guest_record_id', recordIds);
    }

    final Map<String, int> recordGuestCount = {};
    for (final raw in breakdowns) {
      final b = Map<String, dynamic>.from(raw as Map);
      final recId = b['guest_record_id']?.toString() ?? '';
      recordGuestCount[recId] =
          (recordGuestCount[recId] ?? 0) + _asInt(b['count']);
    }

    final Map<String, int> recordDay = {};
    int totalGuestNights = 0;
    final _DayCountMap countryByDay = {};
    final Map<int, Map<String, int>> residentsByDay = {};
    final Map<int, Map<String, Map<String, int>>> sexByDay = {};
    final Map<int, int> roomsOccupiedByDay = {};
    final Map<int, int> guestNightsByDay = {};
    final Map<int, int> guestNightsPerArrivalDay = {};

    for (final r in records) {
      final checkIn = DateTime.parse(r['check_in']);
      final checkOut = DateTime.parse(r['check_out']);
      final nights = checkOut.difference(checkIn).inDays;
      final rooms = r['rooms_occupied'] as int? ?? 0;
      final guestCount = recordGuestCount[r['id'] as String] ?? 0;
      recordDay[r['id']] = checkIn.day;
      if (nights > 0) {
        totalGuestNights += nights * guestCount;
        guestNightsPerArrivalDay[checkIn.day] =
            (guestNightsPerArrivalDay[checkIn.day] ?? 0) +
            (nights * guestCount);
        for (int n = 0; n < nights; n++) {
          final stayDate = checkIn.add(Duration(days: n));
          if (stayDate.year != year || stayDate.month != month) continue;
          final stayDay = stayDate.day;
          roomsOccupiedByDay[stayDay] =
              (roomsOccupiedByDay[stayDay] ?? 0) + rooms;
          guestNightsByDay[stayDay] =
              (guestNightsByDay[stayDay] ?? 0) + guestCount;
        }
      }
    }

    for (final raw in breakdowns) {
      final b = Map<String, dynamic>.from(raw as Map);
      final recId = b['guest_record_id']?.toString() ?? '';
      final day = recordDay[recId] ?? 1;
      final country = _normalizeUpper(b['country']);
      final nationality = _normalizeUpper(b['nationality']);
      final sex = _normalizeLower(b['sex']);
      final isOverseas = _asBool(b['is_overseas']);
      final count = _asInt(b['count']);
      final bucket = _classifyResidenceBucket(
        country: country,
        nationality: nationality,
        isOverseas: isOverseas,
      );

      if (bucket == 'foreign_resident' && country.isNotEmpty) {
        countryByDay.putIfAbsent(country, () => {});
        countryByDay[country]![day] =
            (countryByDay[country]![day] ?? 0) + count;
        countryByDay[country]![0] = (countryByDay[country]![0] ?? 0) + count;
      }

      residentsByDay.putIfAbsent(day, () => {});
      residentsByDay[day]![bucket] =
          (residentsByDay[day]![bucket] ?? 0) + count;
      residentsByDay[0] ??= {};
      residentsByDay[0]![bucket] = (residentsByDay[0]![bucket] ?? 0) + count;

      sexByDay.putIfAbsent(day, () => {});
      sexByDay[day]!.putIfAbsent(sex, () => {});
      sexByDay[day]![sex]![bucket] =
          (sexByDay[day]![sex]![bucket] ?? 0) + count;
      sexByDay[0] ??= {};
      sexByDay[0]!.putIfAbsent(sex, () => {});
      sexByDay[0]![sex]![bucket] = (sexByDay[0]![sex]![bucket] ?? 0) + count;
    }

    return _MonthData(
      month: month,
      countryByDay: countryByDay,
      residentsByDay: residentsByDay,
      sexByDay: sexByDay,
      roomsOccupied: roomsOccupiedByDay,
      guestNightsByDay: guestNightsByDay,
      guestNightsPerArrivalDay: guestNightsPerArrivalDay,
      guestNights: totalGuestNights,
      roomsAvailable: 0,
    );
  }

  // ── Merge ──────────────────────────────────────────────────────────────────

  _MonthData _mergeMonthData(int month, List<_MonthData> list) {
    final _DayCountMap countryByDay = {};
    final Map<int, Map<String, int>> residentsByDay = {};
    final Map<int, Map<String, Map<String, int>>> sexByDay = {};
    final Map<int, int> roomsOccupied = {};
    final Map<int, int> guestNightsByDay = {};
    final Map<int, int> guestNightsPerArrivalDay = {};
    int guestNights = 0;

    for (final md in list) {
      md.countryByDay.forEach((country, days) {
        countryByDay.putIfAbsent(country, () => {});
        days.forEach((day, count) {
          countryByDay[country]![day] =
              (countryByDay[country]![day] ?? 0) + count;
        });
      });
      md.residentsByDay.forEach((day, cats) {
        residentsByDay.putIfAbsent(day, () => {});
        cats.forEach((cat, count) {
          residentsByDay[day]![cat] = (residentsByDay[day]![cat] ?? 0) + count;
        });
      });
      md.sexByDay.forEach((day, sexMap) {
        sexByDay.putIfAbsent(day, () => {});
        sexMap.forEach((sex, cats) {
          sexByDay[day]!.putIfAbsent(sex, () => {});
          cats.forEach((cat, count) {
            sexByDay[day]![sex]![cat] =
                (sexByDay[day]![sex]![cat] ?? 0) + count;
          });
        });
      });
      md.roomsOccupied.forEach((day, count) {
        roomsOccupied[day] = (roomsOccupied[day] ?? 0) + count;
      });
      md.guestNightsByDay.forEach((day, count) {
        guestNightsByDay[day] = (guestNightsByDay[day] ?? 0) + count;
      });
      md.guestNightsPerArrivalDay.forEach((day, count) {
        guestNightsPerArrivalDay[day] =
            (guestNightsPerArrivalDay[day] ?? 0) + count;
      });
      guestNights += md.guestNights;
    }

    return _MonthData(
      month: month,
      countryByDay: countryByDay,
      residentsByDay: residentsByDay,
      sexByDay: sexByDay,
      roomsOccupied: roomsOccupied,
      guestNightsByDay: guestNightsByDay,
      guestNightsPerArrivalDay: guestNightsPerArrivalDay,
      guestNights: guestNights,
      roomsAvailable: 0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WORKBOOK BUILDER
  // ══════════════════════════════════════════════════════════════════════════

  Uint8List _buildWorkbook({
    required List<_BusinessInfo> businesses,
    required List<_MonthData> selectedMonthPerBiz,
    required List<_MonthData>? allTwelveMonthsMerged,
    required int totalRoomsAll,
    required ReportParams params,
  }) {
    final excel = Excel.createExcel();
    final daysInMonth = DateTime(params.year, params.month + 1, 0).day;
    final opts = params.sheetOptions;

    if (opts.includeDailySheet) {
      for (int i = 0; i < businesses.length; i++) {
        _buildDailySheet(
          excel,
          businesses[i],
          selectedMonthPerBiz[i],
          params.year,
          daysInMonth,
        );
      }
    }
    if (opts.includeCountrySumSheet) {
      final merged = _mergeMonthData(params.month, selectedMonthPerBiz);
      _buildCountrySummarySheet(
        excel,
        merged,
        totalRoomsAll,
        params.year,
        params.month,
        daysInMonth,
      );
    }
    if (opts.includeMonthlySummarySheet && allTwelveMonthsMerged != null) {
      _buildMonthlySummarySheet(
        excel,
        allTwelveMonthsMerged,
        totalRoomsAll,
        params.year,
      );
    }
    excel.delete('Sheet1');
    return Uint8List.fromList(excel.encode()!);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHEET 1 — Daily (per establishment)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // Header layout (rows 0-23 are plain-text metadata; row 24 = col-headers):
  //
  //  0  DAE-1B (Manual)
  //  1  [blank]
  //  2  Region: __X  (bold, centred, merged 0-32)
  //  3  <establishment name>  (centred, merged 0-32)
  //  4  <MONTH, YEAR>  (centred, merged 0-32)
  //  5  [blank]
  //  6  REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS  (bold, centred, merged)
  //  7  [blank]
  //  8  Type of Accommodation  (bold)
  //  9  ☑/☐ Hotel
  // 10  ☑/☐ Resort
  // 11  ☑/☐ Pension Inn/ Lodge
  // 12  ☑/☐ Youth Hostel/ Dormitory
  // 13  ☑/☐ Apartel/ Rented Homes/ Apartment
  // 14  ☑/☐ Others, please specify: _____
  // 15  [blank]
  // 16  DOT Accreditation Classification: ___________
  // 17  [blank]
  // 18  AE ID Code (LGU Assigned): ___
  // 19  AE ID Code (LGU Assigned): ___
  // 20  [blank]
  // 21  City/Municipality: ___
  // 22  Province: ___
  // 23  [blank]
  // 24  COUNTRY OF RESIDENCE | 1 | 2 | … | 31 | TOTAL  ← italic col-0 header

  void _buildDailySheet(
    Excel excel,
    _BusinessInfo biz,
    _MonthData md,
    int year,
    int daysInMonth,
  ) {
    final sheet = excel[_sheetTabName(biz.name)];
    _setupDailyColumns(sheet);
    int row = 0;

    // ── Header ──────────────────────────────────────────────────────────────
    _hdrCell(sheet, row++, 'DAE-1B (Manual)');
    _hdrCell(sheet, row++, ''); // blank row 1
    _hdrCell(
      sheet,
      row++,
      'Region: __4-A',
      bold: true,
      center: true,
      mergeToCol: 32,
    );
    _hdrCell(sheet, row++, biz.name, center: true, mergeToCol: 32);
    _hdrCell(
      sheet,
      row++,
      '     ${kMonthNames[md.month]}, $year    ',
      underline: true,
      center: true,
      mergeToCol: 32,
      underlineToCol: 6,
    );

    _hdrCell(sheet, row++, '(Month, Year)', center: true, mergeToCol: 32);
    _hdrCell(sheet, row++, ''); // blank row 5
    _hdrCell(
      sheet,
      row++,
      'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS',
      bold: true,
      center: true,
      size: 12,
      mergeToCol: 32,
    );
    _hdrCell(sheet, row++, ''); // blank row 7

    // Accommodation type checkboxes (rows 8-14)
    _hdrCell(sheet, row++, 'Type of Accommodation', bold: true);
    for (final pair in _kAccTypes) {
      final checked = biz.rawBusinessLines.contains(pair[0]);

      // Col 0 — label only, no checkbox char, no row advance yet
      _hdrCell(sheet, row, '    ${pair[1]}');

      // Col 1 — acts as the checkbox: bordered cell, checkmark if selected
      final checkCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );
      checkCell.value = TextCellValue(checked ? '✔' : '');
      checkCell.cellStyle = CellStyle(
        fontFamily: 'Arial',
        fontSize: 9,
        bold: checked,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: _kThinBorder,
        rightBorder: _kThinBorder,
        topBorder: _kThinBorder,
        bottomBorder: _kThinBorder,
      );

      row++; // advance only after both cells are written
    }

    _hdrCell(sheet, row++, ''); // blank row 15
    _hdrCell(
      sheet,
      row++,
      'DOT Accreditation Classification: _____________________________',
      bold: true,
    );
    _hdrCell(sheet, row++, ''); // blank row 17
    _hdrCell(
      sheet,
      row++,
      'AE ID Code (LGU Assigned): _________________________________________',
      bold: true,
    );
    _hdrCell(
      sheet,
      row++,
      'AE ID Code (LGU Assigned): ____________________________________________',
      bold: true,
    );
    _hdrCell(sheet, row++, ''); // blank row 20
    _hdrCell(
      sheet,
      row++,
      'City/Municipality: ${biz.cityMunicipality}',
      bold: true,
    );
    _hdrCell(sheet, row++, 'Province: ${biz.province}', bold: true);
    _hdrCell(sheet, row++, ''); // blank row 23

    // Row 24 — column headers (italic COUNTRY OF RESIDENCE)
    _writeDayColHeaders(sheet, row++);

    // ── Data helpers (closures capture `row` by reference) ─────────────────
    int cnt(String country, int day) =>
        md.countryByDay[country.toUpperCase()]?[day] ?? 0;
    int countryTotal(int day) =>
        md.countryByDay.values.fold<int>(0, (s, d) => s + (d[day] ?? 0));
    int res(int day, String cat) => md.residentsByDay[day]?[cat] ?? 0;

    List<String> dayValues(String label, int Function(int d) fn) {
      final cells = <String>[label];
      int total = 0;
      for (int d = 1; d <= 31; d++) {
        if (d <= daysInMonth) {
          final v = fn(d);
          cells.add(v.toString());
          total += v;
        } else {
          cells.add('');
        }
      }
      cells.add(total.toString());
      return cells;
    }

    // ── Part I — Arrivals ────────────────────────────────────────────────────
    _blankDataRow(sheet, row++, 33, bgHex: _kOliveGreen);
    // Philippine Residents
    _sectionRow(sheet, row++, 'PHILIPPINE RESIDENTS', _kBlue, totalCols: 33);
    _styledRow(
      sheet,
      row++,
      dayValues(
        '   FILIPINO NATIONALITY',
        (d) => res(d, 'philippine_resident_filipino'),
      ),
      italic: true,
    );
    _styledRow(
      sheet,
      row++,
      dayValues(
        '   FOREIGN NATIONALITY',
        (d) => res(d, 'philippine_resident_foreign'),
      ),
      italic: true,
    );
    final prVals = dayValues(
      'TOTAL PHILIPPINE RESIDENTS',
      (d) =>
          res(d, 'philippine_resident_filipino') +
          res(d, 'philippine_resident_foreign'),
    );
    prVals[32] =
        (res(0, 'philippine_resident_filipino') +
                res(0, 'philippine_resident_foreign'))
            .toString();
    _styledRow(sheet, row++, prVals, bgHex: _kGreen, bold: true);

    _blankDataRow(sheet, row++, 33, bgHex: _kOliveGreen);
    _sectionRow(
      sheet,
      row++,
      'NON-PHILIPPINE RESIDENTS',
      _kBlue,
      totalCols: 33,
    );
    _blankDataRow(sheet, row++, 33, bgHex: _kOliveGreen);

    // Country rows
    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _sectionRow(sheet, row++, cg.region, _kBlue, totalCols: 33);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _sectionRow(
          sheet,
          row++,
          '   ${cg.subRegion}',
          _kBlue,
          totalCols: 33,
          italic: true,
        );
        lastSubRegion = cg.subRegion;
      }
      _styledRow(
        sheet,
        row++,
        dayValues('       ${cg.country}', (d) => cnt(cg.country, d)),
        bold: true,
        italic: true,
      );

      final idx = kCountryRows.indexOf(cg);
      final isLastInSub =
          idx == kCountryRows.length - 1 ||
          kCountryRows[idx + 1].subRegion != cg.subRegion;
      if (isLastInSub) {
        final subCountries = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .map((x) => x.country)
            .toList();
        final stVals = dayValues(
          '                 SUB-TOTAL',
          (d) => subCountries.fold<int>(0, (a, c) => a + cnt(c, d)),
        );
        stVals[32] = subCountries
            .fold<int>(0, (a, c) => a + (md.countryByDay[c]?[0] ?? 0))
            .toString();
        _styledRow(sheet, row++, stVals, bgHex: _kLightBlue, bold: true);
        _blankDataRow(sheet, row++, 33, bgHex: _kOliveGreen);
      }
    }

    // OTHERS AND UNSPECIFIED (section header, no data)
    // NON-PHILIPPINE RESIDENCES (data row with unspecified_guest values)
    _sectionRow(sheet, row++, 'OTHERS AND UNSPECIFIED', _kBlue, totalCols: 33);
    _styledRow(
      sheet,
      row++,
      dayValues(
        'NON-PHILIPPINE RESIDENCES',
        (d) => res(d, 'unspecified_guest'),
      ),
      bgHex: _kBlue,
      bold: true,
    );

    _blankDataRow(sheet, row++, 33, bgHex: _kOliveGreen);
    final int nprTotal =
        md.countryByDay.values.fold<int>(0, (a, d) => a + (d[0] ?? 0)) +
        res(0, 'unspecified_guest');
    final nprVals = dayValues(
      'TOTAL NON-PHILIPPINE RESIDENTS',
      (d) => countryTotal(d) + res(d, 'unspecified_guest'),
    );
    nprVals[32] = nprTotal.toString();
    _styledRow(sheet, row++, nprVals, bgHex: _kGreen, bold: true);

    _blankDataRow(sheet, row++, 33, bgHex: _kOliveGreen);
    _styledRow(
      sheet,
      row++,
      dayValues('OVERSEAS FILIPINOS*', (d) => res(d, 'overseas_filipino')),
      bgHex: _kBlue,
      bold: true,
    );

    _blankDataRow(sheet, row++, 33, bgHex: _kOliveGreen);
    final int gtTotal =
        res(0, 'philippine_resident_filipino') +
        res(0, 'philippine_resident_foreign') +
        nprTotal +
        res(0, 'overseas_filipino');
    final gtVals = dayValues(
      'GRAND TOTAL GUEST ARRIVALS',
      (d) =>
          res(d, 'philippine_resident_filipino') +
          res(d, 'philippine_resident_foreign') +
          countryTotal(d) +
          res(d, 'unspecified_guest') +
          res(d, 'overseas_filipino'),
    );
    gtVals[32] = gtTotal.toString();
    _styledRow(sheet, row++, gtVals, bgHex: _kYellow, bold: true);

    _styledRow(
      sheet,
      row++,
      dayValues(
        '   Total Philippine Residents',
        (d) =>
            res(d, 'philippine_resident_filipino') +
            res(d, 'philippine_resident_foreign'),
      ),
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      dayValues(
        '   Total Non-Philippine Residents',
        (d) => countryTotal(d) + res(d, 'unspecified_guest'),
      ),
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      dayValues(
        '   Total Overseas Filipinos',
        (d) => res(d, 'overseas_filipino'),
      ),
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      dayValues(
        '   Total Guest with Unspecified Residence',
        (d) => res(d, 'unspecified_guest'),
      ),
      bgHex: _kGreen,
      bold: true,
    );

    // ── Part II — Other Indicators ───────────────────────────────────────────

    _blankDataRow(sheet, row++, 33);
    _hdrCell(sheet, row++, 'PART II.  Other Indicators', bold: true, size: 12);
    _blankDataRow(sheet, row++, 33);
    _sectionRow(
      sheet,
      row++,
      'A. DAE2:',
      _kYellow,
      totalCols: 33,
      bold: true,
      size: 12,
    );

    final roomVals = dayValues(
      '1. Rooms Occupied',
      (d) => md.roomsOccupied[d] ?? 0,
    );
    roomVals[32] = md.roomsOccupied.values
        .fold<int>(0, (a, b) => a + b)
        .toString();
    _styledRow(sheet, row++, roomVals);

    final availVals = <String>['2. Rooms available for the month'];
    for (int d = 1; d <= 31; d++) {
      availVals.add(d <= daysInMonth ? biz.totalRooms.toString() : '');
    }
    availVals.add((biz.totalRooms * daysInMonth).toString());
    _styledRow(sheet, row++, availVals);

    final gnVals = dayValues(
      '3. Total Guest nights',
      (d) => md.guestNightsByDay[d] ?? 0,
    );
    gnVals[32] = md.guestNights.toString();
    _styledRow(sheet, row++, gnVals);

    _styledCell(
      sheet,
      row++,
      0,
      'Alternative Submission',
      bold: true,
      bgHex: _kOliveGreen,
      size: 12,
    );

    final totalRoomsOcc = md.roomsOccupied.values.fold<int>(0, (a, b) => a + b);
    final roomsAvail = biz.totalRooms * daysInMonth;
    final occVals = <String>['1. Average Monthly Occupancy Rate'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final occDay = md.roomsOccupied[d] ?? 0;
        occVals.add(
          biz.totalRooms > 0
              ? (occDay / biz.totalRooms * 100).toStringAsFixed(2)
              : '0',
        );
      } else {
        occVals.add('');
      }
    }
    occVals.add(
      roomsAvail > 0
          ? (totalRoomsOcc / roomsAvail * 100).toStringAsFixed(2)
          : '0',
    );
    _styledRow(sheet, row++, occVals);

    int guestArrivalsDay(int day) =>
        md.residentsByDay[day]?.values.fold<int>(0, (s, v) => s + v) ?? 0;
    final alsVals = <String>['2. Average Length of Stay (in Nights)'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final arrivals = guestArrivalsDay(d);
        final nights = md.guestNightsPerArrivalDay[d] ?? 0;
        alsVals.add(
          arrivals > 0 ? (nights / arrivals).toStringAsFixed(2) : '0',
        );
      } else {
        alsVals.add('');
      }
    }
    alsVals.add(
      gtTotal > 0 ? (md.guestNights / gtTotal).toStringAsFixed(2) : '0',
    );
    _styledRow(sheet, row++, alsVals);

    _blankDataRow(sheet, row++, 33);
    _sectionRow(
      sheet,
      row++,
      'B. VOLUME PER SEX',
      _kYellow,
      totalCols: 33,
      bold: true,
      size: 12,
    );

    int sex(int day, String s, String cat) => md.sexByDay[day]?[s]?[cat] ?? 0;

    void sexSection(String gender, String label) {
      _styledCell(sheet, row++, 0, label, bold: true);
      _styledRow(
        sheet,
        row++,
        dayValues(
          'a. Philippine Residents',
          (d) =>
              sex(d, gender, 'philippine_resident_filipino') +
              sex(d, gender, 'philippine_resident_foreign'),
        ),
      );
      _styledRow(
        sheet,
        row++,
        dayValues(
          'b. Non-Philippine/Foreign Residents (including unspecified)',
          (d) => sex(d, gender, 'foreign_resident'),
        ),
      );
      _styledRow(
        sheet,
        row++,
        dayValues(
          'c. Overseas Filipinos',
          (d) => sex(d, gender, 'overseas_filipino'),
        ),
      );
      _styledRow(
        sheet,
        row++,
        dayValues(
          'd. Others/Unspecified Guest',
          (d) => sex(d, gender, 'unspecified_guest'),
        ),
      );
      final totVals = dayValues(
        'x. Total',
        (d) =>
            sex(d, gender, 'philippine_resident_filipino') +
            sex(d, gender, 'philippine_resident_foreign') +
            sex(d, gender, 'foreign_resident') +
            sex(d, gender, 'unspecified_guest') +
            sex(d, gender, 'overseas_filipino'),
      );
      totVals[32] =
          (sex(0, gender, 'philippine_resident_filipino') +
                  sex(0, gender, 'philippine_resident_foreign') +
                  sex(0, gender, 'foreign_resident') +
                  sex(0, gender, 'unspecified_guest') +
                  sex(0, gender, 'overseas_filipino'))
              .toString();
      _styledRow(sheet, row++, totVals, bold: true);
    }

    sexSection('male', '1. Male');
    sexSection('female', '2. Female');

    // ── Footer (2 blank rows gap + standard footer content) ─────────────────
    _writeStandardFooter(sheet, row, 33);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHEET 2 — Country Summary (all establishments combined)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // Header rows 0-6 are plain-text metadata; row 7 = col-headers.

  void _buildCountrySummarySheet(
    Excel excel,
    _MonthData md,
    int totalRoomsAll,
    int year,
    int month,
    int daysInMonth,
  ) {
    final sheet = excel['AE DAE-1B by Country (Sum)'];
    _setupSummaryColumns(sheet);
    int row = 0;

    // ── Header ──────────────────────────────────────────────────────────────
    _hdrCell(sheet, row++, 'DAE-1B(Manual-Summary)');
    _hdrCell(
      sheet,
      row++,
      'Region: __4-A',
      bold: true,
      center: true,
      mergeToCol: 1,
    );
    _hdrCell(
      sheet,
      row++,
      '${kMonthNames[month]}, $year',
      center: true,
      mergeToCol: 1,
    );
    _hdrCell(sheet, row++, ''); // blank row 3
    _hdrCell(
      sheet,
      row++,
      'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS',
      bold: true,
      center: true,
      size: 12,
      mergeToCol: 1,
    );
    _hdrCell(
      sheet,
      row++,
      'All Accommodation Establishments — Combined',
      bold: true,
    );
    _hdrCell(sheet, row++, ''); // blank row 6

    // Row 7 — column headers
    _styledCell(
      sheet,
      row,
      0,
      'COUNTRY OF RESIDENCE',
      bold: true,
      italic: true,
      bgHex: _kLightYellow,
    );
    _styledCell(
      sheet,
      row++,
      1,
      'TOTAL',
      bold: true,
      bgHex: _kLightYellow,
      halign: HorizontalAlign.Center,
    );
    _blankDataRow(sheet, row++, 2);

    // ── Data helpers ────────────────────────────────────────────────────────
    int totCnt(String c) => md.countryByDay[c.toUpperCase()]?[0] ?? 0;
    int totRes(String c) => md.residentsByDay[0]?[c] ?? 0;
    int totCountryAll() =>
        md.countryByDay.values.fold<int>(0, (a, d) => a + (d[0] ?? 0));

    // ── Philippine Residents ─────────────────────────────────────────────────
    _sectionRow(sheet, row++, 'PHILIPPINE RESIDENTS', _kBlue, totalCols: 2);
    _styledRow(sheet, row++, [
      '   FILIPINO NATIONALITY',
      totRes('philippine_resident_filipino').toString(),
    ], italic: true);
    _styledRow(sheet, row++, [
      '   FOREIGN NATIONALITY',
      totRes('philippine_resident_foreign').toString(),
    ], italic: true);
    _styledRow(
      sheet,
      row++,
      [
        'TOTAL PHILIPPINE RESIDENTS',
        (totRes('philippine_resident_filipino') +
                totRes('philippine_resident_foreign'))
            .toString(),
      ],
      bgHex: _kGreen,
      bold: true,
    );

    _blankDataRow(sheet, row++, 2);
    _sectionRow(sheet, row++, 'NON-PHILIPPINE RESIDENTS', _kBlue, totalCols: 2);
    _blankDataRow(sheet, row++, 2);

    // Country rows
    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _sectionRow(sheet, row++, cg.region, _kBlue, totalCols: 2);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _sectionRow(
          sheet,
          row++,
          '   ${cg.subRegion}',
          _kBlue,
          totalCols: 2,
          italic: true,
        );
        lastSubRegion = cg.subRegion;
      }
      _styledRow(
        sheet,
        row++,
        ['       ${cg.country}', totCnt(cg.country).toString()],
        bold: true,
        italic: true,
      );

      final idx = kCountryRows.indexOf(cg);
      final isLast =
          idx == kCountryRows.length - 1 ||
          kCountryRows[idx + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subTotal = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .fold<int>(0, (a, x) => a + totCnt(x.country));
        _styledRow(
          sheet,
          row++,
          ['                 SUB-TOTAL', subTotal.toString()],
          bgHex: _kLightBlue,
          bold: true,
        );
        _blankDataRow(sheet, row++, 2);
      }
    }

    // OTHERS AND UNSPECIFIED (no data) + NON-PHILIPPINE RESIDENCES (data)
    _sectionRow(sheet, row++, 'OTHERS AND UNSPECIFIED', _kBlue, totalCols: 2);
    _styledRow(
      sheet,
      row++,
      ['NON-PHILIPPINE RESIDENCES', totRes('unspecified_guest').toString()],
      bgHex: _kBlue,
      bold: true,
    );

    final int nprTotal = totCountryAll() + totRes('unspecified_guest');
    _styledRow(
      sheet,
      row++,
      ['TOTAL NON-PHILIPPINE RESIDENTS', nprTotal.toString()],
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      ['OVERSEAS FILIPINOS*', totRes('overseas_filipino').toString()],
      bgHex: _kBlue,
      bold: true,
    );

    final int grandTotal =
        totRes('philippine_resident_filipino') +
        totRes('philippine_resident_foreign') +
        nprTotal +
        totRes('overseas_filipino');
    _styledRow(
      sheet,
      row++,
      ['GRAND TOTAL GUEST ARRIVALS', grandTotal.toString()],
      bgHex: _kYellow,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      [
        '   Total Philippine Residents',
        (totRes('philippine_resident_filipino') +
                totRes('philippine_resident_foreign'))
            .toString(),
      ],
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      ['   Total Non-Philippine Residents', nprTotal.toString()],
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      ['   Total Overseas Filipinos', totRes('overseas_filipino').toString()],
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      [
        '   Total Guest with Unspecified Residence',
        totRes('unspecified_guest').toString(),
      ],
      bgHex: _kGreen,
      bold: true,
    );

    // ── Part II ──────────────────────────────────────────────────────────────
    _blankDataRow(sheet, row++, 2);
    _blankDataRow(sheet, row++, 2);
    _styledCell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _sectionRow(sheet, row++, 'A. DAE2:', _kYellow, totalCols: 2, size: 12);

    final sumRoomsOcc = md.roomsOccupied.values.fold<int>(0, (a, b) => a + b);
    final sumRoomsAvail = totalRoomsAll * daysInMonth;
    _styledRow(sheet, row++, ['1. Rooms Occupied', sumRoomsOcc.toString()]);
    _styledRow(sheet, row++, [
      '2. Rooms available for the month',
      sumRoomsAvail.toString(),
    ]);
    _styledRow(sheet, row++, [
      '3. Total Guest nights',
      md.guestNights.toString(),
    ]);

    _blankDataRow(sheet, row++, 2);
    _styledCell(sheet, row++, 0, 'Alternative Submission', bold: true);

    final occRate = sumRoomsAvail > 0
        ? (sumRoomsOcc / sumRoomsAvail * 100).toStringAsFixed(2)
        : '0';
    _styledRow(sheet, row++, ['1. Average Monthly Occupancy Rate', occRate]);

    final als = grandTotal > 0
        ? (md.guestNights / grandTotal).toStringAsFixed(2)
        : '0';
    _styledRow(sheet, row++, ['2. Average Length of Stay (in Nights)', als]);

    _blankDataRow(sheet, row++, 2);
    _sectionRow(sheet, row++, 'B. VOLUME PER SEX', _kYellow, totalCols: 2);

    int totSex(String s, String cat) => md.sexByDay[0]?[s]?[cat] ?? 0;

    void sumSexRows(String gender, String label) {
      _styledCell(sheet, row++, 0, label, bold: true);
      _styledRow(sheet, row++, [
        'a. Philippine Residents',
        (totSex(gender, 'philippine_resident_filipino') +
                totSex(gender, 'philippine_resident_foreign'))
            .toString(),
      ]);
      _styledRow(sheet, row++, [
        'b. Non-Philippine/Foreign Residents (including unspecified)',
        totSex(gender, 'foreign_resident').toString(),
      ]);
      _styledRow(sheet, row++, [
        'c. Overseas Filipinos',
        totSex(gender, 'overseas_filipino').toString(),
      ]);
      _styledRow(sheet, row++, [
        'd. Others/Unspecified Guest',
        totSex(gender, 'unspecified_guest').toString(),
      ]);
      _styledRow(sheet, row++, [
        'x. Total',
        (totSex(gender, 'philippine_resident_filipino') +
                totSex(gender, 'philippine_resident_foreign') +
                totSex(gender, 'foreign_resident') +
                totSex(gender, 'unspecified_guest') +
                totSex(gender, 'overseas_filipino'))
            .toString(),
      ], bold: true);
    }

    sumSexRows('male', '1. Male');
    sumSexRows('female', '2. Female');

    // ── Footer ───────────────────────────────────────────────────────────────
    _writeStandardFooter(sheet, row, 2);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHEET 3 — Monthly Summary (all months, all establishments)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // Header rows 0-6 are plain-text metadata; row 7 = col-headers.

  void _buildMonthlySummarySheet(
    Excel excel,
    List<_MonthData> allMonths,
    int totalRoomsAll,
    int year,
  ) {
    final sheet = excel['AE DAE-1B (Monthly)'];
    _setupMonthlyColumns(sheet);
    int row = 0;

    // ── Header ──────────────────────────────────────────────────────────────
    _hdrCell(sheet, row++, 'DAE-1B(Manual-Summary)');
    _hdrCell(
      sheet,
      row++,
      'Region: __4-A',
      bold: true,
      center: true,
      mergeToCol: 13,
    );
    _hdrCell(sheet, row++, '$year', center: true, mergeToCol: 13);
    _hdrCell(sheet, row++, ''); // blank row 3
    _hdrCell(
      sheet,
      row++,
      'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS',
      bold: true,
      center: true,
      size: 12,
      mergeToCol: 13,
    );
    _hdrCell(
      sheet,
      row++,
      'All Accommodation Establishments — Combined',
      bold: true,
    );
    _hdrCell(sheet, row++, ''); // blank row 6

    // Row 7 — column headers
    _styledCell(
      sheet,
      row,
      0,
      'COUNTRY OF RESIDENCE',
      bold: true,
      italic: true,
      bgHex: _kLightYellow,
    );
    for (int m = 1; m <= 12; m++) {
      _styledCell(
        sheet,
        row,
        m,
        kMonthNames[m],
        bold: true,
        bgHex: _kLightYellow,
        halign: HorizontalAlign.Center,
      );
    }
    _styledCell(
      sheet,
      row++,
      13,
      'TOTAL',
      bold: true,
      bgHex: _kLightYellow,
      halign: HorizontalAlign.Center,
    );
    _blankDataRow(sheet, row++, 14);

    // ── Data helpers ────────────────────────────────────────────────────────
    _MonthData mdFor(int m) =>
        allMonths.firstWhere((x) => x.month == m, orElse: () => _emptyMonth(m));
    int mCnt(String country, int m) =>
        mdFor(m).countryByDay[country.toUpperCase()]?[0] ?? 0;
    int mRes(int m, String cat) => mdFor(m).residentsByDay[0]?[cat] ?? 0;
    int mCountryAll(int m) =>
        mdFor(m).countryByDay.values.fold<int>(0, (a, d) => a + (d[0] ?? 0));

    List<String> monthValues(String label, int Function(int m) fn) {
      final cells = <String>[label];
      int total = 0;
      for (int m = 1; m <= 12; m++) {
        final v = fn(m);
        cells.add(v.toString());
        total += v;
      }
      cells.add(total.toString());
      return cells;
    }

    // ── Philippine Residents ─────────────────────────────────────────────────
    _sectionRow(sheet, row++, 'PHILIPPINE RESIDENTS', _kBlue, totalCols: 14);
    _styledRow(
      sheet,
      row++,
      monthValues(
        '   FILIPINO NATIONALITY',
        (m) => mRes(m, 'philippine_resident_filipino'),
      ),
      italic: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        '   FOREIGN NATIONALITY',
        (m) => mRes(m, 'philippine_resident_foreign'),
      ),
      italic: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        'TOTAL PHILIPPINE RESIDENTS',
        (m) =>
            mRes(m, 'philippine_resident_filipino') +
            mRes(m, 'philippine_resident_foreign'),
      ),
      bgHex: _kGreen,
      bold: true,
    );

    _blankDataRow(sheet, row++, 14);
    _sectionRow(
      sheet,
      row++,
      'NON-PHILIPPINE RESIDENTS',
      _kBlue,
      totalCols: 14,
    );
    _blankDataRow(sheet, row++, 14);

    // Country rows
    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _sectionRow(sheet, row++, cg.region, _kBlue, totalCols: 14);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _sectionRow(
          sheet,
          row++,
          '   ${cg.subRegion}',
          _kBlue,
          totalCols: 14,
          italic: true,
        );
        lastSubRegion = cg.subRegion;
      }
      _styledRow(
        sheet,
        row++,
        monthValues('       ${cg.country}', (m) => mCnt(cg.country, m)),
        bold: true,
        italic: true,
      );

      final idx = kCountryRows.indexOf(cg);
      final isLast =
          idx == kCountryRows.length - 1 ||
          kCountryRows[idx + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subCountries = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .map((x) => x.country)
            .toList();
        _styledRow(
          sheet,
          row++,
          monthValues(
            '                 SUB-TOTAL',
            (m) => subCountries.fold<int>(0, (a, c) => a + mCnt(c, m)),
          ),
          bgHex: _kLightBlue,
          bold: true,
        );
        _blankDataRow(sheet, row++, 14);
      }
    }

    // OTHERS AND UNSPECIFIED (no data) + NON-PHILIPPINE RESIDENCES (data)
    _sectionRow(sheet, row++, 'OTHERS AND UNSPECIFIED', _kBlue, totalCols: 14);
    _styledRow(
      sheet,
      row++,
      monthValues(
        'NON-PHILIPPINE RESIDENCES',
        (m) => mRes(m, 'unspecified_guest'),
      ),
      bgHex: _kBlue,
      bold: true,
    );

    _styledRow(
      sheet,
      row++,
      monthValues(
        'TOTAL NON-PHILIPPINE RESIDENTS',
        (m) => mCountryAll(m) + mRes(m, 'unspecified_guest'),
      ),
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues('OVERSEAS FILIPINOS*', (m) => mRes(m, 'overseas_filipino')),
      bgHex: _kBlue,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        'GRAND TOTAL GUEST ARRIVALS',
        (m) =>
            mRes(m, 'philippine_resident_filipino') +
            mRes(m, 'philippine_resident_foreign') +
            mCountryAll(m) +
            mRes(m, 'unspecified_guest') +
            mRes(m, 'overseas_filipino'),
      ),
      bgHex: _kYellow,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        '   Total Philippine Residents',
        (m) =>
            mRes(m, 'philippine_resident_filipino') +
            mRes(m, 'philippine_resident_foreign'),
      ),
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        '   Total Non-Philippine Residents',
        (m) => mCountryAll(m) + mRes(m, 'unspecified_guest'),
      ),
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        '   Total Overseas Filipinos',
        (m) => mRes(m, 'overseas_filipino'),
      ),
      bgHex: _kGreen,
      bold: true,
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        '   Total Guest with Unspecified Residence',
        (m) => mRes(m, 'unspecified_guest'),
      ),
      bgHex: _kGreen,
      bold: true,
    );

    // ── Part II ──────────────────────────────────────────────────────────────
    _blankDataRow(sheet, row++, 14);
    _blankDataRow(sheet, row++, 14);
    _styledCell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _sectionRow(sheet, row++, 'A. DAE2:', _kYellow, totalCols: 14);

    _styledRow(
      sheet,
      row++,
      monthValues(
        '1. Rooms Occupied',
        (m) => mdFor(m).roomsOccupied.values.fold<int>(0, (a, b) => a + b),
      ),
    );
    _styledRow(
      sheet,
      row++,
      monthValues(
        '2. Rooms available for the month',
        (m) => totalRoomsAll * DateTime(year, m + 1, 0).day,
      ),
    );
    _styledRow(
      sheet,
      row++,
      monthValues('3. Total Guest nights', (m) => mdFor(m).guestNights),
    );

    _blankDataRow(sheet, row++, 14);
    _styledCell(sheet, row++, 0, 'Alternative Submission', bold: true);

    final occCols = <String>['1. Average Monthly Occupancy Rate'];
    int totalOccupied = 0, totalAvailable = 0;
    for (int m = 1; m <= 12; m++) {
      final occ = mdFor(m).roomsOccupied.values.fold<int>(0, (a, b) => a + b);
      final avail = totalRoomsAll * DateTime(year, m + 1, 0).day;
      totalOccupied += occ;
      totalAvailable += avail;
      occCols.add(avail > 0 ? (occ / avail * 100).toStringAsFixed(2) : '0');
    }
    occCols.add(
      totalAvailable > 0
          ? (totalOccupied / totalAvailable * 100).toStringAsFixed(2)
          : '0',
    );
    _styledRow(sheet, row++, occCols);

    final alsCols = <String>['2. Average Length of Stay (in Nights)'];
    int totalGuestNights = 0, totalGuests = 0;
    for (int m = 1; m <= 12; m++) {
      final md2 = mdFor(m);
      final guests =
          mRes(m, 'philippine_resident_filipino') +
          mRes(m, 'philippine_resident_foreign') +
          mCountryAll(m) +
          mRes(m, 'unspecified_guest') +
          mRes(m, 'overseas_filipino');
      totalGuestNights += md2.guestNights;
      totalGuests += guests;
      alsCols.add(
        guests > 0 ? (md2.guestNights / guests).toStringAsFixed(2) : '0',
      );
    }
    alsCols.add(
      totalGuests > 0
          ? (totalGuestNights / totalGuests).toStringAsFixed(2)
          : '0',
    );
    _styledRow(sheet, row++, alsCols);

    _blankDataRow(sheet, row++, 14);
    _sectionRow(sheet, row++, 'B. VOLUME PER SEX', _kYellow, totalCols: 14);

    int mSex(int m, String s, String cat) =>
        mdFor(m).sexByDay[0]?[s]?[cat] ?? 0;

    void mSexSection(String gender, String label) {
      _styledCell(sheet, row++, 0, label, bold: true);
      _styledRow(
        sheet,
        row++,
        monthValues(
          'a. Philippine Residents',
          (m) =>
              mSex(m, gender, 'philippine_resident_filipino') +
              mSex(m, gender, 'philippine_resident_foreign'),
        ),
      );
      _styledRow(
        sheet,
        row++,
        monthValues(
          'b. Non-Philippine/Foreign Residents (including unspecified)',
          (m) => mSex(m, gender, 'foreign_resident'),
        ),
      );
      _styledRow(
        sheet,
        row++,
        monthValues(
          'c. Overseas Filipinos',
          (m) => mSex(m, gender, 'overseas_filipino'),
        ),
      );
      _styledRow(
        sheet,
        row++,
        monthValues(
          'd. Others/Unspecified Guest',
          (m) => mSex(m, gender, 'unspecified_guest'),
        ),
      );
      _styledRow(
        sheet,
        row++,
        monthValues(
          'x. Total',
          (m) =>
              mSex(m, gender, 'philippine_resident_filipino') +
              mSex(m, gender, 'philippine_resident_foreign') +
              mSex(m, gender, 'foreign_resident') +
              mSex(m, gender, 'unspecified_guest') +
              mSex(m, gender, 'overseas_filipino'),
        ),
        bold: true,
      );
    }

    mSexSection('male', '1. Male');
    mSexSection('female', '2. Female');

    // ── Footer ───────────────────────────────────────────────────────────────
    _writeStandardFooter(sheet, row, 14);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLUMN WIDTHS
  // ══════════════════════════════════════════════════════════════════════════

  void _setupDailyColumns(Sheet sheet) {
    sheet.setColumnWidth(0, 45.66);
    for (int i = 1; i <= 31; i++) sheet.setColumnWidth(i, 4.66);
    sheet.setColumnWidth(32, 14.44);
  }

  void _setupSummaryColumns(Sheet sheet) {
    sheet.setColumnWidth(0, 45.66);
    sheet.setColumnWidth(1, 14.44);
  }

  void _setupMonthlyColumns(Sheet sheet) {
    sheet.setColumnWidth(0, 45.66);
    for (int i = 1; i <= 12; i++) sheet.setColumnWidth(i, 9.0);
    sheet.setColumnWidth(13, 14.44);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXCEL STYLE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Writes a single-cell plain-text header row (no borders).
  /// Used exclusively for the metadata header section (rows 0-23 on daily
  /// sheets; rows 0-6 on summary/monthly sheets).
  void _hdrCell(
    Sheet sheet,
    int row,
    String value, {
    bool bold = false,
    bool italic = false,
    bool underline = false,
    bool center = false,
    double size = 10,
    int? mergeToCol,
    int? underlineToCol, // ← new: controls underline width separately
  }) {
    if (mergeToCol != null) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: mergeToCol, rowIndex: row),
      );
    }
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      italic: italic,
      fontFamily: 'Arial',
      fontSize: size.toInt(),
      horizontalAlign: center ? HorizontalAlign.Center : HorizontalAlign.Left,
    );

    // Apply bottom border only across underlineToCol columns
    if (underline) {
      final endCol = underlineToCol ?? 0;
      for (int c = 0; c <= endCol; c++) {
        final borderCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        );
        borderCell.cellStyle = CellStyle(
          bold: c == 0 ? bold : false,
          italic: c == 0 ? italic : false,
          fontFamily: 'Arial',
          fontSize: size.toInt(),
          horizontalAlign: center
              ? HorizontalAlign.Center
              : HorizontalAlign.Left,
          bottomBorder: Border(borderStyle: BorderStyle.Thin),
        );
      }
    }
  }

  /// Writes a single styled cell (no borders). Used for footnote / footer text
  /// and standalone label cells inside the data section.
  void _styledCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
    bool italic = false,
    bool underline = false,
    String? bgHex,
    HorizontalAlign? halign,
    int size = 8,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      italic: italic,
      underline: underline ? Underline.Single : Underline.None,
      fontFamily: 'Arial',
      fontSize: size,
      backgroundColorHex: ExcelColor.fromHexString(bgHex ?? _kWhite),
      horizontalAlign: halign ?? HorizontalAlign.Left,
    );
  }

  /// Writes a full-width blue section-header row (all cells coloured, borders
  /// on every cell, label only in col 0).
  void _sectionRow(
    Sheet sheet,
    int row,
    String label,
    String bgHex, {
    int totalCols = 33,
    bool bold = true,
    bool italic = false,
    int size = 8,
  }) {
    for (int c = 0; c < totalCols; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      if (c == 0) cell.value = TextCellValue(label);
      cell.cellStyle = CellStyle(
        bold: c == 0 ? bold : false,
        italic: c == 0 ? italic : false,
        fontFamily: 'Arial',
        fontSize: size,
        backgroundColorHex: ExcelColor.fromHexString(bgHex),
        leftBorder: _kThinBorder,
        rightBorder: _kThinBorder,
        topBorder: _kThinBorder,
        bottomBorder: _kThinBorder,
      );
    }
  }

  /// Writes a data row.  The first element of [values] is the row label
  /// (col 0); remaining elements are numeric or empty strings for day/month
  /// columns.
  ///
  /// [italic] applies to the label cell (col 0) only — numeric cells are
  /// never italicised.
  void _styledRow(
    Sheet sheet,
    int row,
    List<String> values, {
    bool bold = false,
    String? bgHex,
    bool italic = false,
  }) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      final raw = values[c];

      // ✅ Fixed — try int, then double, then fall back to text
      final intVal = int.tryParse(raw);
      if (intVal != null) {
        cell.value = IntCellValue(intVal);
      } else {
        final doubleVal = double.tryParse(raw);
        if (doubleVal != null) {
          cell.value = DoubleCellValue(doubleVal);
        } else {
          cell.value = TextCellValue(raw);
        }
      }

      cell.cellStyle = CellStyle(
        bold: bold,
        italic: c == 0 ? italic : false,
        fontFamily: 'Arial',
        fontSize: 8,
        backgroundColorHex: ExcelColor.fromHexString(bgHex ?? _kWhite),
        leftBorder: _kThinBorder,
        rightBorder: _kThinBorder,
        topBorder: _kThinBorder,
        bottomBorder: _kThinBorder,
      );
    }
  }

  /// Writes a blank (visually empty) data row with thin borders.
  void _blankDataRow(Sheet sheet, int row, int numCols, {String? bgHex}) {
    for (int c = 0; c < numCols; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      cell.value = TextCellValue('');
      cell.cellStyle = CellStyle(
        fontFamily: 'Arial',
        fontSize: 8,
        backgroundColorHex: ExcelColor.fromHexString(bgHex ?? _kWhite),
      );
    }
  }

  /// Writes the column-header row for daily sheets:
  ///   Col 0 = "COUNTRY OF RESIDENCE" (bold, italic, light-yellow)
  ///   Cols 1-31 = day numbers 1–31
  ///   Col 32 = "TOTAL"
  void _writeDayColHeaders(Sheet sheet, int row) {
    // Col 0 — COUNTRY OF RESIDENCE (bold AND italic per requirements)
    final labelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    labelCell.value = TextCellValue('COUNTRY OF RESIDENCE');
    labelCell.cellStyle = CellStyle(
      bold: true,
      italic: true,
      fontFamily: 'Arial',
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString(_kLightYellow),
      leftBorder: _kThinBorder,
      rightBorder: _kThinBorder,
      topBorder: _kThinBorder,
      bottomBorder: _kThinBorder,
    );

    // Cols 1-31 — day numbers
    for (int d = 1; d <= 31; d++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: d, rowIndex: row),
      );
      cell.value = TextCellValue(d.toString());
      cell.cellStyle = CellStyle(
        bold: true,
        fontFamily: 'Bell MT',
        fontSize: 8,
        backgroundColorHex: ExcelColor.fromHexString(_kLightYellow),
        leftBorder: _kThinBorder,
        rightBorder: _kThinBorder,
        topBorder: _kThinBorder,
        bottomBorder: _kThinBorder,
      );
    }

    // Col 32 — TOTAL
    final totalCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 32, rowIndex: row),
    );
    totalCell.value = TextCellValue('TOTAL');
    totalCell.cellStyle = CellStyle(
      bold: true,
      fontFamily: 'Arial',
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString(_kLightYellow),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: _kThinBorder,
      rightBorder: _kThinBorder,
      topBorder: _kThinBorder,
      bottomBorder: _kThinBorder,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STANDARD FOOTER
  // ══════════════════════════════════════════════════════════════════════════

  /// Writes the standard DOT footer that appears on EVERY sheet type.
  ///
  /// Layout (2 blank rows gap then):
  ///
  ///  * Philippine passport holders permanently residing abroad;
  ///    excludes overseas Filipino workers
  ///  and Former Filipinos                          [Date Submitted: ____]
  ///                                                              (next row)
  ///  Prepared by:  ___________________________     [________________]
  ///                    Signature over Printed Name
  ///
  ///                _____________________________________
  ///                          Position/Designation
  ///
  /// [Right-side content] is placed in the last column (totalCols − 1).
  void _writeStandardFooter(Sheet sheet, int startRow, int totalCols) {
    int row = startRow;
    final lastCol = totalCols - 1;

    // 2 blank rows gap before footer

    // Line 1 — asterisk footnote (long line)
    _styledCell(
      sheet,
      row++,
      0,
      '* Philippine passport holders permanently residing abroad; '
      'excludes overseas Filipino workers',
    );

    // Line 2 — "and Former Filipinos" (col 0)
    _styledCell(sheet, row++, 0, 'and Former Filipinos');

    // Line 3 — Date Submitted in right column only
    _styledCell(sheet, row++, 3, 'Date Submitted:');

    // Line 4 — Prepared by (col 0) + date/signature underline (right col)
    _styledCell(
      sheet,
      row,
      0,
      'Prepared by:        ____________________________________',
    );
    _styledCell(sheet, row++, 3, '________________');

    // Line 5 — Signature over Printed Name label (indented, col 0)
    _styledCell(
      sheet,
      row++,
      0,
      '                           Signature over Printed Name',
    );

    // Line 6 — blank
    row++;

    // Line 7 — Position underline
    _styledCell(
      sheet,
      row++,
      0,
      '                    _____________________________________',
    );

    // Line 8 — Position/Designation label
    _styledCell(
      sheet,
      row,
      0,
      '                              Position/Designation',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATA HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  _MonthData _emptyMonth(int month) => _MonthData(
    month: month,
    countryByDay: {},
    residentsByDay: {},
    sexByDay: {},
    roomsOccupied: {},
    guestNightsByDay: {},
    guestNightsPerArrivalDay: {},
    guestNights: 0,
    roomsAvailable: 0,
  );

  String _sheetTabName(String name) {
    final clean = name.replaceAll(RegExp(r'[\\/*?:\[\]]'), '').trim();
    return clean.length > 31 ? clean.substring(0, 31) : clean;
  }

  String _formatBusinessType(String raw) {
    switch (raw.toLowerCase()) {
      case 'hotel':
        return 'Hotel';
      case 'resort':
        return 'Resort';
      case 'motel':
        return 'Motel';
      case 'pension_inn':
        return 'Pension Inn/ Lodge';
      case 'youth_hostel':
        return 'Youth Hostel/ Dormitory';
      case 'apartment':
        return 'Apartel/ Rented Homes/ Apartment';
      case 'others':
        return 'Others';
      default:
        return raw;
    }
  }

  String _displayBusinessLine(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map(_formatBusinessType)
          .join(', ');
    }
    if (value is String) {
      final parts = value
          .split(RegExp(r'[,|\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length > 1) return parts.map(_formatBusinessType).join(', ');
      return _formatBusinessType(value);
    }
    return '';
  }

  /// Extracts raw lowercase business-line keys for checkbox matching.
  /// Handles both List<String> (from Postgres array) and comma-delimited
  /// String values.
  List<String> _extractRawBusinessLines(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[,|\n]'))
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  String _normalizeUpper(Object? v) => v?.toString().trim().toUpperCase() ?? '';
  String _normalizeLower(Object? v) => v?.toString().trim().toLowerCase() ?? '';

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  bool _asBool(Object? v) {
    if (v is bool) return v;
    final n = v?.toString().trim().toLowerCase();
    return n == 'true' || n == 't' || n == '1' || n == 'yes';
  }

  String _classifyResidenceBucket({
    required String country,
    required String nationality,
    required bool isOverseas,
  }) {
    if (isOverseas) return 'overseas_filipino';
    if (country.isEmpty || country == 'OTHERS') return 'unspecified_guest';
    if (country == 'PHILIPPINES') {
      if (nationality == 'FILIPINO') return 'philippine_resident_filipino';
      if (nationality == 'FOREIGN') return 'philippine_resident_foreign';
      return 'unspecified_guest';
    }
    return 'foreign_resident';
  }
}
