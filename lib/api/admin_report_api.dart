// report_service.dart
// DAE-1B Excel Report Generator
// Generates monthly/quarterly tourist arrival reports following the DOT DAE-1B format.
// Uploads the generated .xlsx to Supabase Storage and logs to the reports table.
//
// Dependencies (pubspec.yaml):
//   supabase_flutter: ^2.x
//   excel: ^4.x
//   path_provider: ^2.x

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// COUNTRY TAXONOMY — mirrors the DAE-1B row structure exactly
// ---------------------------------------------------------------------------

class _CountryGroup {
  final String region;      // e.g. "ASIA"
  final String subRegion;   // e.g. "ASEAN"
  final String country;     // e.g. "BRUNEI"
  const _CountryGroup(this.region, this.subRegion, this.country);
}

const List<_CountryGroup> kCountryRows = [
  // ── ASIA / ASEAN ──────────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'ASEAN', 'BRUNEI'),
  _CountryGroup('ASIA', 'ASEAN', 'CAMBODIA'),
  _CountryGroup('ASIA', 'ASEAN', 'INDONESIA'),
  _CountryGroup('ASIA', 'ASEAN', 'LAOS'),
  _CountryGroup('ASIA', 'ASEAN', 'MALAYSIA'),
  _CountryGroup('ASIA', 'ASEAN', 'MYANMAR'),
  _CountryGroup('ASIA', 'ASEAN', 'SINGAPORE'),
  _CountryGroup('ASIA', 'ASEAN', 'THAILAND'),
  _CountryGroup('ASIA', 'ASEAN', 'VIETNAM'),
  // ── ASIA / EAST ASIA ──────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'EAST ASIA', 'CHINA'),
  _CountryGroup('ASIA', 'EAST ASIA', 'HONGKONG'),
  _CountryGroup('ASIA', 'EAST ASIA', 'JAPAN'),
  _CountryGroup('ASIA', 'EAST ASIA', 'KOREA'),
  _CountryGroup('ASIA', 'EAST ASIA', 'TAIWAN'),
  // ── ASIA / SOUTH ASIA ─────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'SOUTH ASIA', 'BANGLADESH'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'INDIA'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'IRAN'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'NEPAL'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'PAKISTAN'),
  _CountryGroup('ASIA', 'SOUTH ASIA', 'SRI LANKA'),
  // ── ASIA / MIDDLE EAST ────────────────────────────────────────────────────
  _CountryGroup('ASIA', 'MIDDLE EAST', 'BAHRAIN'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'EGYPT'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'ISRAEL'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'JORDAN'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'KUWAIT'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'SAUDI ARABIA'),
  _CountryGroup('ASIA', 'MIDDLE EAST', 'UNITED ARAB EMIRATES'),
  // ── AMERICA / NORTH AMERICA ───────────────────────────────────────────────
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'CANADA'),
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'MEXICO'),
  _CountryGroup('AMERICA', 'NORTH AMERICA', 'USA'),
  // ── AMERICA / SOUTH AMERICA ───────────────────────────────────────────────
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'ARGENTINA'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'BRAZIL'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'COLOMBIA'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'PERU'),
  _CountryGroup('AMERICA', 'SOUTH AMERICA', 'VENEZUELA'),
  // ── EUROPE / WESTERN EUROPE ───────────────────────────────────────────────
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'AUSTRIA'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'BELGIUM'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'FRANCE'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'GERMANY'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'LUXEMBOURG'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'NETHERLANDS'),
  _CountryGroup('EUROPE', 'WESTERN EUROPE', 'SWITZERLAND'),
  // ── EUROPE / NORTHERN EUROPE ──────────────────────────────────────────────
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'DENMARK'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'FINLAND'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'IRELAND'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'NORWAY'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'SWEDEN'),
  _CountryGroup('EUROPE', 'NORTHERN EUROPE', 'UNITED KINGDOM'),
  // ── EUROPE / SOUTHERN EUROPE ──────────────────────────────────────────────
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'GREECE'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'ITALY'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'PORTUGAL'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'SPAIN'),
  _CountryGroup('EUROPE', 'SOUTHERN EUROPE', 'UNION OF SERBIA AND MONTENEGRO'),
  // ── EUROPE / EASTERN EUROPE ───────────────────────────────────────────────
  _CountryGroup('EUROPE', 'EASTERN EUROPE', 'COMMONWEALTH OF INDEPENDENT STATES'),
  _CountryGroup('EUROPE', 'EASTERN EUROPE', 'POLAND'),
  _CountryGroup('EUROPE', 'EASTERN EUROPE', 'RUSSIA'),
  // ── AUSTRALASIA/PACIFIC ───────────────────────────────────────────────────
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'AUSTRALIA'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'GUAM'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'NAURU'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'NEW ZEALAND'),
  _CountryGroup('AUSTRALASIA/PACIFIC', 'AUSTRALASIA/PACIFIC', 'PAPUA NEW GUINEA'),
  // ── AFRICA ────────────────────────────────────────────────────────────────
  _CountryGroup('AFRICA', 'AFRICA', 'NIGERIA'),
  _CountryGroup('AFRICA', 'AFRICA', 'SOUTH AFRICA'),
];

const List<String> kMonthNames = [
  '', 'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
  'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
];

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class ReportSheetOptions {
  final bool includeEstablishmentSheet;
  final bool includeCountrySumSheet;
  final bool includeMonthlySummarySheet;

  const ReportSheetOptions({
    this.includeEstablishmentSheet = true,
    this.includeCountrySumSheet = true,
    this.includeMonthlySummarySheet = true,
  });
}

class ReportParams {
  /// 1–3 months to include (e.g. [1,2,3] for Q1).
  final List<int> months;
  final int year;
  final String businessId;

  const ReportParams({
    required this.months,
    required this.year,
    required this.businessId,
  }) : assert(months.length >= 1 && months.length <= 3,
            'Select between 1 and 3 months');
}

class _BusinessInfo {
  final String name;
  final String businessType;
  final String region;
  final String cityMunicipality;
  final String province;
  final int totalRooms;

  const _BusinessInfo({
    required this.name,
    required this.businessType,
    required this.region,
    required this.cityMunicipality,
    required this.province,
    required this.totalRooms,
  });
}

/// Aggregated counts keyed by [country][day] = count.
/// day = 0 means "total across days" (used by Sheet 2 and Sheet 3).
typedef _DayCountMap = Map<String, Map<int, int>>;

class _MonthData {
  final int month;
  /// country → {day → count}  (non-Philippine residents)
  final _DayCountMap countryByDay;
  /// day → {resident_type → count}
  final Map<int, Map<String, int>> residentsByDay;
  /// day → {sex → {resident_type → count}}
  final Map<int, Map<String, Map<String, int>>> sexByDay;
  /// day → rooms_occupied
  final Map<int, int> roomsOccupied;
  /// total guest nights for the month
  final int guestNights;
  /// rooms available = totalRooms * days_in_month
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

// ---------------------------------------------------------------------------
// REPORT SERVICE
// ---------------------------------------------------------------------------

class ReportService {
  ReportService({SupabaseClient? client})
      : _sb = client ?? Supabase.instance.client;

  final SupabaseClient _sb;
  static const _bucket = 'reports';

  // ── PUBLIC ENTRY POINT ───────────────────────────────────────────────────

  /// Generates the DAE-1B Excel workbook, uploads it to Supabase Storage,
  /// inserts a row in [reports], and returns the public file URL.
  Future<String> generateAndUpload(ReportParams params) async {
    final business = await _fetchBusiness(params.businessId);
    final monthDataList = await Future.wait(
      params.months.map((m) => _fetchMonthData(params.businessId, m, params.year)),
    );

    final bytes = _buildWorkbook(business, monthDataList, params);

    final fileName =
        'DAE1B_${params.businessId}_${params.year}_${params.months.join('-')}_'
        '${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final storagePath = 'dae1b/$fileName';

    await _sb.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
        );

    final fileUrl = _sb.storage.from(_bucket).getPublicUrl(storagePath);

    // Log to reports table — one row per month covered
    for (final month in params.months) {
      await _sb.from('reports').insert({
        'report_type': 'DAE-1B',
        'period_month': month,
        'period_year': params.year,
        'file_url': fileUrl,
        'generated_by': _sb.auth.currentUser?.id,
        'include_sheet_establishment': true,
        'include_sheet_country_sum': true,
        'include_sheet_monthly': true,
      });
    }

    return fileUrl;
  }

  // ── DATA FETCHING ────────────────────────────────────────────────────────

  Future<_BusinessInfo> _fetchBusiness(String businessId) async {
    final row = await _sb
        .from('businesses')
        .select('business_name, business_type, region, city_municipality, province, total_rooms')
        .eq('id', businessId)
        .single();
    return _BusinessInfo(
      name: row['business_name'] ?? '',
      businessType: row['business_type'] ?? '',
      region: row['region'] ?? '4-A',
      cityMunicipality: row['city_municipality'] ?? '',
      province: row['province'] ?? '',
      totalRooms: row['total_rooms'] ?? 0,
    );
  }

  Future<_MonthData> _fetchMonthData(
      String businessId, int month, int year) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0); // last day of month
    final daysInMonth = lastDay.day;
    final roomsAvailable = 0; // will be summed from records below

    // Pull guest_records for this business + month
    final records = await _sb
        .from('guest_records')
        .select('id, check_in, check_out, rooms_occupied')
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .gte('check_in', firstDay.toIso8601String().substring(0, 10))
        .lte('check_in', lastDay.toIso8601String().substring(0, 10));

    final recordIds = (records as List).map((r) => r['id'] as String).toList();

    // Pull all breakdowns for these records
    List breakdowns = [];
    if (recordIds.isNotEmpty) {
      breakdowns = await _sb
          .from('guest_breakdowns')
          .select('guest_record_id, country, sex, residence_category, count')
          .inFilter('guest_record_id', recordIds);
    }

    // Map record_id → check_in day and rooms_occupied
    final Map<String, int> recordDay = {};
    final Map<String, int> recordRooms = {};
    int totalGuestNights = 0;
    int totalRoomsOccupied = 0;

    for (final r in records) {
      final checkIn = DateTime.parse(r['check_in']);
      final checkOut = DateTime.parse(r['check_out']);
      final day = checkIn.day;
      recordDay[r['id']] = day;
      recordRooms[r['id']] = r['rooms_occupied'] ?? 0;
      totalGuestNights += (checkOut.difference(checkIn).inDays).abs();
      totalRoomsOccupied += (r['rooms_occupied'] as int? ?? 0);
    }

    // Build aggregation maps
    final _DayCountMap countryByDay = {};
    final Map<int, Map<String, int>> residentsByDay = {};
    final Map<int, Map<String, Map<String, int>>> sexByDay = {};
    final Map<int, int> roomsOccupiedByDay = {};

    for (final r in records) {
      final day = recordDay[r['id']]!;
      roomsOccupiedByDay[day] = (roomsOccupiedByDay[day] ?? 0) + (r['rooms_occupied'] as int? ?? 0);
    }

    for (final b in breakdowns) {
      final recId = b['guest_record_id'] as String;
      final day = recordDay[recId] ?? 1;
      final country = (b['country'] as String).toUpperCase().trim();
      final sex = (b['sex'] as String).toLowerCase();
      final residenceCat = b['residence_category'] as String;
      final count = b['count'] as int;

      // Country day map (non-Philippine residents)
      if (residenceCat != 'philippine_resident' &&
          residenceCat != 'overseas_filipino') {
        countryByDay.putIfAbsent(country, () => {});
        countryByDay[country]![day] =
            (countryByDay[country]![day] ?? 0) + count;
        // also accumulate into day=0 (total)
        countryByDay[country]![0] =
            (countryByDay[country]![0] ?? 0) + count;
      }

      // Residents by day
      residentsByDay.putIfAbsent(day, () => {});
      residentsByDay[day]![residenceCat] =
          (residentsByDay[day]![residenceCat] ?? 0) + count;
      residentsByDay[0] ??= {};
      residentsByDay[0]![residenceCat] =
          (residentsByDay[0]![residenceCat] ?? 0) + count;

      // Sex by day
      sexByDay.putIfAbsent(day, () => {});
      sexByDay[day]!.putIfAbsent(sex, () => {});
      sexByDay[day]![sex]![residenceCat] =
          (sexByDay[day]![sex]![residenceCat] ?? 0) + count;
      sexByDay[0] ??= {};
      sexByDay[0]!.putIfAbsent(sex, () => {});
      sexByDay[0]![sex]![residenceCat] =
          (sexByDay[0]![sex]![residenceCat] ?? 0) + count;
    }

    return _MonthData(
      month: month,
      countryByDay: countryByDay,
      residentsByDay: residentsByDay,
      sexByDay: sexByDay,
      roomsOccupied: roomsOccupiedByDay,
      guestNights: totalGuestNights,
      roomsAvailable: 0, // populated per-sheet using business.totalRooms
    );
  }

  // ── WORKBOOK BUILDER ─────────────────────────────────────────────────────

  Uint8List _buildWorkbook(
    _BusinessInfo biz,
    List<_MonthData> monthDataList,
    ReportParams params,
  ) {
    final excel = Excel.createExcel();

    // Remove default sheet
    excel.delete('Sheet1');

    for (final md in monthDataList) {
      final daysInMonth = DateTime(params.year, md.month + 1, 0).day;
      _buildSheet1(excel, biz, md, params.year, daysInMonth);
    }

    _buildSheet2(excel, biz, monthDataList, params.year);
    _buildSheet3(excel, biz, monthDataList, params.year);

    final encoded = excel.encode();
    return Uint8List.fromList(encoded!);
  }

  // ── SHEET 1: Daily breakdown per month ───────────────────────────────────

  void _buildSheet1(
    Excel excel,
    _BusinessInfo biz,
    _MonthData md,
    int year,
    int daysInMonth,
  ) {
    final sheetName = 'Daily ${kMonthNames[md.month]}';
    final sheet = excel[sheetName];

    int row = 0;

    // ── Header ──────────────────────────────────────────────────────────────
    _cell(sheet, row++, 0, 'DAE-1B (Manual)');
    _cell(sheet, row++, 0, 'Region: ${biz.region}');
    _cell(sheet, row++, 0,
        '${kMonthNames[md.month]}, $year');
    _cell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS');
    _cell(sheet, row++, 0, 'Type of Accommodation: ${_formatBusinessType(biz.businessType)}');
    _cell(sheet, row++, 0, 'City/Municipality: ${biz.cityMunicipality}');
    _cell(sheet, row++, 0, 'Province: ${biz.province}');
    row++;

    // ── Column headers: COUNTRY OF RESIDENCE | 1 | 2 | … | 31 | TOTAL ─────
    final headers = <String>['COUNTRY OF RESIDENCE'];
    for (int d = 1; d <= 31; d++) headers.add(d.toString());
    headers.add('TOTAL');
    _row(sheet, row++, headers, bold: true);

    // Helper: get count for a country on a specific day (0 = total)
    int cnt(String country, int day) =>
        md.countryByDay[country.toUpperCase()]?[day] ?? 0;

    // Helper: get resident-category count for a day
    int res(int day, String cat) =>
        md.residentsByDay[day]?[cat] ?? 0;

    // Helper: write a data row with values for days 1–daysInMonth, 0 for rest, total
    void dataRow(String label, List<int> Function(int day) dayFn) {
      final cells = <Object?>[label];
      int total = 0;
      for (int d = 1; d <= 31; d++) {
        if (d <= daysInMonth) {
          final v = dayFn(d).fold<int>(0, (a, b) => a + b);
          cells.add(v == 0 ? null : v);
          total += v;
        } else {
          cells.add(null);
        }
      }
      cells.add(total == 0 ? 0 : total);
      _row(sheet, row++, cells.map((e) => e?.toString() ?? '').toList());
    }

    // ── PHILIPPINE RESIDENTS ─────────────────────────────────────────────
    _cell(sheet, row++, 0, 'PHILIPPINE RESIDENTS', bold: true);
    dataRow('   FILIPINO NATIONALITY',
        (d) => [res(d, 'philippine_resident_filipino')]);
    dataRow('   FOREIGN NATIONALITY',
        (d) => [res(d, 'philippine_resident_foreign')]);

    // Sub-total row Philippine Residents
    final prRow = row;
    final cells = <String>['TOTAL PHILIPPINE RESIDENTS'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v = res(d, 'philippine_resident_filipino') +
            res(d, 'philippine_resident_foreign');
        cells.add(v == 0 ? '0' : v.toString());
      } else {
        cells.add('0');
      }
    }
    final prTotal = (res(0, 'philippine_resident_filipino') +
        res(0, 'philippine_resident_foreign'));
    cells.add(prTotal.toString());
    _row(sheet, row++, cells, bold: true);

    row++;
    _cell(sheet, row++, 0, 'NON-PHILIPPINE RESIDENTS', bold: true);
    row++;

    // ── Country rows ─────────────────────────────────────────────────────
    String? lastRegion, lastSubRegion;
    final subRegionStartRows = <String, int>{};
    final subRegionEndRows = <String, int>{};

    for (final cg in kCountryRows) {
      if (cg.region != lastRegion) {
        _cell(sheet, row++, 0, cg.region, bold: true);
        lastRegion = cg.region;
        lastSubRegion = null;
      }
      if (cg.subRegion != lastSubRegion &&
          cg.subRegion != cg.region) {
        _cell(sheet, row++, 0, '   ${cg.subRegion}', bold: true);
        lastSubRegion = cg.subRegion;
      }

      subRegionStartRows.putIfAbsent('${cg.region}|${cg.subRegion}', () => row);
      dataRow('       ${cg.country}', (d) => [cnt(cg.country, d)]);
      subRegionEndRows['${cg.region}|${cg.subRegion}'] = row - 1;

      // Write SUB-TOTAL after last country in sub-region
      final isLast = kCountryRows.indexOf(cg) == kCountryRows.length - 1 ||
          kCountryRows[kCountryRows.indexOf(cg) + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subKey = '${cg.region}|${cg.subRegion}';
        final subCols = <String>['                 SUB-TOTAL'];
        final countriesInSub = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .map((x) => x.country)
            .toList();
        int subTotal = 0;
        for (int d = 1; d <= 31; d++) {
          if (d <= daysInMonth) {
            final v = countriesInSub.fold<int>(0, (a, c) => a + cnt(c, d));
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

    // ── OTHERS AND UNSPECIFIED ───────────────────────────────────────────
    dataRow('OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES',
        (d) => [res(d, 'unspecified_guest')]);

    // TOTAL NON-PHILIPPINE RESIDENTS
    final nprCols = <String>['TOTAL NON-PHILIPPINE RESIDENTS'];
    int nprTotal = 0;
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v = kCountryRows.fold<int>(0, (a, cg) => a + cnt(cg.country, d)) +
            res(d, 'unspecified_guest');
        nprCols.add(v == 0 ? '0' : v.toString());
        nprTotal += v;
      } else {
        nprCols.add('0');
      }
    }
    nprCols.add(nprTotal.toString());
    _row(sheet, row++, nprCols, bold: true);

    // OVERSEAS FILIPINOS
    dataRow('OVERSEAS FILIPINOS*', (d) => [res(d, 'overseas_filipino')]);

    // GRAND TOTAL
    final gtCols = <String>['GRAND TOTAL GUEST ARRIVALS'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v = res(d, 'philippine_resident_filipino') +
            res(d, 'philippine_resident_foreign') +
            kCountryRows.fold<int>(0, (a, cg) => a + cnt(cg.country, d)) +
            res(d, 'unspecified_guest') +
            res(d, 'overseas_filipino');
        gtCols.add(v == 0 ? '0' : v.toString());
      } else {
        gtCols.add('0');
      }
    }
    final gtTotal = (res(0, 'philippine_resident_filipino') +
        res(0, 'philippine_resident_foreign') +
        kCountryRows.fold<int>(0, (a, cg) => a + cnt(cg.country, 0)) +
        res(0, 'unspecified_guest') +
        res(0, 'overseas_filipino'));
    gtCols.add(gtTotal.toString());
    _row(sheet, row++, gtCols, bold: true);

    // Summary breakdown rows
    void summaryRow(String label, String cat) {
      final cols = <String>[label];
      for (int d = 1; d <= 31; d++) {
        if (d <= daysInMonth) {
          final v = res(d, cat);
          cols.add(v == 0 ? '0' : v.toString());
        } else {
          cols.add('0');
        }
      }
      cols.add(res(0, cat).toString());
      _row(sheet, row++, cols);
    }

    summaryRow('   Total Philippine Residents', 'philippine_resident_filipino');
    summaryRow('   Total Non-Philippine Residents', 'unspecified_guest');
    summaryRow('   Total Overseas Filipinos', 'overseas_filipino');

    row += 2;

    // ── PART II ─────────────────────────────────────────────────────────
    _cell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _cell(sheet, row++, 0, 'A. DAE2:');

    // Rooms occupied per day
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

    // Rooms available (total_rooms * daysInMonth) — constant per day
    final availCols = <String>['2. Rooms available for the month'];
    for (int d = 1; d <= 31; d++) {
      availCols.add(d <= daysInMonth ? biz.totalRooms.toString() : '');
    }
    availCols.add((biz.totalRooms * daysInMonth).toString());
    _row(sheet, row++, availCols);

    // Guest nights (check_out - check_in per record, summed)
    final gnCols = <String>['3. Total Guest nights'];
    for (int d = 1; d <= 31; d++) gnCols.add('');
    gnCols.add(md.guestNights.toString());
    _row(sheet, row++, gnCols);

    row++;
    _cell(sheet, row++, 0, 'Alternative Submission');

    // Average Monthly Occupancy Rate = Total Rooms Occ / Rooms Available
    final occCols = <String>['1. Average Monthly Occupancy Rate'];
    for (int d = 1; d <= 31; d++) occCols.add('');
    final roomsAvail = biz.totalRooms * daysInMonth;
    final occRate = roomsAvail > 0
        ? '${(totalRoomsOcc / roomsAvail * 100).toStringAsFixed(2)}%'
        : '0%';
    occCols.add(occRate);
    _row(sheet, row++, occCols);

    // Average Length of Stay = Guest Nights / Grand Total Guests
    final alsCols = <String>['2. Average Length of Stay (in Nights)'];
    for (int d = 1; d <= 31; d++) alsCols.add('');
    final als = gtTotal > 0
        ? (md.guestNights / gtTotal).toStringAsFixed(2)
        : '0';
    alsCols.add(als);
    _row(sheet, row++, alsCols);

    row++;
    _cell(sheet, row++, 0, 'B. VOLUME PER SEX', bold: true);

    int sex(int day, String s, String cat) =>
        md.sexByDay[day]?[s]?[cat] ?? 0;

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
    sexRow('b. Non-Philippine/Foreign Residents (including unspecified)',
        'male', 'unspecified_guest');
    sexRow('c. Overseas Filipinos', 'male', 'overseas_filipino');
    sexRow('d. Others/Unspecified Guest', 'male', 'unspecified_guest');

    final maleTotalCols = <String>['x. Total'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v = sex(d, 'male', 'philippine_resident_filipino') +
            sex(d, 'male', 'unspecified_guest') +
            sex(d, 'male', 'overseas_filipino');
        maleTotalCols.add(v == 0 ? '' : v.toString());
      } else {
        maleTotalCols.add('');
      }
    }
    maleTotalCols.add((sex(0, 'male', 'philippine_resident_filipino') +
            sex(0, 'male', 'unspecified_guest') +
            sex(0, 'male', 'overseas_filipino'))
        .toString());
    _row(sheet, row++, maleTotalCols, bold: true);

    _cell(sheet, row++, 0, '2. Female');
    sexRow('a. Philippine Residents', 'female', 'philippine_resident_filipino');
    sexRow('b. Non-Philippine/Foreign Residents (including unspecified)',
        'female', 'unspecified_guest');
    sexRow('c. Overseas Filipinos', 'female', 'overseas_filipino');
    sexRow('d. Others/Unspecified Guest', 'female', 'unspecified_guest');

    final femaleTotalCols = <String>['x. Total'];
    for (int d = 1; d <= 31; d++) {
      if (d <= daysInMonth) {
        final v = sex(d, 'female', 'philippine_resident_filipino') +
            sex(d, 'female', 'unspecified_guest') +
            sex(d, 'female', 'overseas_filipino');
        femaleTotalCols.add(v == 0 ? '' : v.toString());
      } else {
        femaleTotalCols.add('');
      }
    }
    femaleTotalCols.add((sex(0, 'female', 'philippine_resident_filipino') +
            sex(0, 'female', 'unspecified_guest') +
            sex(0, 'female', 'overseas_filipino'))
        .toString());
    _row(sheet, row++, femaleTotalCols, bold: true);

    row += 2;
    _cell(sheet, row++, 0,
        '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos');
    row++;
    _cell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ── SHEET 2: Monthly totals by country (sum of selected months) ──────────

  void _buildSheet2(
    Excel excel,
    _BusinessInfo biz,
    List<_MonthData> monthDataList,
    int year,
  ) {
    final sheet = excel['Country Summary'];
    int row = 0;

    final monthLabel = monthDataList.length == 1
        ? kMonthNames[monthDataList.first.month]
        : '${kMonthNames[monthDataList.first.month]}–${kMonthNames[monthDataList.last.month]}';

    _cell(sheet, row++, 0, 'DAE-1B (Manual-Summary)');
    _cell(sheet, row++, 0, 'Region: ${biz.region}');
    _cell(sheet, row++, 0, '$monthLabel, $year');
    _cell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS');
    _cell(sheet, row++, 0, 'Type of Accommodation: ${_formatBusinessType(biz.businessType)}');
    _cell(sheet, row++, 0, 'City/Municipality: ${biz.cityMunicipality}');
    _cell(sheet, row++, 0, 'Province: ${biz.province}');
    row++;

    _row(sheet, row++, ['COUNTRY OF RESIDENCE', 'TOTAL'], bold: true);

    // Merge all months
    int totCnt(String country) => monthDataList.fold<int>(
        0, (a, md) => a + (md.countryByDay[country.toUpperCase()]?[0] ?? 0));
    int totRes(String cat) => monthDataList.fold<int>(
        0, (a, md) => a + (md.residentsByDay[0]?[cat] ?? 0));

    _cell(sheet, row++, 0, 'PHILIPPINE RESIDENTS', bold: true);
    _row(sheet, row++, ['   FILIPINO NATIONALITY', totRes('philippine_resident_filipino').toString()]);
    _row(sheet, row++, ['   FOREIGN NATIONALITY', totRes('philippine_resident_foreign').toString()]);
    _row(sheet, row++, [
      'TOTAL PHILIPPINE RESIDENTS',
      (totRes('philippine_resident_filipino') + totRes('philippine_resident_foreign')).toString()
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
      _row(sheet, row++, ['       ${cg.country}', totCnt(cg.country).toString()]);

      final isLast = kCountryRows.indexOf(cg) == kCountryRows.length - 1 ||
          kCountryRows[kCountryRows.indexOf(cg) + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subTotal = kCountryRows
            .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
            .fold<int>(0, (a, x) => a + totCnt(x.country));
        _row(sheet, row++, ['                 SUB-TOTAL', subTotal.toString()], bold: true);
        row++;
      }
    }

    _row(sheet, row++, [
      'OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES',
      totRes('unspecified_guest').toString()
    ]);
    final nprTotal = kCountryRows.fold<int>(0, (a, cg) => a + totCnt(cg.country)) +
        totRes('unspecified_guest');
    _row(sheet, row++, ['TOTAL NON-PHILIPPINE RESIDENTS', nprTotal.toString()], bold: true);
    _row(sheet, row++, ['OVERSEAS FILIPINOS*', totRes('overseas_filipino').toString()]);

    final grandTotal = totRes('philippine_resident_filipino') +
        totRes('philippine_resident_foreign') +
        nprTotal +
        totRes('overseas_filipino');
    _row(sheet, row++, ['GRAND TOTAL GUEST ARRIVALS', grandTotal.toString()], bold: true);

    row += 2;
    _cell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _cell(sheet, row++, 0, 'A. DAE2:');

    int sumRoomsOcc = monthDataList.fold<int>(
        0, (a, md) => a + md.roomsOccupied.values.fold<int>(0, (x, y) => x + y));
    int sumNights = monthDataList.fold<int>(0, (a, md) => a + md.guestNights);
    int sumRoomsAvail = monthDataList.fold<int>(
        0,
        (a, md) =>
            a + biz.totalRooms * DateTime(year, md.month + 1, 0).day);

    _row(sheet, row++, ['1. Rooms Occupied', sumRoomsOcc.toString()]);
    _row(sheet, row++, ['2. Rooms available for the month', sumRoomsAvail.toString()]);
    _row(sheet, row++, ['3. Total Guest nights', sumNights.toString()]);
    row++;
    _cell(sheet, row++, 0, 'Alternative Submission');
    final occRate = sumRoomsAvail > 0
        ? '${(sumRoomsOcc / sumRoomsAvail * 100).toStringAsFixed(2)}%'
        : '0%';
    _row(sheet, row++, ['1. Average Monthly Occupancy Rate', occRate]);
    final als = grandTotal > 0
        ? (sumNights / grandTotal).toStringAsFixed(2)
        : '0';
    _row(sheet, row++, ['2. Average Length of Stay (in Nights)', als]);

    row++;
    _cell(sheet, row++, 0, 'B. VOLUME PER SEX', bold: true);
    int totSex(String s, String cat) => monthDataList.fold<int>(
        0, (a, md) => a + (md.sexByDay[0]?[s]?[cat] ?? 0));

    _cell(sheet, row++, 0, '1. Male');
    _row(sheet, row++, ['a. Philippine Residents', totSex('male', 'philippine_resident_filipino').toString()]);
    _row(sheet, row++, ['b. Non-Philippine/Foreign Residents (including unspecified)', totSex('male', 'unspecified_guest').toString()]);
    _row(sheet, row++, ['c. Overseas Filipinos', totSex('male', 'overseas_filipino').toString()]);
    _row(sheet, row++, ['d. Others/Unspecified Guest', totSex('male', 'unspecified_guest').toString()]);
    _row(sheet, row++, ['x. Total', (totSex('male', 'philippine_resident_filipino') + totSex('male', 'unspecified_guest') + totSex('male', 'overseas_filipino')).toString()], bold: true);

    _cell(sheet, row++, 0, '2. Female');
    _row(sheet, row++, ['a. Philippine Residents', totSex('female', 'philippine_resident_filipino').toString()]);
    _row(sheet, row++, ['b. Non-Philippine/Foreign Residents (including unspecified)', totSex('female', 'unspecified_guest').toString()]);
    _row(sheet, row++, ['c. Overseas Filipinos', totSex('female', 'overseas_filipino').toString()]);
    _row(sheet, row++, ['d. Others/Unspecified Guest', totSex('female', 'unspecified_guest').toString()]);
    _row(sheet, row++, ['x. Total', (totSex('female', 'philippine_resident_filipino') + totSex('female', 'unspecified_guest') + totSex('female', 'overseas_filipino')).toString()], bold: true);

    row += 2;
    _cell(sheet, row++, 0, '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos');
    row++;
    _cell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ── SHEET 3: Month-by-month comparison ───────────────────────────────────

  void _buildSheet3(
    Excel excel,
    _BusinessInfo biz,
    List<_MonthData> monthDataList,
    int year,
  ) {
    final sheet = excel['Monthly Comparison'];
    int row = 0;

    _cell(sheet, row++, 0, 'DAE-1B (Manual-Summary)');
    _cell(sheet, row++, 0, 'Region: ${biz.region}');
    _cell(sheet, row++, 0, '$year');
    _cell(sheet, row++, 0, 'REPORT ON THE REGIONAL DISTRIBUTION OF TRAVELERS');
    _cell(sheet, row++, 0, 'Type of Accommodation: ${_formatBusinessType(biz.businessType)}');
    _cell(sheet, row++, 0, 'City/Municipality: ${biz.cityMunicipality}');
    _cell(sheet, row++, 0, 'Province: ${biz.province}');
    row++;

    // Headers: COUNTRY OF RESIDENCE | [MONTH NAME …] | TOTAL
    final headers = <String>['COUNTRY OF RESIDENCE'];
    for (final md in monthDataList) headers.add(kMonthNames[md.month]);
    headers.add('TOTAL');
    _row(sheet, row++, headers, bold: true);

    // Helpers
    int mCnt(String country, int month) {
      final md = monthDataList.firstWhere((m) => m.month == month,
          orElse: () => _emptyMonth(month));
      return md.countryByDay[country.toUpperCase()]?[0] ?? 0;
    }

    int mRes(int month, String cat) {
      final md = monthDataList.firstWhere((m) => m.month == month,
          orElse: () => _emptyMonth(month));
      return md.residentsByDay[0]?[cat] ?? 0;
    }

    void dataRow3(String label, int Function(int month) fn) {
      final cols = <String>[label];
      int total = 0;
      for (final md in monthDataList) {
        final v = fn(md.month);
        cols.add(v == 0 ? '' : v.toString());
        total += v;
      }
      cols.add(total.toString());
      _row(sheet, row++, cols);
    }

    _cell(sheet, row++, 0, 'PHILIPPINE RESIDENTS', bold: true);
    dataRow3('   FILIPINO NATIONALITY',
        (m) => mRes(m, 'philippine_resident_filipino'));
    dataRow3('   FOREIGN NATIONALITY',
        (m) => mRes(m, 'philippine_resident_foreign'));

    final prCols = <String>['TOTAL PHILIPPINE RESIDENTS'];
    int prGrandTotal = 0;
    for (final md in monthDataList) {
      final v = mRes(md.month, 'philippine_resident_filipino') +
          mRes(md.month, 'philippine_resident_foreign');
      prCols.add(v.toString());
      prGrandTotal += v;
    }
    prCols.add(prGrandTotal.toString());
    _row(sheet, row++, prCols, bold: true);

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
      dataRow3('       ${cg.country}', (m) => mCnt(cg.country, m));

      final isLast = kCountryRows.indexOf(cg) == kCountryRows.length - 1 ||
          kCountryRows[kCountryRows.indexOf(cg) + 1].subRegion != cg.subRegion;
      if (isLast) {
        final subCols = <String>['                 SUB-TOTAL'];
        int subGrand = 0;
        for (final md in monthDataList) {
          final v = kCountryRows
              .where((x) => x.region == cg.region && x.subRegion == cg.subRegion)
              .fold<int>(0, (a, x) => a + mCnt(x.country, md.month));
          subCols.add(v.toString());
          subGrand += v;
        }
        subCols.add(subGrand.toString());
        _row(sheet, row++, subCols, bold: true);
        row++;
      }
    }

    dataRow3('OTHERS AND UNSPECIFIED NON-PHILIPPINE RESIDENCES',
        (m) => mRes(m, 'unspecified_guest'));

    final nprCols = <String>['TOTAL NON-PHILIPPINE RESIDENTS'];
    int nprGrand = 0;
    for (final md in monthDataList) {
      final v = kCountryRows.fold<int>(0, (a, cg) => a + mCnt(cg.country, md.month)) +
          mRes(md.month, 'unspecified_guest');
      nprCols.add(v.toString());
      nprGrand += v;
    }
    nprCols.add(nprGrand.toString());
    _row(sheet, row++, nprCols, bold: true);

    dataRow3('OVERSEAS FILIPINOS*', (m) => mRes(m, 'overseas_filipino'));

    final gtCols = <String>['GRAND TOTAL GUEST ARRIVALS'];
    int gtGrand = 0;
    for (final md in monthDataList) {
      final v = mRes(md.month, 'philippine_resident_filipino') +
          mRes(md.month, 'philippine_resident_foreign') +
          kCountryRows.fold<int>(0, (a, cg) => a + mCnt(cg.country, md.month)) +
          mRes(md.month, 'unspecified_guest') +
          mRes(md.month, 'overseas_filipino');
      gtCols.add(v.toString());
      gtGrand += v;
    }
    gtCols.add(gtGrand.toString());
    _row(sheet, row++, gtCols, bold: true);

    row += 2;
    _cell(sheet, row++, 0, 'PART II.  Other Indicators', bold: true);
    _cell(sheet, row++, 0, 'A. DAE2:');

    void indRow(String label, int Function(_MonthData md) fn) {
      final cols = <String>[label];
      int total = 0;
      for (final md in monthDataList) {
        final v = fn(md);
        cols.add(v == 0 ? '' : v.toString());
        total += v;
      }
      cols.add(total.toString());
      _row(sheet, row++, cols);
    }

    indRow('1. Rooms Occupied',
        (md) => md.roomsOccupied.values.fold<int>(0, (a, b) => a + b));
    indRow('2. Rooms available for the month',
        (md) => biz.totalRooms * DateTime(year, md.month + 1, 0).day);
    indRow('3. Total Guest nights', (md) => md.guestNights);

    row++;
    _cell(sheet, row++, 0, 'Alternative Submission');

    // Occupancy rate per month
    final occCols = <String>['1. Average Monthly Occupancy Rate'];
    for (final md in monthDataList) {
      final occ = md.roomsOccupied.values.fold<int>(0, (a, b) => a + b);
      final avail = biz.totalRooms * DateTime(year, md.month + 1, 0).day;
      occCols.add(avail > 0 ? '${(occ / avail * 100).toStringAsFixed(2)}%' : '0%');
    }
    occCols.add('');
    _row(sheet, row++, occCols);

    // ALS per month
    final alsCols = <String>['2. Average Length of Stay (in Nights)'];
    for (final md in monthDataList) {
      final guests = mRes(md.month, 'philippine_resident_filipino') +
          mRes(md.month, 'philippine_resident_foreign') +
          kCountryRows.fold<int>(0, (a, cg) => a + mCnt(cg.country, md.month)) +
          mRes(md.month, 'unspecified_guest') +
          mRes(md.month, 'overseas_filipino');
      alsCols.add(guests > 0
          ? (md.guestNights / guests).toStringAsFixed(2)
          : '0');
    }
    alsCols.add('');
    _row(sheet, row++, alsCols);

    row++;
    _cell(sheet, row++, 0, 'B. VOLUME PER SEX', bold: true);

    int mSex(_MonthData md, String s, String cat) =>
        md.sexByDay[0]?[s]?[cat] ?? 0;

    void sexRow3(String label, String s, String cat) {
      final cols = <String>[label];
      int total = 0;
      for (final md in monthDataList) {
        final v = mSex(md, s, cat);
        cols.add(v == 0 ? '' : v.toString());
        total += v;
      }
      cols.add(total.toString());
      _row(sheet, row++, cols);
    }

    _cell(sheet, row++, 0, '1. Male');
    sexRow3('a. Philippine Residents', 'male', 'philippine_resident_filipino');
    sexRow3('b. Non-Philippine/Foreign Residents (including unspecified)', 'male', 'unspecified_guest');
    sexRow3('c. Overseas Filipinos', 'male', 'overseas_filipino');
    sexRow3('d. Others/Unspecified Guest', 'male', 'unspecified_guest');

    final maleCols = <String>['x. Total'];
    int maleGrand = 0;
    for (final md in monthDataList) {
      final v = mSex(md, 'male', 'philippine_resident_filipino') +
          mSex(md, 'male', 'unspecified_guest') +
          mSex(md, 'male', 'overseas_filipino');
      maleCols.add(v.toString());
      maleGrand += v;
    }
    maleCols.add(maleGrand.toString());
    _row(sheet, row++, maleCols, bold: true);

    _cell(sheet, row++, 0, '2. Female');
    sexRow3('a. Philippine Residents', 'female', 'philippine_resident_filipino');
    sexRow3('b. Non-Philippine/Foreign Residents (including unspecified)', 'female', 'unspecified_guest');
    sexRow3('c. Overseas Filipinos', 'female', 'overseas_filipino');
    sexRow3('d. Others/Unspecified Guest', 'female', 'unspecified_guest');

    final femaleCols = <String>['x. Total'];
    int femaleGrand = 0;
    for (final md in monthDataList) {
      final v = mSex(md, 'female', 'philippine_resident_filipino') +
          mSex(md, 'female', 'unspecified_guest') +
          mSex(md, 'female', 'overseas_filipino');
      femaleCols.add(v.toString());
      femaleGrand += v;
    }
    femaleCols.add(femaleGrand.toString());
    _row(sheet, row++, femaleCols, bold: true);

    row += 2;
    _cell(sheet, row++, 0, '* Philippine passport holders permanently residing abroad; excludes overseas Filipino workers and Former Filipinos');
    row++;
    _cell(sheet, row, 0, 'Prepared by: ____________________________________');
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  _MonthData _emptyMonth(int month) => _MonthData(
        month: month,
        countryByDay: {},
        residentsByDay: {},
        sexByDay: {},
        roomsOccupied: {},
        guestNights: 0,
        roomsAvailable: 0,
      );

  void _cell(Sheet sheet, int row, int col, String value,
      {bool bold = false}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    if (bold) {
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  void _row(Sheet sheet, int row, List<String> values, {bool bold = false}) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: c, rowIndex: row));
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
      case 'hotel': return 'Hotel';
      case 'resort': return 'Resort';
      case 'pension_inn': return 'Pension Inn/ Lodge';
      case 'youth_hostel': return 'Youth Hostel/ Dormitory';
      case 'apartel': return 'Apartel/ Rented Homes/ Apartment';
      default: return raw;
    }
  }
}