// ignore_for_file: deprecated_member_use

// admin_report_api.dart
// DAE-1B Excel Report Generator
//
// Generates ONE Excel file per report run covering ALL approved businesses.
//
// Sheet layout (controlled by ReportSheetOptions):
//   • Daily sheets  — one tab per business, named after the business, for the selected month
//   • Country Summary — one tab aggregating ALL businesses for the selected month
//   • Monthly Summary — one tab with all 12 months of the year, ALL businesses aggregated
//
// Dependencies (pubspec.yaml):
//   supabase_flutter: ^2.x
//   excel: ^4.x

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Country Taxonomy — mirrors DAE-1B row structure exactly ─────────────────

class _CountryGroup {
  final String region;
  final String subRegion;
  final String country;
  const _CountryGroup(this.region, this.subRegion, this.country);
}

const List<_CountryGroup> kCountryRows = [
  // ── ASIA / ASEAN ────────────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'ASEAN', 'BRUNEI'),
  _CountryGroup('ASIA', 'ASEAN', 'CAMBODIA'),
  _CountryGroup('ASIA', 'ASEAN', 'INDONESIA'),
  _CountryGroup('ASIA', 'ASEAN', 'LAOS'),
  _CountryGroup('ASIA', 'ASEAN', 'MALAYSIA'),
  _CountryGroup('ASIA', 'ASEAN', 'MYANMAR'),
  _CountryGroup('ASIA', 'ASEAN', 'SINGAPORE'),
  _CountryGroup('ASIA', 'ASEAN', 'THAILAND'),
  _CountryGroup('ASIA', 'ASEAN', 'VIETNAM'),
  // ── ASIA / EAST ASIA ────────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'EAST ASIA', 'CHINA'),
  _CountryGroup('ASIA', 'EAST ASIA', 'HONGKONG'),
  _CountryGroup('ASIA', 'EAST ASIA', 'JAPAN'),
  _CountryGroup('ASIA', 'EAST ASIA', 'KOREA'),
  _CountryGroup('ASIA', 'EAST ASIA', 'TAIWAN'),
  // ── ASIA / SOUTH ASIA ───────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'SOUTH ASIA', 'BANGLADESH'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'INDIA'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'IRAN'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'NEPAL'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'PAKISTAN'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'SRI LANKA'),
  // ── ASIA / MIDDLE EAST ──────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'MIDDLE EAST', 'BAHRAIN'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'EGYPT'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'ISRAEL'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'JORDAN'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'KUWAIT'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'SAUDI ARABIA'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'UNITED ARAB EMIRATES'),
  // ── AMERICA / NORTH AMERICA ─────────────────────────────────────────────────
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'CANADA'),
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'MEXICO'),
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'USA'),
  // ── AMERICA / SOUTH AMERICA ─────────────────────────────────────────────────
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'ARGENTINA'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'BRAZIL'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'COLOMBIA'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'PERU'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'VENEZUELA'),
  // ── EUROPE / WESTERN EUROPE ─────────────────────────────────────────────────
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'AUSTRIA'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'BELGIUM'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'FRANCE'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'GERMANY'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'LUXEMBOURG'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'NETHERLANDS'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'SWITZERLAND'),
  // ── EUROPE / NORTHERN EUROPE ────────────────────────────────────────────────
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'DENMARK'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'FINLAND'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'IRELAND'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'NORWAY'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'SWEDEN'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'UNITED KINGDOM'),
  // ── EUROPE / SOUTHERN EUROPE ────────────────────────────────────────────────
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'GREECE'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'ITALY'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'PORTUGAL'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'SPAIN'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'UNION OF SERBIA AND MONTENEGRO'),
  // ── EUROPE / EASTERN EUROPE ─────────────────────────────────────────────────
  _CountryGroup(
    'EUROPE',
    'EASTERN EUROPE',
    'COMMONWEALTH OF INDEPENDENT STATES',
  ),
  _CountryGroup('EUROPE', 'EASTERN EUROPE', 'POLAND'),
  _CountryGroup('EUROPE', 'EASTERN EUROPE', 'RUSSIA'),
  // ── AUSTRALASIA/PACIFIC ─────────────────────────────────────────────────────
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'AUSTRALIA'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'GUAM'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'NAURU'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'NEW ZEALAND'),
  _CountryGroup(
    'AUSTRALASIA/PACIFIC',
    'AUSTRALASIA/PACIFIC',
    'PAPUA NEW GUINEA',
  ),
  // ── AFRICA ──────────────────────────────────────────────────────────────────
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

// ─── Public Models ────────────────────────────────────────────────────────────

/// Controls which sheets are included in the generated workbook.
class ReportSheetOptions {
  /// Sheet 1 — one daily-breakdown tab per accommodation for the selected month.
  final bool includeDailySheet;

  /// Sheet 2 — a single "Country Summary" tab aggregating ALL accommodations.
  final bool includeCountrySumSheet;

  /// Sheet 3 — a single "Monthly Summary" tab with all 12 months of the year.
  final bool includeMonthlySummarySheet;

  const ReportSheetOptions({
    this.includeDailySheet = true,
    this.includeCountrySumSheet = true,
    this.includeMonthlySummarySheet = true,
  });
}

/// Parameters passed to [ReportService.generateAndUpload].
class ReportParams {
  /// The single month selected by the admin (1–12).
  final int month;
  final int year;
  final ReportSheetOptions sheetOptions;

  const ReportParams({
    required this.month,
    required this.year,
    required this.sheetOptions,
  }) : assert(month >= 1 && month <= 12, 'month must be 1–12');
}

// ─── Internal Models ──────────────────────────────────────────────────────────

class _BusinessInfo {
  final String id;
  final String name;
  final String businessType;
  final String region;
  final String cityMunicipality;
  final String province;
  final int totalRooms;

  const _BusinessInfo({
    required this.id,
    required this.name,
    required this.businessType,
    required this.region,
    required this.cityMunicipality,
    required this.province,
    required this.totalRooms,
  });
}

/// country → { day → count }.  day = 0 means "running total across all days".
typedef _DayCountMap = Map<String, Map<int, int>>;

class _MonthData {
  final int month;

  /// Non-Philippine residents: country → { day → count }
  final _DayCountMap countryByDay;

  /// day → { resident_bucket → count }
  final Map<int, Map<String, int>> residentsByDay;

  /// day → { sex → { resident_bucket → count } }
  final Map<int, Map<String, Map<String, int>>> sexByDay;

  /// day → rooms_occupied
  final Map<int, int> roomsOccupied;

  /// Total guest-nights for the month (sum of check_out – check_in).
  final int guestNights;

  /// Populated per-sheet using business.totalRooms × daysInMonth.
  final int roomsAvailable;

  const _MonthData({
    required this.month,
    required this.countryByDay,
    required this.residentsByDay,
    required this.sexByDay,
    required this.roomsOccupied,
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

  // ── PUBLIC ENTRY POINT ────────────────────────────────────────────────────

  /// Generates ONE Excel workbook for ALL approved businesses, uploads it to
  /// Supabase Storage, logs a row in the [reports] table, and returns the URL.
  Future<String> generateAndUpload(ReportParams params) async {
    // 1. Fetch every approved accommodation.
    final businesses = await _fetchAllBusinesses();
    if (businesses.isEmpty) {
      throw Exception('No approved businesses found. Cannot generate report.');
    }

    // 2. Fetch the selected month's data for each business.
    final List<_MonthData> selectedMonthPerBiz = await Future.wait(
      businesses.map((b) => _fetchMonthData(b.id, params.month, params.year)),
    );

    // 3. If Monthly Summary is needed, fetch all 12 months (reuse already-fetched month).
    List<_MonthData>? allTwelveMonthsMerged;
    if (params.sheetOptions.includeMonthlySummarySheet) {
      allTwelveMonthsMerged = [];
      for (int m = 1; m <= 12; m++) {
        if (m == params.month) {
          // Reuse what we already fetched.
          allTwelveMonthsMerged.add(_mergeMonthData(m, selectedMonthPerBiz));
        } else {
          final perBiz = await Future.wait(
            businesses.map((b) => _fetchMonthData(b.id, m, params.year)),
          );
          allTwelveMonthsMerged.add(_mergeMonthData(m, perBiz));
        }
      }
    }

    // 4. Build the workbook bytes.
    final totalRoomsAll = businesses.fold<int>(
      0,
      (sum, b) => sum + b.totalRooms,
    );

    final bytes = _buildWorkbook(
      businesses: businesses,
      selectedMonthPerBiz: selectedMonthPerBiz,
      allTwelveMonthsMerged: allTwelveMonthsMerged,
      totalRoomsAll: totalRoomsAll,
      params: params,
    );

    // 5. Upload to Supabase Storage.
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

    // 6. Log ONE row to the reports table.
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

    return fileUrl;
  }

  // ── DATA FETCHING ─────────────────────────────────────────────────────────

  Future<List<_BusinessInfo>> _fetchAllBusinesses() async {
    final rows = await _sb
        .from('businesses')
        .select(
          'id, business_name, business_type, region, city_municipality, province, total_rooms',
        )
        .eq('status', 'approved')
        .order('business_name');

    return (rows as List)
        .map(
          (r) => _BusinessInfo(
            id: r['id'] as String,
            name: r['business_name'] as String? ?? 'Unknown',
            businessType: r['business_type'] as String? ?? '',
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

    final Map<String, int> recordDay = {};
    int totalGuestNights = 0;

    final _DayCountMap countryByDay = {};
    final Map<int, Map<String, int>> residentsByDay = {};
    final Map<int, Map<String, Map<String, int>>> sexByDay = {};
    final Map<int, int> roomsOccupiedByDay = {};

    for (final r in records) {
      final checkIn = DateTime.parse(r['check_in']);
      final checkOut = DateTime.parse(r['check_out']);
      final nights = checkOut.difference(checkIn).inDays;
      final rooms = r['rooms_occupied'] as int? ?? 0;

      recordDay[r['id']] = checkIn.day;

      // Only count valid stays
      if (nights > 0) {
        totalGuestNights += nights;

        // Spread rooms occupied across each night of the stay
        for (int n = 0; n < nights; n++) {
          final stayDay = checkIn.add(Duration(days: n)).day;
          roomsOccupiedByDay[stayDay] =
              (roomsOccupiedByDay[stayDay] ?? 0) + rooms;
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

      // Foreign residents: store per-day + total (day 0).
      if (bucket == 'foreign_resident' && country.isNotEmpty) {
        countryByDay.putIfAbsent(country, () => {});
        countryByDay[country]![day] =
            (countryByDay[country]![day] ?? 0) + count;
        countryByDay[country]![0] = (countryByDay[country]![0] ?? 0) + count;
      }

      // All buckets go into residentsByDay (day 0 = total).
      residentsByDay.putIfAbsent(day, () => {});
      residentsByDay[day]![bucket] =
          (residentsByDay[day]![bucket] ?? 0) + count;
      residentsByDay[0] ??= {};
      residentsByDay[0]![bucket] = (residentsByDay[0]![bucket] ?? 0) + count;

      // Sex breakdown (day 0 = total).
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
      guestNights: totalGuestNights,
      roomsAvailable: 0,
    );
  }

  // ── MERGE ─────────────────────────────────────────────────────────────────

  /// Sums multiple [_MonthData] objects (one per business) into one aggregate.
  _MonthData _mergeMonthData(int month, List<_MonthData> list) {
    final _DayCountMap countryByDay = {};
    final Map<int, Map<String, int>> residentsByDay = {};
    final Map<int, Map<String, Map<String, int>>> sexByDay = {};
    final Map<int, int> roomsOccupied = {};
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

      guestNights += md.guestNights;
    }

    return _MonthData(
      month: month,
      countryByDay: countryByDay,
      residentsByDay: residentsByDay,
      sexByDay: sexByDay,
      roomsOccupied: roomsOccupied,
      guestNights: guestNights,
      roomsAvailable: 0,
    );
  }

  // ── WORKBOOK BUILDER ──────────────────────────────────────────────────────

  Uint8List _buildWorkbook({
    required List<_BusinessInfo> businesses,
    required List<_MonthData> selectedMonthPerBiz,
    required List<_MonthData>? allTwelveMonthsMerged,
    required int totalRoomsAll,
    required ReportParams params,
  }) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final daysInMonth = DateTime(params.year, params.month + 1, 0).day;
    final opts = params.sheetOptions;

    // ── Daily sheets — one tab per business ───────────────────────────────
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

    // ── Country Summary — one tab, all businesses merged ──────────────────
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

    // ── Monthly Summary — all 12 months, all businesses ───────────────────
    if (opts.includeMonthlySummarySheet && allTwelveMonthsMerged != null) {
      _buildMonthlySummarySheet(
        excel,
        allTwelveMonthsMerged,
        totalRoomsAll,
        params.year,
      );
    }

    return Uint8List.fromList(excel.encode()!);
  }

  // ── SHEET: Daily (per business, selected month) ───────────────────────────

  void _buildDailySheet(
    Excel excel,
    _BusinessInfo biz,
    _MonthData md,
    int year,
    int daysInMonth,
  ) {
    final sheet = excel[_sheetTabName(biz.name)];
    int row = 0;

    // Header block
    _cell(sheet, row++, 0, 'DAE-1B (Manual)');
    _cell(sheet, row++, 0, 'Region: ${biz.region}');
    _cell(sheet, row++, 0, '${kMonthNames[md.month]}, $year');
    _cell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS');
    _cell(sheet, row++, 0, 'Establishment: ${biz.name}');
    _cell(
      sheet,
      row++,
      0,
      'Type of Accommodation: ${_formatBusinessType(biz.businessType)}',
    );
    _cell(sheet, row++, 0, 'City/Municipality: ${biz.cityMunicipality}');
    _cell(sheet, row++, 0, 'Province: ${biz.province}');
    row++;

    // Column headers: COUNTRY OF RESIDENCE | 1..31 | TOTAL
    final headers = <String>['COUNTRY OF RESIDENCE'];
    for (int d = 1; d <= 31; d++) headers.add(d.toString());
    headers.add('TOTAL');
    _row(sheet, row++, headers, bold: true);

    // Helpers
    int cnt(String country, int day) =>
        md.countryByDay[country.toUpperCase()]?[day] ?? 0;

    int countryTotal(int day) => md.countryByDay.values.fold<int>(
      0,
      (sum, days) => sum + (days[day] ?? 0),
    );

    int res(int day, String cat) => md.residentsByDay[day]?[cat] ?? 0;

    void dataRow(String label, List<int> Function(int day) dayFn) {
      final cells = <String>[label];
      int total = 0;
      for (int d = 1; d <= 31; d++) {
        if (d <= daysInMonth) {
          final v = dayFn(d).fold<int>(0, (a, b) => a + b);
          cells.add(v == 0 ? '' : v.toString());
          total += v;
        } else {
          cells.add('');
        }
      }
      cells.add(total.toString());
      _row(sheet, row++, cells);
    }

    // ── Philippine Residents
    _cell(sheet, row++, 0, 'PHILIPPINE RESIDENTS', bold: true);
    dataRow(
      '   FILIPINO NATIONALITY',
      (d) => [res(d, 'philippine_resident_filipino')],
    );
    dataRow(
      '   FOREIGN NATIONALITY',
      (d) => [res(d, 'philippine_resident_foreign')],
    );

    final prCells = <String>['TOTAL PHILIPPINE RESIDENTS'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v =
            res(d, 'philippine_resident_filipino') +
            res(d, 'philippine_resident_foreign');
        prCells.add(v == 0 ? '0' : v.toString());
      } else {
        prCells.add('0');
      }
    }
    prCells.add(
      (res(0, 'philippine_resident_filipino') +
              res(0, 'philippine_resident_foreign'))
          .toString(),
    );
    _row(sheet, row++, prCells, bold: true);

    row++;
    _cell(sheet, row++, 0, 'NON-PHILIPPINE RESIDENTS', bold: true);
    row++;

    // ── Country rows by region / sub-region
    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _cell(sheet, row++, 0, cg.region, bold: true);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _cell(sheet, row++, 0, '   ${cg.subRegion}', bold: true);
        lastSubRegion = cg.subRegion;
      }
      dataRow('       ${cg.country}', (d) => [cnt(cg.country, d)]);

      final isLast =
          kCountryRows.indexOf(cg) == kCountryRows.length - 1 ||
          kCountryRows[kCountryRows.indexOf(cg) + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subCols = <String>['                 SUB-TOTAL'];
        int subTotal = 0;
        final countries = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .map((x) => x.country)
            .toList();
        for (int d = 1; d <= 31; d++) {
          if (d <= daysInMonth) {
            final v = countries.fold<int>(0, (a, c) => a + cnt(c, d));
            subCols.add(v == 0 ? '0' : v.toString());
            subTotal += v;
          } else {
            subCols.add('0');
          }
        }
        subCols.add(subTotal.toString());
        _row(sheet, row++, subCols, bold: true);
        row++;
      }
    }

    // ── Others, totals, grand total
    dataRow(
      'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES',
      (d) => [res(d, 'unspecified_guest')],
    );

    final nprCols = <String>['TOTAL NON-PHILIPPINE RESIDENTS'];
    int nprTotal = 0;
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v = countryTotal(d) + res(d, 'unspecified_guest');
        nprCols.add(v == 0 ? '0' : v.toString());
        nprTotal += v;
      } else {
        nprCols.add('0');
      }
    }
    nprCols.add(nprTotal.toString());
    _row(sheet, row++, nprCols, bold: true);

    dataRow('OVERSEAS FILIPINOS*', (d) => [res(d, 'overseas_filipino')]);

    final gtCols = <String>['GRAND TOTAL GUEST ARRIVALS'];
    int gtTotal = 0;
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v =
            res(d, 'philippine_resident_filipino') +
            res(d, 'philippine_resident_foreign') +
            countryTotal(d) +
            res(d, 'unspecified_guest') +
            res(d, 'overseas_filipino');
        gtCols.add(v == 0 ? '0' : v.toString());
        gtTotal += v;
      } else {
        gtCols.add('0');
      }
    }
    gtCols.add(gtTotal.toString());
    _row(sheet, row++, gtCols, bold: true);

    // Summary sub-rows
    void summaryRow(String label, int Function(int day) fn) {
      final cols = <String>[label];
      for (int d = 1; d <= 31; d++) {
        if (d <= daysInMonth) {
          final v = fn(d);
          cols.add(v == 0 ? '0' : v.toString());
        } else {
          cols.add('0');
        }
      }
      cols.add(fn(0).toString());
      _row(sheet, row++, cols);
    }

    summaryRow(
      '   Total Philippine Residents',
      (d) =>
          res(d, 'philippine_resident_filipino') +
          res(d, 'philippine_resident_foreign'),
    );
    summaryRow(
      '   Total Non-Philippine Residents',
      (d) => countryTotal(d) + res(d, 'unspecified_guest'),
    );
    summaryRow(
      '   Total Overseas Filipinos',
      (d) => res(d, 'overseas_filipino'),
    );

    row += 2;

    // ── PART II
    _cell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _cell(sheet, row++, 0, 'A. DAE2:');

    final roomCols = <String>['1. Rooms Occupied'];
    int totalRoomsOcc = 0;
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v = md.roomsOccupied[d] ?? 0;
        roomCols.add(v == 0 ? '' : v.toString());
        totalRoomsOcc += v;
      } else {
        roomCols.add('');
      }
    }
    roomCols.add(totalRoomsOcc.toString());
    _row(sheet, row++, roomCols);

    final availCols = <String>['2. Rooms available for the month'];
    for (int d = 1; d <= 31; d++) {
      availCols.add(d <= daysInMonth ? biz.totalRooms.toString() : '');
    }
    availCols.add((biz.totalRooms * daysInMonth).toString());
    _row(sheet, row++, availCols);

    final gnCols = <String>['3. Total Guest nights'];
    for (int d = 1; d <= 31; d++) gnCols.add('');
    gnCols.add(md.guestNights.toString());
    _row(sheet, row++, gnCols);

    row++;
    _cell(sheet, row++, 0, 'Alternative Submission');

    final occCols = <String>['1. Average Monthly Occupancy Rate'];
    for (int d = 1; d <= 31; d++) occCols.add('');
    final roomsAvail = biz.totalRooms * daysInMonth;
    occCols.add(
      roomsAvail > 0
          ? '${(totalRoomsOcc / roomsAvail * 100).toStringAsFixed(2)}%'
          : '0%',
    );
    _row(sheet, row++, occCols);

    final alsCols = <String>['2. Average Length of Stay (in Nights)'];
    for (int d = 1; d <= 31; d++) alsCols.add('');
    alsCols.add(
      gtTotal > 0 ? (md.guestNights / gtTotal).toStringAsFixed(2) : '0',
    );
    _row(sheet, row++, alsCols);

    row++;
    _cell(sheet, row++, 0, 'B. VOLUME PER SEX', bold: true);

    int sex(int day, String s, String cat) => md.sexByDay[day]?[s]?[cat] ?? 0;

    void sexRow(String label, String s, String cat) {
      final cols = <String>[label];
      for (int d = 1; d <= 31; d++) {
        if (d <= daysInMonth) {
          final v = sex(d, s, cat);
          cols.add(v == 0 ? '' : v.toString());
        } else {
          cols.add('');
        }
      }
      cols.add(sex(0, s, cat).toString());
      _row(sheet, row++, cols);
    }

    _cell(sheet, row++, 0, '1. Male');
    sexRow('a. Philippine Residents', 'male', 'philippine_resident_filipino');
    sexRow(
      'b. Non-Philippine/Foreign Residents (including unspecified)',
      'male',
      'foreign_resident',
    );
    sexRow('c. Overseas Filipinos', 'male', 'overseas_filipino');
    sexRow('d. Others/Unspecified Guest', 'male', 'unspecified_guest');

    final maleTotCols = <String>['x. Total'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v =
            sex(d, 'male', 'philippine_resident_filipino') +
            sex(d, 'male', 'philippine_resident_foreign') +
            sex(d, 'male', 'foreign_resident') +
            sex(d, 'male', 'unspecified_guest') +
            sex(d, 'male', 'overseas_filipino');
        maleTotCols.add(v == 0 ? '' : v.toString());
      } else {
        maleTotCols.add('');
      }
    }
    maleTotCols.add(
      (sex(0, 'male', 'philippine_resident_filipino') +
              sex(0, 'male', 'philippine_resident_foreign') +
              sex(0, 'male', 'foreign_resident') +
              sex(0, 'male', 'unspecified_guest') +
              sex(0, 'male', 'overseas_filipino'))
          .toString(),
    );
    _row(sheet, row++, maleTotCols, bold: true);

    _cell(sheet, row++, 0, '2. Female');
    sexRow('a. Philippine Residents', 'female', 'philippine_resident_filipino');
    sexRow(
      'b. Non-Philippine/Foreign Residents (including unspecified)',
      'female',
      'foreign_resident',
    );
    sexRow('c. Overseas Filipinos', 'female', 'overseas_filipino');
    sexRow('d. Others/Unspecified Guest', 'female', 'unspecified_guest');

    final femaleTotCols = <String>['x. Total'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v =
            sex(d, 'female', 'philippine_resident_filipino') +
            sex(d, 'female', 'philippine_resident_foreign') +
            sex(d, 'female', 'foreign_resident') +
            sex(d, 'female', 'unspecified_guest') +
            sex(d, 'female', 'overseas_filipino');
        femaleTotCols.add(v == 0 ? '' : v.toString());
      } else {
        femaleTotCols.add('');
      }
    }
    femaleTotCols.add(
      (sex(0, 'female', 'philippine_resident_filipino') +
              sex(0, 'female', 'philippine_resident_foreign') +
              sex(0, 'female', 'foreign_resident') +
              sex(0, 'female', 'unspecified_guest') +
              sex(0, 'female', 'overseas_filipino'))
          .toString(),
    );
    _row(sheet, row++, femaleTotCols, bold: true);

    row += 2;
    _cell(
      sheet,
      row++,
      0,
      '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos',
    );
    row++;
    _cell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ── SHEET: Country Summary (all businesses merged, selected month) ─────────

  void _buildCountrySummarySheet(
    Excel excel,
    _MonthData md, // already merged across all businesses
    int totalRoomsAll,
    int year,
    int month,
    int daysInMonth,
  ) {
    final sheet = excel['Country Summary'];
    int row = 0;

    _cell(sheet, row++, 0, 'DAE-1B (Manual-Summary)');
    _cell(sheet, row++, 0, '${kMonthNames[month]}, $year');
    _cell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS');
    _cell(sheet, row++, 0, 'All Accommodation Establishments — Combined');
    row++;

    _row(sheet, row++, ['COUNTRY OF RESIDENCE', 'TOTAL'], bold: true);

    int totCnt(String country) =>
        md.countryByDay[country.toUpperCase()]?[0] ?? 0;
    int totRes(String cat) => md.residentsByDay[0]?[cat] ?? 0;
    int totCountryAll() =>
        md.countryByDay.values.fold<int>(0, (a, days) => a + (days[0] ?? 0));

    _cell(sheet, row++, 0, 'PHILIPPINE RESIDENTS', bold: true);
    _row(sheet, row++, [
      '   FILIPINO NATIONALITY',
      totRes('philippine_resident_filipino').toString(),
    ]);
    _row(sheet, row++, [
      '   FOREIGN NATIONALITY',
      totRes('philippine_resident_foreign').toString(),
    ]);
    _row(sheet, row++, [
      'TOTAL PHILIPPINE RESIDENTS',
      (totRes('philippine_resident_filipino') +
              totRes('philippine_resident_foreign'))
          .toString(),
    ], bold: true);

    row++;
    _cell(sheet, row++, 0, 'NON-PHILIPPINE RESIDENTS', bold: true);
    row++;

    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _cell(sheet, row++, 0, cg.region, bold: true);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _cell(sheet, row++, 0, '   ${cg.subRegion}', bold: true);
        lastSubRegion = cg.subRegion;
      }
      _row(sheet, row++, [
        '       ${cg.country}',
        totCnt(cg.country).toString(),
      ]);

      final isLast =
          kCountryRows.indexOf(cg) == kCountryRows.length - 1 ||
          kCountryRows[kCountryRows.indexOf(cg) + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subTotal = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .fold<int>(0, (a, x) => a + totCnt(x.country));
        _row(sheet, row++, [
          '                 SUB-TOTAL',
          subTotal.toString(),
        ], bold: true);
        row++;
      }
    }

    _row(sheet, row++, [
      'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES',
      totRes('unspecified_guest').toString(),
    ]);

    final nprTotal = totCountryAll() + totRes('unspecified_guest');
    _row(sheet, row++, [
      'TOTAL NON-PHILIPPINE RESIDENTS',
      nprTotal.toString(),
    ], bold: true);
    _row(sheet, row++, [
      'OVERSEAS FILIPINOS*',
      totRes('overseas_filipino').toString(),
    ]);

    final grandTotal =
        totRes('philippine_resident_filipino') +
        totRes('philippine_resident_foreign') +
        nprTotal +
        totRes('overseas_filipino');
    _row(sheet, row++, [
      'GRAND TOTAL GUEST ARRIVALS',
      grandTotal.toString(),
    ], bold: true);

    row += 2;
    _cell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _cell(sheet, row++, 0, 'A. DAE2:');

    final sumRoomsOcc = md.roomsOccupied.values.fold<int>(0, (a, b) => a + b);
    final sumRoomsAvail = totalRoomsAll * daysInMonth;

    _row(sheet, row++, ['1. Rooms Occupied', sumRoomsOcc.toString()]);
    _row(sheet, row++, [
      '2. Rooms available for the month',
      sumRoomsAvail.toString(),
    ]);
    _row(sheet, row++, ['3. Total Guest nights', md.guestNights.toString()]);
    row++;
    _cell(sheet, row++, 0, 'Alternative Submission');

    final occRate = sumRoomsAvail > 0
        ? '${(sumRoomsOcc / sumRoomsAvail * 100).toStringAsFixed(2)}%'
        : '0%';
    _row(sheet, row++, ['1. Average Monthly Occupancy Rate', occRate]);

    final als = grandTotal > 0
        ? (md.guestNights / grandTotal).toStringAsFixed(2)
        : '0';
    _row(sheet, row++, ['2. Average Length of Stay (in Nights)', als]);

    row++;
    _cell(sheet, row++, 0, 'B. VOLUME PER SEX', bold: true);

    int totSex(String s, String cat) => md.sexByDay[0]?[s]?[cat] ?? 0;

    _cell(sheet, row++, 0, '1. Male');
    _row(sheet, row++, [
      'a. Philippine Residents',
      totSex('male', 'philippine_resident_filipino').toString(),
    ]);
    _row(sheet, row++, [
      'b. Non-Philippine/Foreign Residents (including unspecified)',
      totSex('male', 'foreign_resident').toString(),
    ]);
    _row(sheet, row++, [
      'c. Overseas Filipinos',
      totSex('male', 'overseas_filipino').toString(),
    ]);
    _row(sheet, row++, [
      'd. Others/Unspecified Guest',
      totSex('male', 'unspecified_guest').toString(),
    ]);
    _row(sheet, row++, [
      'x. Total',
      (totSex('male', 'philippine_resident_filipino') +
              totSex('male', 'philippine_resident_foreign') +
              totSex('male', 'foreign_resident') +
              totSex('male', 'unspecified_guest') +
              totSex('male', 'overseas_filipino'))
          .toString(),
    ], bold: true);

    _cell(sheet, row++, 0, '2. Female');
    _row(sheet, row++, [
      'a. Philippine Residents',
      totSex('female', 'philippine_resident_filipino').toString(),
    ]);
    _row(sheet, row++, [
      'b. Non-Philippine/Foreign Residents (including unspecified)',
      totSex('female', 'foreign_resident').toString(),
    ]);
    _row(sheet, row++, [
      'c. Overseas Filipinos',
      totSex('female', 'overseas_filipino').toString(),
    ]);
    _row(sheet, row++, [
      'd. Others/Unspecified Guest',
      totSex('female', 'unspecified_guest').toString(),
    ]);
    _row(sheet, row++, [
      'x. Total',
      (totSex('female', 'philippine_resident_filipino') +
              totSex('female', 'philippine_resident_foreign') +
              totSex('female', 'foreign_resident') +
              totSex('female', 'unspecified_guest') +
              totSex('female', 'overseas_filipino'))
          .toString(),
    ], bold: true);

    row += 2;
    _cell(
      sheet,
      row++,
      0,
      '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos',
    );
    row++;
    _cell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ── SHEET: Monthly Summary (all 12 months, all businesses merged) ──────────

  void _buildMonthlySummarySheet(
    Excel excel,
    List<_MonthData> allMonths, // one entry per month 1–12
    int totalRoomsAll,
    int year,
  ) {
    final sheet = excel['Monthly Summary'];
    int row = 0;

    _cell(sheet, row++, 0, 'DAE-1B (Manual-Summary)');
    _cell(sheet, row++, 0, '$year');
    _cell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS');
    _cell(sheet, row++, 0, 'All Accommodation Establishments — Combined');
    row++;

    // Column headers: COUNTRY OF RESIDENCE | JAN..DEC | TOTAL
    final headers = <String>['COUNTRY OF RESIDENCE'];
    for (int m = 1; m <= 12; m++) headers.add(kMonthNames[m]);
    headers.add('TOTAL');
    _row(sheet, row++, headers, bold: true);

    // Helpers
    _MonthData mdFor(int month) => allMonths.firstWhere(
      (m) => m.month == month,
      orElse: () => _emptyMonth(month),
    );

    int mCnt(String country, int month) =>
        mdFor(month).countryByDay[country.toUpperCase()]?[0] ?? 0;

    int mRes(int month, String cat) =>
        mdFor(month).residentsByDay[0]?[cat] ?? 0;

    int mCountryAll(int month) => mdFor(
      month,
    ).countryByDay.values.fold<int>(0, (a, days) => a + (days[0] ?? 0));

    void dataRow(String label, int Function(int month) fn) {
      final cols = <String>[label];
      int total = 0;
      for (int m = 1; m <= 12; m++) {
        final v = fn(m);
        cols.add(v == 0 ? '' : v.toString());
        total += v;
      }
      cols.add(total.toString());
      _row(sheet, row++, cols);
    }

    // ── Philippine Residents
    _cell(sheet, row++, 0, 'PHILIPPINE RESIDENTS', bold: true);
    dataRow(
      '   FILIPINO NATIONALITY',
      (m) => mRes(m, 'philippine_resident_filipino'),
    );
    dataRow(
      '   FOREIGN NATIONALITY',
      (m) => mRes(m, 'philippine_resident_foreign'),
    );

    final prCols = <String>['TOTAL PHILIPPINE RESIDENTS'];
    int prGrand = 0;
    for (int m = 1; m <= 12; m++) {
      final v =
          mRes(m, 'philippine_resident_filipino') +
          mRes(m, 'philippine_resident_foreign');
      prCols.add(v == 0 ? '' : v.toString());
      prGrand += v;
    }
    prCols.add(prGrand.toString());
    _row(sheet, row++, prCols, bold: true);

    row++;
    _cell(sheet, row++, 0, 'NON-PHILIPPINE RESIDENTS', bold: true);
    row++;

    // ── Country rows
    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _cell(sheet, row++, 0, cg.region, bold: true);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _cell(sheet, row++, 0, '   ${cg.subRegion}', bold: true);
        lastSubRegion = cg.subRegion;
      }
      dataRow('       ${cg.country}', (m) => mCnt(cg.country, m));

      final isLast =
          kCountryRows.indexOf(cg) == kCountryRows.length - 1 ||
          kCountryRows[kCountryRows.indexOf(cg) + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subCols = <String>['                 SUB-TOTAL'];
        int subGrand = 0;
        for (int m = 1; m <= 12; m++) {
          final v = kCountryRows
              .where(
                (x) => x.region == cg.region && x.subRegion == cg.subRegion,
              )
              .fold<int>(0, (a, x) => a + mCnt(x.country, m));
          subCols.add(v == 0 ? '' : v.toString());
          subGrand += v;
        }
        subCols.add(subGrand.toString());
        _row(sheet, row++, subCols, bold: true);
        row++;
      }
    }

    // ── Others, totals, grand total
    dataRow(
      'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES',
      (m) => mRes(m, 'unspecified_guest'),
    );

    final nprCols = <String>['TOTAL NON-PHILIPPINE RESIDENTS'];
    int nprGrand = 0;
    for (int m = 1; m <= 12; m++) {
      final v = mCountryAll(m) + mRes(m, 'unspecified_guest');
      nprCols.add(v == 0 ? '' : v.toString());
      nprGrand += v;
    }
    nprCols.add(nprGrand.toString());
    _row(sheet, row++, nprCols, bold: true);

    dataRow('OVERSEAS FILIPINOS*', (m) => mRes(m, 'overseas_filipino'));

    final gtCols = <String>['GRAND TOTAL GUEST ARRIVALS'];
    int gtGrand = 0;
    for (int m = 1; m <= 12; m++) {
      final v =
          mRes(m, 'philippine_resident_filipino') +
          mRes(m, 'philippine_resident_foreign') +
          mCountryAll(m) +
          mRes(m, 'unspecified_guest') +
          mRes(m, 'overseas_filipino');
      gtCols.add(v == 0 ? '' : v.toString());
      gtGrand += v;
    }
    gtCols.add(gtGrand.toString());
    _row(sheet, row++, gtCols, bold: true);

    row += 2;
    _cell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _cell(sheet, row++, 0, 'A. DAE2:');

    void indRow(String label, int Function(int month) fn) {
      final cols = <String>[label];
      int total = 0;
      for (int m = 1; m <= 12; m++) {
        final v = fn(m);
        cols.add(v == 0 ? '' : v.toString());
        total += v;
      }
      cols.add(total.toString());
      _row(sheet, row++, cols);
    }

    indRow(
      '1. Rooms Occupied',
      (m) => mdFor(m).roomsOccupied.values.fold<int>(0, (a, b) => a + b),
    );
    indRow(
      '2. Rooms available for the month',
      (m) => totalRoomsAll * DateTime(year, m + 1, 0).day,
    );
    indRow('3. Total Guest nights', (m) => mdFor(m).guestNights);

    row++;
    _cell(sheet, row++, 0, 'Alternative Submission');

    // Occupancy rate per month — no total column (leave blank)
    final occCols = <String>['1. Average Monthly Occupancy Rate'];
    for (int m = 1; m <= 12; m++) {
      final occ = mdFor(m).roomsOccupied.values.fold<int>(0, (a, b) => a + b);
      final avail = totalRoomsAll * DateTime(year, m + 1, 0).day;
      occCols.add(
        avail > 0 ? '${(occ / avail * 100).toStringAsFixed(2)}%' : '0%',
      );
    }
    occCols.add('');
    _row(sheet, row++, occCols);

    // Average Length of Stay per month — no total column
    final alsCols = <String>['2. Average Length of Stay (in Nights)'];
    for (int m = 1; m <= 12; m++) {
      final md = mdFor(m);
      final guests =
          mRes(m, 'philippine_resident_filipino') +
          mRes(m, 'philippine_resident_foreign') +
          mCountryAll(m) +
          mRes(m, 'unspecified_guest') +
          mRes(m, 'overseas_filipino');
      alsCols.add(
        guests > 0 ? (md.guestNights / guests).toStringAsFixed(2) : '0',
      );
    }
    alsCols.add('');
    _row(sheet, row++, alsCols);

    row++;
    _cell(sheet, row++, 0, 'B. VOLUME PER SEX', bold: true);

    int mSex(int month, String s, String cat) =>
        mdFor(month).sexByDay[0]?[s]?[cat] ?? 0;

    void sexRow(String label, String s, String cat) {
      final cols = <String>[label];
      int total = 0;
      for (int m = 1; m <= 12; m++) {
        final v = mSex(m, s, cat);
        cols.add(v == 0 ? '' : v.toString());
        total += v;
      }
      cols.add(total.toString());
      _row(sheet, row++, cols);
    }

    _cell(sheet, row++, 0, '1. Male');
    sexRow('a. Philippine Residents', 'male', 'philippine_resident_filipino');
    sexRow(
      'b. Non-Philippine/Foreign Residents (including unspecified)',
      'male',
      'foreign_resident',
    );
    sexRow('c. Overseas Filipinos', 'male', 'overseas_filipino');
    sexRow('d. Others/Unspecified Guest', 'male', 'unspecified_guest');

    final maleCols = <String>['x. Total'];
    int maleGrand = 0;
    for (int m = 1; m <= 12; m++) {
      final v =
          mSex(m, 'male', 'philippine_resident_filipino') +
          mSex(m, 'male', 'philippine_resident_foreign') +
          mSex(m, 'male', 'foreign_resident') +
          mSex(m, 'male', 'unspecified_guest') +
          mSex(m, 'male', 'overseas_filipino');
      maleCols.add(v == 0 ? '' : v.toString());
      maleGrand += v;
    }
    maleCols.add(maleGrand.toString());
    _row(sheet, row++, maleCols, bold: true);

    _cell(sheet, row++, 0, '2. Female');
    sexRow('a. Philippine Residents', 'female', 'philippine_resident_filipino');
    sexRow(
      'b. Non-Philippine/Foreign Residents (including unspecified)',
      'female',
      'foreign_resident',
    );
    sexRow('c. Overseas Filipinos', 'female', 'overseas_filipino');
    sexRow('d. Others/Unspecified Guest', 'female', 'unspecified_guest');

    final femaleCols = <String>['x. Total'];
    int femaleGrand = 0;
    for (int m = 1; m <= 12; m++) {
      final v =
          mSex(m, 'female', 'philippine_resident_filipino') +
          mSex(m, 'female', 'philippine_resident_foreign') +
          mSex(m, 'female', 'foreign_resident') +
          mSex(m, 'female', 'unspecified_guest') +
          mSex(m, 'female', 'overseas_filipino');
      femaleCols.add(v == 0 ? '' : v.toString());
      femaleGrand += v;
    }
    femaleCols.add(femaleGrand.toString());
    _row(sheet, row++, femaleCols, bold: true);

    row += 2;
    _cell(
      sheet,
      row++,
      0,
      '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos',
    );
    row++;
    _cell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  _MonthData _emptyMonth(int month) => _MonthData(
    month: month,
    countryByDay: {},
    residentsByDay: {},
    sexByDay: {},
    roomsOccupied: {},
    guestNights: 0,
    roomsAvailable: 0,
  );

  /// Sanitises a business name for use as an Excel sheet tab (max 31 chars,
  /// no special characters).
  String _sheetTabName(String name) {
    final clean = name.replaceAll(RegExp(r'[\\/*?:\[\]]'), '').trim();
    return clean.length > 31 ? clean.substring(0, 31) : clean;
  }

  void _cell(Sheet sheet, int row, int col, String value, {bool bold = false}) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    if (bold) cell.cellStyle = CellStyle(bold: true);
  }

  void _row(Sheet sheet, int row, List<String> values, {bool bold = false}) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      final raw = values[c];
      final parsed = int.tryParse(raw);
      if (parsed != null) {
        cell.value = IntCellValue(parsed);
      } else {
        cell.value = TextCellValue(raw);
      }
      if (bold) cell.cellStyle = CellStyle(bold: true);
    }
  }

  String _formatBusinessType(String raw) {
    switch (raw.toLowerCase()) {
      case 'hotel':
        return 'Hotel';
      case 'resort':
        return 'Resort';
      case 'pension_inn':
        return 'Pension Inn/ Lodge';
      case 'youth_hostel':
        return 'Youth Hostel/ Dormitory';
      case 'apartel':
        return 'Apartel/ Rented Homes/ Apartment';
      default:
        return raw;
    }
  }

  String _normalizeUpper(Object? value) =>
      value?.toString().trim().toUpperCase() ?? '';
  String _normalizeLower(Object? value) =>
      value?.toString().trim().toLowerCase() ?? '';

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _asBool(Object? value) {
    if (value is bool) return value;
    final n = value?.toString().trim().toLowerCase();
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
