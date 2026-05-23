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

// ─── Internal Models ──────────────────────────────────────────────────────────

class _BusinessInfo {
  final String id;
  final String name;
  final String businessLine;
  final String region;
  final String cityMunicipality;
  final String province;
  final int totalRooms;

  const _BusinessInfo({
    required this.id,
    required this.name,
    required this.businessLine,
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

  // ── ON Blank Form color palette (ARGB hex, matching exactly) ──────────────
  // Blue  — section headers: PHILIPPINE RESIDENTS, NON-PHILIPPINE RESIDENTS,
  //         region/sub-region labels, OVERSEAS FILIPINOS, OTHERS & UNSPECIFIED
  static const _kBlue = 'FF0070C0';
  // Green — total rows: TOTAL PHILIPPINE RESIDENTS, TOTAL NON-PHILIPPINE,
  //         sub-breakdown rows under GRAND TOTAL
  static const _kGreen = 'FF92D050';
  // Light blue — SUB-TOTAL rows inside each region
  static const _kLightBlue = 'FF00B0F0';
  // Yellow — GRAND TOTAL, A. DAE2, B. VOLUME PER SEX
  static const _kYellow = 'FFFFFF00';
  // Light yellow — column header row (COUNTRY OF RESIDENCE | 1–31 | TOTAL)
  static const _kLightYellow = 'FFFFFF66';

  // ── PUBLIC ENTRY POINT ────────────────────────────────────────────────────

  Future<String> generateAndUpload(ReportParams params) async {
    final businesses = await _fetchAllBusinesses();
    if (businesses.isEmpty) {
      throw Exception('No approved businesses found. Cannot generate report.');
    }

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

    final totalRoomsAll = businesses.fold<int>(0, (sum, b) => sum + b.totalRooms);

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
          'id, business_name, business_line, region, city_municipality, province, total_rooms',
        )
        .eq('status', 'approved')
        .order('business_name');

    return (rows as List)
        .map(
          (r) => _BusinessInfo(
            id: r['id'] as String,
            name: r['business_name'] as String? ?? 'Unknown',
            businessLine: _displayBusinessLine(r['business_line']),
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

  // ── MERGE ─────────────────────────────────────────────────────────────────

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

    return Uint8List.fromList(excel.encode()!);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHEET: Daily (per business, selected month)
  // ══════════════════════════════════════════════════════════════════════════

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

    // ── Header block (Arial 10pt, matching blank form layout) ──────────────
    _hdrCell(sheet, row++, 0, 'DAE-1B (Manual)', bold: false);
    _hdrCell(sheet, row++, 0, 'Region: __${biz.region}', bold: true, center: true);
    _hdrCell(sheet, row++, 0, '${kMonthNames[md.month]}, $year', bold: false, center: true);
    row++; // blank row between date and title
    _hdrCell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS', bold: true, center: true, size: 12);
    _hdrCell(sheet, row++, 0, 'Establishment: ${biz.name}', bold: true);
    _hdrCell(sheet, row++, 0, 'Type of Accommodation: ${_formatBusinessType(biz.businessLine)}', bold: true);
    _hdrCell(sheet, row++, 0, 'City/Municipality: ${biz.cityMunicipality}', bold: true);
    _hdrCell(sheet, row++, 0, 'Province: ${biz.province}', bold: true);
    row++; // blank row before data table

    // ── Column header row — light-yellow bg, Bell MT for day numbers ───────
    _writeDayColHeaders(sheet, row++);

    // ── Data helpers ───────────────────────────────────────────────────────
    int cnt(String country, int day) =>
        md.countryByDay[country.toUpperCase()]?[day] ?? 0;

    int countryTotal(int day) => md.countryByDay.values
        .fold<int>(0, (sum, days) => sum + (days[day] ?? 0));

    int res(int day, String cat) => md.residentsByDay[day]?[cat] ?? 0;

    // Builds a 33-element list: [label, d1..d31, total]
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

    // ── PHILIPPINE RESIDENTS ───────────────────────────────────────────────
    _sectionRow(sheet, row++, 'PHILIPPINE RESIDENTS', _kBlue, totalCols: 33);
    _styledRow(sheet, row++, dayValues('   FILIPINO NATIONALITY', (d) => res(d, 'philippine_resident_filipino')));
    _styledRow(sheet, row++, dayValues('   FOREIGN NATIONALITY', (d) => res(d, 'philippine_resident_foreign')));

    final prVals = dayValues('TOTAL PHILIPPINE RESIDENTS', (d) =>
        res(d, 'philippine_resident_filipino') +
        res(d, 'philippine_resident_foreign'));
    // Override total col (index 32) with day-0 aggregates
    prVals[32] = (res(0, 'philippine_resident_filipino') +
            res(0, 'philippine_resident_foreign'))
        .toString();
    _styledRow(sheet, row++, prVals, bgHex: _kGreen, bold: true);

    row++; // blank
    _sectionRow(sheet, row++, 'NON-PHILIPPINE RESIDENTS', _kBlue, totalCols: 33);
    row++; // blank

    // ── Country groups ─────────────────────────────────────────────────────
    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      // Region header
      if (cg.region != lastRegion) {
        _sectionRow(sheet, row++, cg.region, _kBlue, totalCols: 33);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      // Sub-region header (only when sub-region ≠ region, e.g. AFRICA has same)
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _sectionRow(sheet, row++, '   ${cg.subRegion}', _kBlue, totalCols: 33);
        lastSubRegion = cg.subRegion;
      }
      // Country data row — no fill, bold label
      _styledRow(sheet, row++, dayValues('       ${cg.country}', (d) => cnt(cg.country, d)), bold: true);

      // Sub-total after the last country in a sub-region
      final idx = kCountryRows.indexOf(cg);
      final isLastInSubRegion = idx == kCountryRows.length - 1 ||
          kCountryRows[idx + 1].subRegion != cg.subRegion;

      if (isLastInSubRegion) {
        final subCountries = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .map((x) => x.country)
            .toList();
        final stVals = dayValues('                 SUB-TOTAL', (d) =>
            subCountries.fold<int>(0, (a, c) => a + cnt(c, d)));
        stVals[32] = subCountries
            .fold<int>(0, (a, c) => a + (md.countryByDay[c]?[0] ?? 0))
            .toString();
        _styledRow(sheet, row++, stVals, bgHex: _kLightBlue, bold: true);
        row++; // blank between sub-regions
      }
    }

    // ── Others and totals ──────────────────────────────────────────────────
    _sectionRow(sheet, row++, 'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES', _kBlue, totalCols: 33);
    _styledRow(sheet, row, dayValues('', (d) => res(d, 'unspecified_guest')));
    // Write the actual count values on same row as the blue label row above
    // (The blank form wraps the label across 2 rows; we keep one row for the values)
    row++;

    // TOTAL NON-PHILIPPINE RESIDENTS
    int nprTotal = 0;
    final nprVals = dayValues('TOTAL NON-PHILIPPINE RESIDENTS', (d) {
      final v = countryTotal(d) + res(d, 'unspecified_guest');
      return v;
    });
    nprTotal = md.countryByDay.values.fold<int>(0, (a, days) => a + (days[0] ?? 0)) +
        res(0, 'unspecified_guest');
    nprVals[32] = nprTotal.toString();
    _styledRow(sheet, row++, nprVals, bgHex: _kGreen, bold: true);

    // OVERSEAS FILIPINOS
    _sectionRow(sheet, row++, 'OVERSEAS FILIPINOS*', _kBlue, totalCols: 33);
    _styledRow(sheet, row, dayValues('', (d) => res(d, 'overseas_filipino')));
    row++;

    // GRAND TOTAL GUEST ARRIVALS
    int gtTotal = 0;
    final gtVals = dayValues('GRAND TOTAL GUEST ARRIVALS', (d) {
      final v = res(d, 'philippine_resident_filipino') +
          res(d, 'philippine_resident_foreign') +
          countryTotal(d) +
          res(d, 'unspecified_guest') +
          res(d, 'overseas_filipino');
      return v;
    });
    gtTotal = res(0, 'philippine_resident_filipino') +
        res(0, 'philippine_resident_foreign') +
        nprTotal +
        res(0, 'overseas_filipino');
    gtVals[32] = gtTotal.toString();
    _styledRow(sheet, row++, gtVals, bgHex: _kYellow, bold: true);

    // Sub-breakdown rows (green bg)
    _styledRow(
      sheet, row++,
      dayValues('   Total Philippine Residents', (d) =>
          res(d, 'philippine_resident_filipino') +
          res(d, 'philippine_resident_foreign')),
      bgHex: _kGreen, bold: true,
    );
    _styledRow(
      sheet, row++,
      dayValues('   Total Non-Philippine Residents', (d) =>
          countryTotal(d) + res(d, 'unspecified_guest')),
      bgHex: _kGreen, bold: true,
    );
    _styledRow(
      sheet, row++,
      dayValues('   Total Overseas Filipinos', (d) => res(d, 'overseas_filipino')),
      bgHex: _kGreen, bold: true,
    );
    _styledRow(
      sheet, row++,
      dayValues('   Total Guest with Unspecified Residence', (d) => res(d, 'unspecified_guest')),
      bgHex: _kGreen, bold: true,
    );

    row += 2;

    // ── PART II ────────────────────────────────────────────────────────────
    _styledCell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _sectionRow(sheet, row++, 'A. DAE2:', _kYellow, totalCols: 33);

    // 1. Rooms Occupied
    final roomVals = dayValues('1. Rooms Occupied', (d) => md.roomsOccupied[d] ?? 0);
    roomVals[32] = md.roomsOccupied.values.fold<int>(0, (a, b) => a + b).toString();
    _styledRow(sheet, row++, roomVals);

    // 2. Rooms available
    final availVals = <String>['2. Rooms available for the month'];
    for (int d = 1; d <= 31; d++) {
      availVals.add(d <= daysInMonth ? biz.totalRooms.toString() : '');
    }
    availVals.add((biz.totalRooms * daysInMonth).toString());
    _styledRow(sheet, row++, availVals);

    // 3. Total Guest nights
    final gnVals = dayValues('3. Total Guest nights', (d) => md.guestNightsByDay[d] ?? 0);
    gnVals[32] = md.guestNights.toString();
    _styledRow(sheet, row++, gnVals);

    row++;
    _styledCell(sheet, row++, 0, 'Alternative Submission', bold: true);

    // Occupancy rate
    final totalRoomsOcc = md.roomsOccupied.values.fold<int>(0, (a, b) => a + b);
    final roomsAvail = biz.totalRooms * daysInMonth;
    final occVals = <String>['1. Average Monthly Occupancy Rate'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final roomsAvailDay = biz.totalRooms;
        final occDay = md.roomsOccupied[d] ?? 0;
        occVals.add(roomsAvailDay > 0
            ? '${(occDay / roomsAvailDay * 100).toStringAsFixed(2)}%'
            : '0%');
      } else {
        occVals.add('');
      }
    }
    occVals.add(roomsAvail > 0
        ? '${(totalRoomsOcc / roomsAvail * 100).toStringAsFixed(2)}%'
        : '0%');
    _styledRow(sheet, row++, occVals);

    // Average Length of Stay
    int guestArrivalsDay(int day) =>
        md.residentsByDay[day]?.values.fold<int>(0, (sum, v) => sum + v) ?? 0;

    final alsVals = <String>['2. Average Length of Stay (in Nights)'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final arrivals = guestArrivalsDay(d);
        final nightsForArrivals = md.guestNightsPerArrivalDay[d] ?? 0;
        alsVals.add(arrivals > 0
            ? (nightsForArrivals / arrivals).toStringAsFixed(2)
            : '0');
      } else {
        alsVals.add('');
      }
    }
    alsVals.add(gtTotal > 0 ? (md.guestNights / gtTotal).toStringAsFixed(2) : '0');
    _styledRow(sheet, row++, alsVals);

    row++;
    _sectionRow(sheet, row++, 'B. VOLUME PER SEX', _kYellow, totalCols: 33);

    int sex(int day, String s, String cat) => md.sexByDay[day]?[s]?[cat] ?? 0;

    void _sexSectionMale() {
      _styledCell(sheet, row++, 0, '1. Male', bold: true);

      // a. Philippine Residents (both buckets)
      _styledRow(sheet, row++, dayValues('a. Philippine Residents', (d) =>
          sex(d, 'male', 'philippine_resident_filipino') +
          sex(d, 'male', 'philippine_resident_foreign')));
      _styledRow(sheet, row++, dayValues(
          'b. Non-Philippine/Foreign Residents (including unspecified)',
          (d) => sex(d, 'male', 'foreign_resident')));
      _styledRow(sheet, row++, dayValues('c. Overseas Filipinos', (d) => sex(d, 'male', 'overseas_filipino')));
      _styledRow(sheet, row++, dayValues('d. Others/Unspecified Guest', (d) => sex(d, 'male', 'unspecified_guest')));

      final maleTotVals = dayValues('x. Total', (d) =>
          sex(d, 'male', 'philippine_resident_filipino') +
          sex(d, 'male', 'philippine_resident_foreign') +
          sex(d, 'male', 'foreign_resident') +
          sex(d, 'male', 'unspecified_guest') +
          sex(d, 'male', 'overseas_filipino'));
      maleTotVals[32] = (sex(0, 'male', 'philippine_resident_filipino') +
              sex(0, 'male', 'philippine_resident_foreign') +
              sex(0, 'male', 'foreign_resident') +
              sex(0, 'male', 'unspecified_guest') +
              sex(0, 'male', 'overseas_filipino'))
          .toString();
      _styledRow(sheet, row++, maleTotVals, bold: true);
    }

    void _sexSectionFemale() {
      _styledCell(sheet, row++, 0, '2. Female', bold: true);

      _styledRow(sheet, row++, dayValues('a. Philippine Residents', (d) =>
          sex(d, 'female', 'philippine_resident_filipino') +
          sex(d, 'female', 'philippine_resident_foreign')));
      _styledRow(sheet, row++, dayValues(
          'b. Non-Philippine/Foreign Residents (including unspecified)',
          (d) => sex(d, 'female', 'foreign_resident')));
      _styledRow(sheet, row++, dayValues('c. Overseas Filipinos', (d) => sex(d, 'female', 'overseas_filipino')));
      _styledRow(sheet, row++, dayValues('d. Others/Unspecified Guest', (d) => sex(d, 'female', 'unspecified_guest')));

      final femTotVals = dayValues('x. Total', (d) =>
          sex(d, 'female', 'philippine_resident_filipino') +
          sex(d, 'female', 'philippine_resident_foreign') +
          sex(d, 'female', 'foreign_resident') +
          sex(d, 'female', 'unspecified_guest') +
          sex(d, 'female', 'overseas_filipino'));
      femTotVals[32] = (sex(0, 'female', 'philippine_resident_filipino') +
              sex(0, 'female', 'philippine_resident_foreign') +
              sex(0, 'female', 'foreign_resident') +
              sex(0, 'female', 'unspecified_guest') +
              sex(0, 'female', 'overseas_filipino'))
          .toString();
      _styledRow(sheet, row++, femTotVals, bold: true);
    }

    _sexSectionMale();
    _sexSectionFemale();

    row += 2;
    _styledCell(
      sheet, row++, 0,
      '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos',
    );
    row++;
    _styledCell(
      sheet, row++, 0,
      'Prepared by:            ____________________________________'
      '                         ________________________________________'
      '                         ____________________________________',
    );
    _styledCell(
      sheet, row, 0,
      '                                                      Signature over Printed Name'
      '                                                     Position/Designation',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHEET: Country Summary (all businesses merged, selected month)
  // ══════════════════════════════════════════════════════════════════════════

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

    // Header block
    _hdrCell(sheet, row++, 0, 'DAE-1B(Manual-Summary)', bold: false);
    _hdrCell(sheet, row++, 0, 'Region: __4-A', bold: true, center: true);
    _hdrCell(sheet, row++, 0, '${kMonthNames[month]}, $year', bold: false, center: true);
    row++;
    _hdrCell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS', bold: true, center: true, size: 12);
    _hdrCell(sheet, row++, 0, 'All Accommodation Establishments — Combined', bold: true);
    row++;

    // Column headers — light yellow
    _styledCell(sheet, row, 0, 'COUNTRY OF RESIDENCE', bold: true, bgHex: _kLightYellow);
    _styledCell(sheet, row++, 1, 'TOTAL', bold: true, bgHex: _kLightYellow, halign: HorizontalAlign.Center);

    row++; // blank

    int totCnt(String country) =>
        md.countryByDay[country.toUpperCase()]?[0] ?? 0;
    int totRes(String cat) => md.residentsByDay[0]?[cat] ?? 0;
    int totCountryAll() =>
        md.countryByDay.values.fold<int>(0, (a, days) => a + (days[0] ?? 0));

    // PHILIPPINE RESIDENTS
    _sectionRow(sheet, row++, 'PHILIPPINE RESIDENTS', _kBlue, totalCols: 2);
    _styledRow(sheet, row++, ['   FILIPINO NATIONALITY', totRes('philippine_resident_filipino').toString()]);
    _styledRow(sheet, row++, ['   FOREIGN NATIONALITY', totRes('philippine_resident_foreign').toString()]);
    _styledRow(sheet, row++, [
      'TOTAL PHILIPPINE RESIDENTS',
      (totRes('philippine_resident_filipino') + totRes('philippine_resident_foreign')).toString(),
    ], bgHex: _kGreen, bold: true);

    row++;
    _sectionRow(sheet, row++, 'NON-PHILIPPINE RESIDENTS', _kBlue, totalCols: 2);
    row++;

    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _sectionRow(sheet, row++, cg.region, _kBlue, totalCols: 2);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _sectionRow(sheet, row++, '   ${cg.subRegion}', _kBlue, totalCols: 2);
        lastSubRegion = cg.subRegion;
      }
      _styledRow(sheet, row++, ['       ${cg.country}', totCnt(cg.country).toString()], bold: true);

      final idx = kCountryRows.indexOf(cg);
      final isLast = idx == kCountryRows.length - 1 ||
          kCountryRows[idx + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subTotal = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .fold<int>(0, (a, x) => a + totCnt(x.country));
        _styledRow(sheet, row++, ['                 SUB-TOTAL', subTotal.toString()],
            bgHex: _kLightBlue, bold: true);
        row++;
      }
    }

    final nprTotal = totCountryAll() + totRes('unspecified_guest');

    _sectionRow(sheet, row++, 'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES', _kBlue, totalCols: 2);
    _styledRow(sheet, row++, ['', totRes('unspecified_guest').toString()]);

    _styledRow(sheet, row++, ['TOTAL NON-PHILIPPINE RESIDENTS', nprTotal.toString()],
        bgHex: _kGreen, bold: true);

    _sectionRow(sheet, row++, 'OVERSEAS FILIPINOS*', _kBlue, totalCols: 2);
    _styledRow(sheet, row++, ['', totRes('overseas_filipino').toString()]);

    final grandTotal = totRes('philippine_resident_filipino') +
        totRes('philippine_resident_foreign') +
        nprTotal +
        totRes('overseas_filipino');
    _styledRow(sheet, row++, ['GRAND TOTAL GUEST ARRIVALS', grandTotal.toString()],
        bgHex: _kYellow, bold: true);

    // Sub-breakdown (green)
    _styledRow(sheet, row++, [
      '   Total Philippine Residents',
      (totRes('philippine_resident_filipino') + totRes('philippine_resident_foreign')).toString(),
    ], bgHex: _kGreen, bold: true);
    _styledRow(sheet, row++, ['   Total Non-Philippine Residents', nprTotal.toString()],
        bgHex: _kGreen, bold: true);
    _styledRow(sheet, row++, ['   Total Overseas Filipinos', totRes('overseas_filipino').toString()],
        bgHex: _kGreen, bold: true);
    _styledRow(sheet, row++, ['   Total Guest with Unspecified Residence', totRes('unspecified_guest').toString()],
        bgHex: _kGreen, bold: true);

    row += 2;
    _styledCell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _sectionRow(sheet, row++, 'A. DAE2:', _kYellow, totalCols: 2);

    final sumRoomsOcc = md.roomsOccupied.values.fold<int>(0, (a, b) => a + b);
    final sumRoomsAvail = totalRoomsAll * daysInMonth;

    _styledRow(sheet, row++, ['1. Rooms Occupied', sumRoomsOcc.toString()]);
    _styledRow(sheet, row++, ['2. Rooms available for the month', sumRoomsAvail.toString()]);
    _styledRow(sheet, row++, ['3. Total Guest nights', md.guestNights.toString()]);
    row++;
    _styledCell(sheet, row++, 0, 'Alternative Submission', bold: true);

    final occRate = sumRoomsAvail > 0
        ? '${(sumRoomsOcc / sumRoomsAvail * 100).toStringAsFixed(2)}%'
        : '0%';
    _styledRow(sheet, row++, ['1. Average Monthly Occupancy Rate', occRate]);

    final als = grandTotal > 0 ? (md.guestNights / grandTotal).toStringAsFixed(2) : '0';
    _styledRow(sheet, row++, ['2. Average Length of Stay (in Nights)', als]);

    row++;
    _sectionRow(sheet, row++, 'B. VOLUME PER SEX', _kYellow, totalCols: 2);

    int totSex(String s, String cat) => md.sexByDay[0]?[s]?[cat] ?? 0;

    void _sumSexRows(String gender, String label) {
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
      _styledRow(sheet, row++, ['c. Overseas Filipinos', totSex(gender, 'overseas_filipino').toString()]);
      _styledRow(sheet, row++, ['d. Others/Unspecified Guest', totSex(gender, 'unspecified_guest').toString()]);
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

    _sumSexRows('male', '1. Male');
    _sumSexRows('female', '2. Female');

    row += 2;
    _styledCell(sheet, row++, 0,
        '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos');
    row++;
    _styledCell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHEET: Monthly Summary (all 12 months, all businesses merged)
  // ══════════════════════════════════════════════════════════════════════════

  void _buildMonthlySummarySheet(
    Excel excel,
    List<_MonthData> allMonths,
    int totalRoomsAll,
    int year,
  ) {
    final sheet = excel['AE DAE-1B (Monthly)'];
    _setupMonthlyColumns(sheet);
    int row = 0;

    // Header block
    _hdrCell(sheet, row++, 0, 'DAE-1B(Manual-Summary)', bold: false);
    _hdrCell(sheet, row++, 0, 'Region: __4-A', bold: true, center: true);
    _hdrCell(sheet, row++, 0, '$year', bold: false, center: true);
    row++;
    _hdrCell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS', bold: true, center: true, size: 12);
    _hdrCell(sheet, row++, 0, 'All Accommodation Establishments — Combined', bold: true);
    row++;

    // Column headers — light yellow, Arial (no Bell MT; month names, not day numbers)
    _styledCell(sheet, row, 0, 'COUNTRY OF RESIDENCE', bold: true, bgHex: _kLightYellow);
    for (int m = 1; m <= 12; m++) {
      _styledCell(sheet, row, m, kMonthNames[m], bold: true, bgHex: _kLightYellow, halign: HorizontalAlign.Center);
    }
    _styledCell(sheet, row++, 13, 'TOTAL', bold: true, bgHex: _kLightYellow, halign: HorizontalAlign.Center);

    row++; // blank

    // Helpers
    _MonthData mdFor(int month) => allMonths.firstWhere(
      (m) => m.month == month,
      orElse: () => _emptyMonth(month),
    );
    int mCnt(String country, int month) =>
        mdFor(month).countryByDay[country.toUpperCase()]?[0] ?? 0;
    int mRes(int month, String cat) =>
        mdFor(month).residentsByDay[0]?[cat] ?? 0;
    int mCountryAll(int month) => mdFor(month).countryByDay.values
        .fold<int>(0, (a, days) => a + (days[0] ?? 0));

    // Builds [label, jan..dec, total]
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

    // PHILIPPINE RESIDENTS
    _sectionRow(sheet, row++, 'PHILIPPINE RESIDENTS', _kBlue, totalCols: 14);
    _styledRow(sheet, row++, monthValues('   FILIPINO NATIONALITY', (m) => mRes(m, 'philippine_resident_filipino')));
    _styledRow(sheet, row++, monthValues('   FOREIGN NATIONALITY', (m) => mRes(m, 'philippine_resident_foreign')));
    _styledRow(sheet, row++, monthValues('TOTAL PHILIPPINE RESIDENTS', (m) =>
        mRes(m, 'philippine_resident_filipino') + mRes(m, 'philippine_resident_foreign')),
        bgHex: _kGreen, bold: true);

    row++;
    _sectionRow(sheet, row++, 'NON-PHILIPPINE RESIDENTS', _kBlue, totalCols: 14);
    row++;

    String? lastRegion, lastSubRegion;
    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _sectionRow(sheet, row++, cg.region, _kBlue, totalCols: 14);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion && cg.subRegion != cg.region) {
        _sectionRow(sheet, row++, '   ${cg.subRegion}', _kBlue, totalCols: 14);
        lastSubRegion = cg.subRegion;
      }
      _styledRow(sheet, row++, monthValues('       ${cg.country}', (m) => mCnt(cg.country, m)), bold: true);

      final idx = kCountryRows.indexOf(cg);
      final isLast = idx == kCountryRows.length - 1 ||
          kCountryRows[idx + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subCountries = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .map((x) => x.country)
            .toList();
        _styledRow(sheet, row++, monthValues('                 SUB-TOTAL', (m) =>
            subCountries.fold<int>(0, (a, c) => a + mCnt(c, m))),
            bgHex: _kLightBlue, bold: true);
        row++;
      }
    }

    _sectionRow(sheet, row++, 'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES', _kBlue, totalCols: 14);
    _styledRow(sheet, row++, monthValues('', (m) => mRes(m, 'unspecified_guest')));

    final nprVals = monthValues('TOTAL NON-PHILIPPINE RESIDENTS', (m) =>
        mCountryAll(m) + mRes(m, 'unspecified_guest'));
    _styledRow(sheet, row++, nprVals, bgHex: _kGreen, bold: true);

    _sectionRow(sheet, row++, 'OVERSEAS FILIPINOS*', _kBlue, totalCols: 14);
    _styledRow(sheet, row++, monthValues('', (m) => mRes(m, 'overseas_filipino')));

    final gtVals = monthValues('GRAND TOTAL GUEST ARRIVALS', (m) =>
        mRes(m, 'philippine_resident_filipino') +
        mRes(m, 'philippine_resident_foreign') +
        mCountryAll(m) +
        mRes(m, 'unspecified_guest') +
        mRes(m, 'overseas_filipino'));
    _styledRow(sheet, row++, gtVals, bgHex: _kYellow, bold: true);

    // Sub-breakdown (green)
    _styledRow(sheet, row++, monthValues('   Total Philippine Residents', (m) =>
        mRes(m, 'philippine_resident_filipino') + mRes(m, 'philippine_resident_foreign')),
        bgHex: _kGreen, bold: true);
    _styledRow(sheet, row++, monthValues('   Total Non-Philippine Residents', (m) =>
        mCountryAll(m) + mRes(m, 'unspecified_guest')),
        bgHex: _kGreen, bold: true);
    _styledRow(sheet, row++, monthValues('   Total Overseas Filipinos', (m) => mRes(m, 'overseas_filipino')),
        bgHex: _kGreen, bold: true);
    _styledRow(sheet, row++, monthValues('   Total Guest with Unspecified Residence', (m) => mRes(m, 'unspecified_guest')),
        bgHex: _kGreen, bold: true);

    row += 2;
    _styledCell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _sectionRow(sheet, row++, 'A. DAE2:', _kYellow, totalCols: 14);

    _styledRow(sheet, row++, monthValues('1. Rooms Occupied',
        (m) => mdFor(m).roomsOccupied.values.fold<int>(0, (a, b) => a + b)));
    _styledRow(sheet, row++, monthValues('2. Rooms available for the month',
        (m) => totalRoomsAll * DateTime(year, m + 1, 0).day));
    _styledRow(sheet, row++, monthValues('3. Total Guest nights', (m) => mdFor(m).guestNights));

    row++;
    _styledCell(sheet, row++, 0, 'Alternative Submission', bold: true);

    // Occupancy rate per month
    final occCols = <String>['1. Average Monthly Occupancy Rate'];
    int totalOccupied = 0;
    int totalAvailable = 0;
    for (int m = 1; m <= 12; m++) {
      final occ = mdFor(m).roomsOccupied.values.fold<int>(0, (a, b) => a + b);
      final avail = totalRoomsAll * DateTime(year, m + 1, 0).day;
      totalOccupied += occ;
      totalAvailable += avail;
      occCols.add(avail > 0 ? '${(occ / avail * 100).toStringAsFixed(2)}%' : '0%');
    }
    occCols.add(totalAvailable > 0
        ? '${(totalOccupied / totalAvailable * 100).toStringAsFixed(2)}%'
        : '0%');
    _styledRow(sheet, row++, occCols);

    // ALS per month
    final alsCols = <String>['2. Average Length of Stay (in Nights)'];
    int totalGuestNights = 0;
    int totalGuests = 0;
    for (int m = 1; m <= 12; m++) {
      final md = mdFor(m);
      final guests =
          mRes(m, 'philippine_resident_filipino') +
          mRes(m, 'philippine_resident_foreign') +
          mCountryAll(m) +
          mRes(m, 'unspecified_guest') +
          mRes(m, 'overseas_filipino');
      totalGuestNights += md.guestNights;
      totalGuests += guests;
      alsCols.add(guests > 0 ? (md.guestNights / guests).toStringAsFixed(2) : '0');
    }
    alsCols.add(totalGuests > 0
        ? (totalGuestNights / totalGuests).toStringAsFixed(2)
        : '0');
    _styledRow(sheet, row++, alsCols);

    row++;
    _sectionRow(sheet, row++, 'B. VOLUME PER SEX', _kYellow, totalCols: 14);

    int mSex(int month, String s, String cat) =>
        mdFor(month).sexByDay[0]?[s]?[cat] ?? 0;

    void _mSexSection(String gender, String label) {
      _styledCell(sheet, row++, 0, label, bold: true);
      _styledRow(sheet, row++, monthValues('a. Philippine Residents', (m) =>
          mSex(m, gender, 'philippine_resident_filipino') +
          mSex(m, gender, 'philippine_resident_foreign')));
      _styledRow(sheet, row++, monthValues(
          'b. Non-Philippine/Foreign Residents (including unspecified)',
          (m) => mSex(m, gender, 'foreign_resident')));
      _styledRow(sheet, row++, monthValues('c. Overseas Filipinos', (m) => mSex(m, gender, 'overseas_filipino')));
      _styledRow(sheet, row++, monthValues('d. Others/Unspecified Guest', (m) => mSex(m, gender, 'unspecified_guest')));
      _styledRow(sheet, row++, monthValues('x. Total', (m) =>
          mSex(m, gender, 'philippine_resident_filipino') +
          mSex(m, gender, 'philippine_resident_foreign') +
          mSex(m, gender, 'foreign_resident') +
          mSex(m, gender, 'unspecified_guest') +
          mSex(m, gender, 'overseas_filipino')),
          bold: true);
    }

    _mSexSection('male', '1. Male');
    _mSexSection('female', '2. Female');

    row += 2;
    _styledCell(sheet, row++, 0,
        '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos');
    row++;
    _styledCell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLUMN WIDTH SETUP — matching ON blank form exactly
  // ══════════════════════════════════════════════════════════════════════════

  /// Daily sheet: A=45.66 · B-AF=4.66 each · AG=14.44
  void _setupDailyColumns(Sheet sheet) {
    sheet.setColumnWidth(0, 45.66);
    for (int i = 1; i <= 31; i++) sheet.setColumnWidth(i, 4.66);
    sheet.setColumnWidth(32, 14.44);
  }

  /// Country summary: A=45.66 · B(TOTAL)=14.44
  void _setupSummaryColumns(Sheet sheet) {
    sheet.setColumnWidth(0, 45.66);
    sheet.setColumnWidth(1, 14.44);
  }

  /// Monthly summary: A=45.66 · B-M(months)=9.0 each · N(TOTAL)=14.44
  void _setupMonthlyColumns(Sheet sheet) {
    sheet.setColumnWidth(0, 45.66);
    for (int i = 1; i <= 12; i++) sheet.setColumnWidth(i, 9.0);
    sheet.setColumnWidth(13, 14.44);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOW-LEVEL STYLE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Header block cell — Arial, configurable size, optional centering.
  void _hdrCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
    bool center = false,
    double size = 10,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      fontFamily: 'Arial',
      fontSize: size.toInt(),
      horizontalAlign: center ? HorizontalAlign.Center : HorizontalAlign.Left,
    );
  }

  /// Standard data cell — Arial 8pt, optional bg, optional bold/align.
  void _styledCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
    String? bgHex,
    HorizontalAlign? halign,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      fontFamily: 'Arial',
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString(bgHex ?? 'FFFFFFFF'),
      horizontalAlign: halign ?? HorizontalAlign.Left,
    );
  }

  /// Writes a section-header label in col 0 AND paints [totalCols] cells
  /// across the row with the given background — matching the full-row coloring
  /// seen in the ON blank form for blue/yellow section rows.
  void _sectionRow(
    Sheet sheet,
    int row,
    String label,
    String bgHex, {
    int totalCols = 33,
    bool bold = true,
  }) {
    for (int c = 0; c < totalCols; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      if (c == 0) cell.value = TextCellValue(label);
      cell.cellStyle = CellStyle(
        bold: c == 0 ? bold : false,
        fontFamily: 'Arial',
        fontSize: 8,
        backgroundColorHex: ExcelColor.fromHexString(bgHex),
      );
    }
  }

  /// Writes a full data row (label + numeric values).  Applies optional bg
  /// and bold across ALL cells — for total/sub-total rows.
  void _styledRow(
    Sheet sheet,
    int row,
    List<String> values, {
    bool bold = false,
    String? bgHex,
  }) {
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
      cell.cellStyle = CellStyle(
        bold: bold,
        fontFamily: 'Arial',
        fontSize: 8,
        backgroundColorHex: ExcelColor.fromHexString(bgHex ?? 'FFFFFFFF'),
      );
    }
  }

  /// Column-header row for the daily sheet.
  /// • Col 0 "COUNTRY OF RESIDENCE"  — Arial 8, bold, light-yellow bg
  /// • Cols 1-31 (day numbers)        — Bell MT 8, bold, light-yellow bg  ← matches blank form
  /// • Col 32 "TOTAL"                 — Arial 8, bold, light-yellow bg, centered
  void _writeDayColHeaders(Sheet sheet, int row) {
    // Label
    final labelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    labelCell.value = TextCellValue('COUNTRY OF RESIDENCE');
    labelCell.cellStyle = CellStyle(
      bold: true,
      fontFamily: 'Arial',
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString(_kLightYellow),
    );

    // Day number cells — Bell MT (matches the ON blank form exactly)
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
      );
    }

    // TOTAL
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATA HELPERS (unchanged from original)
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
      for (final entry in value) {
        if (entry is String && entry.trim().isNotEmpty) {
          return _formatBusinessType(entry);
        }
      }
      return '';
    }
    if (value is String) return _formatBusinessType(value);
    return '';
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