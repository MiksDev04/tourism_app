// ignore_for_file: inference_failure_on_function_invocation

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/core/database/local_database.dart';
import 'package:tourism_app/core/services/offline_service.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class DashboardStats {
  const DashboardStats({
    required this.guestsThisMonth,
    required this.guestsThisYear,
    required this.avgLengthOfStay,
    required this.totalRooms,
  });

  final int guestsThisMonth;
  final int guestsThisYear;
  final double avgLengthOfStay;
  final int totalRooms;
}

class SexDistribution {
  const SexDistribution({
    required this.male,
    required this.female,
    required this.other,
  });

  final int male;
  final int female;
  final int other;

  int get total => male + female + other;
  double get maleRatio => total == 0 ? 0 : male / total;
  double get femaleRatio => total == 0 ? 0 : female / total;
}

class CountryCount {
  const CountryCount({required this.country, required this.count});

  final String country;
  final int count;
}

class RegionCount {
  const RegionCount({required this.region, required this.count});

  final String region;
  final int count;
}

class MonthlyCount {
  const MonthlyCount({required this.month, required this.count});

  final int month; // 1–12
  final int count;
}

class DashboardData {
  const DashboardData({
    required this.stats,
    required this.sexDistribution,
    required this.topCountries,
    required this.topRegions,
  });

  final DashboardStats stats;
  final SexDistribution sexDistribution;
  final List<CountryCount> topCountries;
  final List<RegionCount> topRegions;
}

class BusinessDetails {
  const BusinessDetails({
    required this.address,
    required this.totalRooms,
    required this.businessLine,
  });

  final String address;
  final int totalRooms;
  final List<String> businessLine;
}

// ─── API ──────────────────────────────────────────────────────────────────────

class BusinessDashboardApi {
  BusinessDashboardApi({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  // ── Date helpers ─────────────────────────────────────────────────────────────

  (String start, String end) _dateRange(int month, int year) {
    if (month == 0) {
      return ('$year-01-01', '$year-12-31');
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    final mm      = month.toString().padLeft(2, '0');
    final dd      = lastDay.toString().padLeft(2, '0');
    return ('$year-$mm-01', '$year-$mm-$dd');
  }

  // ===========================================================================
  // PUBLIC — fetchBusinessDetails
  // ===========================================================================

  Future<BusinessDetails> fetchBusinessDetails(String businessId) async {
    if (!ConnectivityService.instance.isOnline) {
      return _fetchBusinessDetailsOffline(businessId);
    }
    return _fetchBusinessDetailsOnline(businessId);
  }

  Future<BusinessDetails> _fetchBusinessDetailsOnline(String businessId) async {
    final response = await _supabase
        .from('businesses')
        .select('street, total_rooms, business_line')
        .eq('id', businessId)
        .maybeSingle();

    if (response == null) {
      return const BusinessDetails(address: '', totalRooms: 0, businessLine: []);
    }

    final street          = (response['street'] as String?) ?? '';
    final rawBusinessLine = response['business_line'];
    final businessLine    = rawBusinessLine is List
        ? rawBusinessLine.map((v) => v.toString()).toList()
        : <String>[];

    return BusinessDetails(
      address:      street,
      totalRooms:   (response['total_rooms'] as int?) ?? 0,
      businessLine: businessLine,
    );
  }

  Future<BusinessDetails> _fetchBusinessDetailsOffline(String businessId) async {
    final db   = await LocalDatabase.instance.database;
    final rows = await db.query(
      LocalDatabase.tableLocalBusinesses,
      where:     'id = ?',
      whereArgs: [businessId],
      limit:     1,
    );

    if (rows.isEmpty) {
      return const BusinessDetails(address: '', totalRooms: 0, businessLine: []);
    }

    final row             = rows.first;
    final street          = (row['street'] as String?) ?? '';
    final rawBusinessLine = row['business_line'] as String?;

    // business_line is stored as a JSON string e.g. '["Hotel","Resort"]'
    List<String> businessLine = [];
    if (rawBusinessLine != null && rawBusinessLine.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBusinessLine);
        if (decoded is List) {
          businessLine = decoded.map((v) => v.toString()).toList();
        }
      } catch (_) {
        businessLine = [rawBusinessLine];
      }
    }

    return BusinessDetails(
      address:      street,
      totalRooms:   (row['total_rooms'] as int?) ?? 0,
      businessLine: businessLine,
    );
  }

  // ===========================================================================
  // PUBLIC — fetchDashboardData
  // ===========================================================================

  Future<DashboardData> fetchDashboardData({
    required String businessId,
    required int totalRooms,
    required int month,
    required int year,
  }) async {
    if (!ConnectivityService.instance.isOnline) {
      return _fetchDashboardDataOffline(
        businessId: businessId,
        totalRooms: totalRooms,
        month:      month,
        year:       year,
      );
    }
    return _fetchDashboardDataOnline(
      businessId: businessId,
      totalRooms: totalRooms,
      month:      month,
      year:       year,
    );
  }

  // ===========================================================================
  // ONLINE — existing Supabase logic unchanged
  // ===========================================================================

  Future<DashboardData> _fetchDashboardDataOnline({
    required String businessId,
    required int totalRooms,
    required int month,
    required int year,
  }) async {
    final (start, end)         = _dateRange(month, year);
    final (yearStart, yearEnd) = _dateRange(0, year);

    final periodRecords = await _fetchGuestRecordsOnline(
      businessId: businessId,
      startDate:  start,
      endDate:    end,
    );

    final yearRecords = (month == 0)
        ? periodRecords
        : await _fetchGuestRecordsOnline(
            businessId: businessId,
            startDate:  yearStart,
            endDate:    yearEnd,
          );

    final stats = _computeStats(
      periodRecords: periodRecords,
      yearRecords:   yearRecords,
      totalRooms:    totalRooms,
    );

    final recordIds = periodRecords
        .map((r) => _stringValue(r, 'id'))
        .whereType<String>()
        .toList();

    final breakdowns = await _fetchBreakdownsOnline(recordIds);

    return _computeDashboardData(stats: stats, breakdowns: breakdowns);
  }

  Future<List<Map<String, dynamic>>> _fetchGuestRecordsOnline({
    required String businessId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _supabase
        .from('guest_records')
        .select('id, check_in, check_out, total_guests, rooms_occupied')
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .eq('status', 'active')
        .gte('check_in', startDate)
        .lte('check_in', endDate);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> _fetchBreakdownsOnline(
    List<String> recordIds,
  ) async {
    if (recordIds.isEmpty) return [];
    final response = await _supabase
        .from('guest_breakdowns')
        .select(
          'guest_record_id, country, philippines_region, sex, age_group, count',
        )
        .inFilter('guest_record_id', recordIds);

    return List<Map<String, dynamic>>.from(response as List);
  }

  // ===========================================================================
  // OFFLINE — read from SQLite
  // ===========================================================================

  Future<DashboardData> _fetchDashboardDataOffline({
    required String businessId,
    required int totalRooms,
    required int month,
    required int year,
  }) async {
    final (start, end)         = _dateRange(month, year);
    final (yearStart, yearEnd) = _dateRange(0, year);

    final periodRecords = await _fetchGuestRecordsOffline(
      businessId: businessId,
      startDate:  start,
      endDate:    end,
    );

    final yearRecords = (month == 0)
        ? periodRecords
        : await _fetchGuestRecordsOffline(
            businessId: businessId,
            startDate:  yearStart,
            endDate:    yearEnd,
          );

    final stats = _computeStats(
      periodRecords: periodRecords,
      yearRecords:   yearRecords,
      totalRooms:    totalRooms,
    );

    final recordIds = periodRecords
        .map((r) => _stringValue(r, 'id'))
        .whereType<String>()
        .toList();

    final breakdowns = await _fetchBreakdownsOffline(recordIds);

    return _computeDashboardData(stats: stats, breakdowns: breakdowns);
  }

  Future<List<Map<String, dynamic>>> _fetchGuestRecordsOffline({
    required String businessId,
    required String startDate,
    required String endDate,
  }) async {
    final db   = await LocalDatabase.instance.database;
    final rows = await db.query(
      LocalDatabase.tableGuestRecords,
      columns:   ['id', 'check_in', 'check_out', 'total_guests', 'rooms_occupied'],
      where:     'business_id = ? AND is_deleted = 0 AND status = ? '
                 'AND check_in >= ? AND check_in <= ?',
      whereArgs: [businessId, 'active', startDate, endDate],
    );
    // Convert Map<String, Object?> to Map<String, dynamic>
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchBreakdownsOffline(
    List<String> recordIds,
  ) async {
    if (recordIds.isEmpty) return [];

    final db = await LocalDatabase.instance.database;

    // SQLite doesn't support inFilter so we build a placeholder string.
    final placeholders = recordIds.map((_) => '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT guest_record_id, country, philippines_region, sex, age_group, count '
      'FROM ${LocalDatabase.tableGuestBreakdowns} '
      'WHERE guest_record_id IN ($placeholders)',
      recordIds,
    );

    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  // ===========================================================================
  // SHARED — pure computation (same logic for online and offline)
  // ===========================================================================

  DashboardStats _computeStats({
    required List<Map<String, dynamic>> periodRecords,
    required List<Map<String, dynamic>> yearRecords,
    required int totalRooms,
  }) {
    final guestsThisMonth = periodRecords.fold<int>(
      0,
      (s, r) => s + ((_intValue(r, 'total_guests')) ?? 0),
    );
    final guestsThisYear = yearRecords.fold<int>(
      0,
      (s, r) => s + ((_intValue(r, 'total_guests')) ?? 0),
    );

    double avgStay = 0;
    if (periodRecords.isNotEmpty) {
      double totalNights  = 0;
      int validStayCount  = 0;
      for (final r in periodRecords) {
        final checkInText  = _stringValue(r, 'check_in');
        final checkOutText = _stringValue(r, 'check_out');
        if (checkInText == null || checkOutText == null) continue;
        final checkIn  = DateTime.tryParse(checkInText);
        final checkOut = DateTime.tryParse(checkOutText);
        if (checkIn == null || checkOut == null) continue;
        totalNights += checkOut.difference(checkIn).inDays;
        validStayCount++;
      }
      if (validStayCount > 0) avgStay = totalNights / validStayCount;
    }

    return DashboardStats(
      guestsThisMonth: guestsThisMonth,
      guestsThisYear:  guestsThisYear,
      avgLengthOfStay: avgStay,
      totalRooms:      totalRooms,
    );
  }

  DashboardData _computeDashboardData({
    required DashboardStats stats,
    required List<Map<String, dynamic>> breakdowns,
  }) {
    // Sex distribution
    int male = 0, female = 0, genderOther = 0;
    for (final b in breakdowns) {
      final sex = _stringValue(b, 'sex')?.toLowerCase() ?? '';
      final cnt = (_intValue(b, 'count')) ?? 0;
      if (sex == 'male') {
        male += cnt;
      } else if (sex == 'female') {
        female += cnt;
      } else {
        genderOther += cnt;
      }
    }

    // Top 5 countries
    final countryMap = <String, int>{};
    for (final b in breakdowns) {
      final country = _stringValue(b, 'country') ?? 'Unknown';
      countryMap[country] =
          (countryMap[country] ?? 0) + ((_intValue(b, 'count')) ?? 0);
    }
    final topCountries = (countryMap.entries
            .map((e) => CountryCount(country: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(5)
        .toList();

    // Top 5 local regions
    final regionMap = <String, int>{};
    for (final b in breakdowns) {
      final region = _stringValue(b, 'philippines_region');
      if (region != null && region.isNotEmpty) {
        regionMap[region] =
            (regionMap[region] ?? 0) + ((_intValue(b, 'count')) ?? 0);
      }
    }
    final topRegions = (regionMap.entries
            .map((e) => RegionCount(region: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(5)
        .toList();

    return DashboardData(
      stats:           stats,
      sexDistribution: SexDistribution(
        male:   male,
        female: female,
        other:  genderOther,
      ),
      topCountries: topCountries,
      topRegions:   topRegions,
    );
  }

  // ===========================================================================
  // PUBLIC — fetchYearlyComparison
  // ===========================================================================

  Future<Map<int, List<MonthlyCount>>> fetchYearlyComparison({
    required String businessId,
    required List<int> years,
  }) async {
    if (!ConnectivityService.instance.isOnline) {
      return _fetchYearlyComparisonOffline(
        businessId: businessId,
        years:      years,
      );
    }
    return _fetchYearlyComparisonOnline(
      businessId: businessId,
      years:      years,
    );
  }

  Future<Map<int, List<MonthlyCount>>> _fetchYearlyComparisonOnline({
    required String businessId,
    required List<int> years,
  }) async {
    final result = <int, List<MonthlyCount>>{};

    for (final year in years) {
      final (start, end) = _dateRange(0, year);
      final records      = await _fetchGuestRecordsOnline(
        businessId: businessId,
        startDate:  start,
        endDate:    end,
      );
      result[year] = _recordsToMonthly(records);
    }

    return result;
  }

  Future<Map<int, List<MonthlyCount>>> _fetchYearlyComparisonOffline({
    required String businessId,
    required List<int> years,
  }) async {
    final result = <int, List<MonthlyCount>>{};

    for (final year in years) {
      final (start, end) = _dateRange(0, year);
      final records      = await _fetchGuestRecordsOffline(
        businessId: businessId,
        startDate:  start,
        endDate:    end,
      );
      result[year] = _recordsToMonthly(records);
    }

    return result;
  }

  List<MonthlyCount> _recordsToMonthly(List<Map<String, dynamic>> records) {
    final monthMap = <int, int>{};
    for (final r in records) {
      final checkInText = _stringValue(r, 'check_in');
      if (checkInText == null) continue;
      final parsed = DateTime.tryParse(checkInText);
      if (parsed == null) continue;
      final m      = parsed.month;
      monthMap[m]  = (monthMap[m] ?? 0) + ((_intValue(r, 'total_guests')) ?? 0);
    }
    return List.generate(
      12,
      (i) => MonthlyCount(month: i + 1, count: monthMap[i + 1] ?? 0),
    );
  }

  // ===========================================================================
  // PUBLIC — generateCsv
  // ===========================================================================

  Future<String> generateCsv({
    required String businessId,
    required String businessName,
    required int month,
    required int year,
  }) async {
    final (start, end) = _dateRange(month, year);

    final records = ConnectivityService.instance.isOnline
        ? await _fetchGuestRecordsOnline(
            businessId: businessId,
            startDate:  start,
            endDate:    end,
          )
        : await _fetchGuestRecordsOffline(
            businessId: businessId,
            startDate:  start,
            endDate:    end,
          );

    final recordIds = records
        .map((r) => _stringValue(r, 'id'))
        .whereType<String>()
        .toList();

    final breakdowns = ConnectivityService.instance.isOnline
        ? await _fetchBreakdownsOnline(recordIds)
        : await _fetchBreakdownsOffline(recordIds);

    final recordMap = <String, Map<String, dynamic>>{
      for (final r in records)
        if (_stringValue(r, 'id') case final id?) id: r,
    };

    final buf = StringBuffer()
      ..writeln('Business,$businessName')
      ..writeln('Period,${month == 0 ? 'Full Year' : _monthName(month)} $year')
      ..writeln()
      ..writeln(
        'Check In,Check Out,Total Guests,Rooms Occupied,'
        'Country,Region,Sex,Age Group,Count',
      );

    for (final b in breakdowns) {
      final recordId = _stringValue(b, 'guest_record_id');
      if (recordId == null) continue;
      final rec = recordMap[recordId];
      if (rec == null) continue;
      final row = [
        _stringValue(rec, 'check_in')           ?? '',
        _stringValue(rec, 'check_out')           ?? '',
        _intValue(rec, 'total_guests')           ?? 0,
        _intValue(rec, 'rooms_occupied')         ?? 0,
        _csvCell(_stringValue(b, 'country')      ?? 'Unknown'),
        _csvCell(_stringValue(b, 'philippines_region') ?? ''),
        _stringValue(b, 'sex')                   ?? '',
        _stringValue(b, 'age_group')             ?? '',
        _intValue(b, 'count')                    ?? 0,
      ];
      buf.writeln(row.join(','));
    }

    return buf.toString();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String? _stringValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value == null ? null : value.toString();
  }

  int? _intValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _csvCell(String value) =>
      value.contains(',') ? '"$value"' : value;

  String _monthName(int month) => const [
    '',
    'January', 'February', 'March',     'April',
    'May',     'June',     'July',      'August',
    'September','October', 'November',  'December',
  ][month];
}