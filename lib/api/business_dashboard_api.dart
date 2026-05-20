// ignore_for_file: inference_failure_on_function_invocation

import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Required pubspec.yaml dependencies ───────────────────────────────────────
// supabase_flutter: ^2.x.x
// pdf: ^3.x.x
// printing: ^5.x.x
// share_plus: ^9.x.x
// path_provider: ^2.x.x

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
  const BusinessDetails({required this.address, required this.totalRooms});

  final String address;
  final int totalRooms;
}

// ─── API ──────────────────────────────────────────────────────────────────────

class BusinessDashboardApi {
  BusinessDashboardApi({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  // ── Date helpers ─────────────────────────────────────────────────────────────

  /// Returns (startDate, endDate) strings.
  /// month == 0 → full year; month 1–12 → that specific month.
  (String start, String end) _dateRange(int month, int year) {
    if (month == 0) {
      return ('$year-01-01', '$year-12-31');
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    final mm = month.toString().padLeft(2, '0');
    final dd = lastDay.toString().padLeft(2, '0');
    return ('$year-$mm-01', '$year-$mm-$dd');
  }

  // ── Raw fetches ───────────────────────────────────────────────────────────────

  Future<BusinessDetails> fetchBusinessDetails(String businessId) async {
    final response = await _supabase
        .from('businesses')
        .select('street, total_rooms')
        .eq('id', businessId)
        .maybeSingle();

    final data = response as Map<String, dynamic>?;
    final street = (data?['street'] as String?) ?? '';
    return BusinessDetails(
      address: street,
      totalRooms: (data?['total_rooms'] as int?) ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchGuestRecords({
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

  Future<List<Map<String, dynamic>>> _fetchBreakdowns(
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

  // ── Main dashboard data ───────────────────────────────────────────────────────

  Future<DashboardData> fetchDashboardData({
    required String businessId,
    required int totalRooms,
    required int month, // 0 = all year, 1–12 = specific month
    required int year,
  }) async {
    final (start, end) = _dateRange(month, year);
    final (yearStart, yearEnd) = _dateRange(0, year);

    // Records for the selected filter period
    final periodRecords = await _fetchGuestRecords(
      businessId: businessId,
      startDate: start,
      endDate: end,
    );

    // Records for the full year (for "guests this year" stat)
    final yearRecords = (month == 0)
        ? periodRecords
        : await _fetchGuestRecords(
            businessId: businessId,
            startDate: yearStart,
            endDate: yearEnd,
          );

    // ── Stats ────────────────────────────────────────────────────────────────────

    final guestsThisMonth =
        periodRecords.fold<int>(0, (s, r) => s + (r['total_guests'] as int));
    final guestsThisYear =
        yearRecords.fold<int>(0, (s, r) => s + (r['total_guests'] as int));

    double avgStay = 0;
    if (periodRecords.isNotEmpty) {
      double totalNights = 0;
      for (final r in periodRecords) {
        final checkIn = DateTime.parse(r['check_in'] as String);
        final checkOut = DateTime.parse(r['check_out'] as String);
        totalNights += checkOut.difference(checkIn).inDays;
      }
      avgStay = totalNights / periodRecords.length;
    }

    final stats = DashboardStats(
      guestsThisMonth: guestsThisMonth,
      guestsThisYear: guestsThisYear,
      avgLengthOfStay: avgStay,
      totalRooms: totalRooms,
    );

    // ── Breakdowns ───────────────────────────────────────────────────────────────

    final recordIds =
        periodRecords.map((r) => r['id'] as String).toList();
    final breakdowns = await _fetchBreakdowns(recordIds);

    // Gender
    int male = 0, female = 0, genderOther = 0;
    for (final b in breakdowns) {
      final sex = (b['sex'] as String).toLowerCase();
      final cnt = b['count'] as int;
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
      final country = b['country'] as String;
      countryMap[country] = (countryMap[country] ?? 0) + (b['count'] as int);
    }
    final topCountries = (countryMap.entries
            .map((e) => CountryCount(country: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(5)
        .toList();

    // Top 5 local regions (Philippine visitors only)
    final regionMap = <String, int>{};
    for (final b in breakdowns) {
      final region = b['philippines_region'] as String?;
      if (region != null && region.isNotEmpty) {
        regionMap[region] =
            (regionMap[region] ?? 0) + (b['count'] as int);
      }
    }
    final topRegions = (regionMap.entries
            .map((e) => RegionCount(region: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(5)
        .toList();

    return DashboardData(
      stats: stats,
      sexDistribution:
          SexDistribution(male: male, female: female, other: genderOther),
      topCountries: topCountries,
      topRegions: topRegions,
    );
  }

  // ── Yearly trend comparison ───────────────────────────────────────────────────

  /// Fetches monthly guest counts for each year in [years].
  /// Returns a map: { year → [MonthlyCount × 12] }
  Future<Map<int, List<MonthlyCount>>> fetchYearlyComparison({
    required String businessId,
    required List<int> years,
  }) async {
    final result = <int, List<MonthlyCount>>{};

    for (final year in years) {
      final (start, end) = _dateRange(0, year);
      final records = await _fetchGuestRecords(
        businessId: businessId,
        startDate: start,
        endDate: end,
      );

      final monthMap = <int, int>{};
      for (final r in records) {
        final m = DateTime.parse(r['check_in'] as String).month;
        monthMap[m] = (monthMap[m] ?? 0) + (r['total_guests'] as int);
      }

      result[year] = List.generate(
        12,
        (i) => MonthlyCount(month: i + 1, count: monthMap[i + 1] ?? 0),
      );
    }

    return result;
  }

  // ── CSV export ────────────────────────────────────────────────────────────────

  /// Builds a CSV string of all guest records + breakdowns for the given period.
  Future<String> generateCsv({
    required String businessId,
    required String businessName,
    required int month,
    required int year,
  }) async {
    final (start, end) = _dateRange(month, year);
    final records = await _fetchGuestRecords(
      businessId: businessId,
      startDate: start,
      endDate: end,
    );
    final recordIds = records.map((r) => r['id'] as String).toList();
    final breakdowns = await _fetchBreakdowns(recordIds);

    final recordMap = {for (final r in records) r['id'] as String: r};

    final buf = StringBuffer()
      ..writeln('Business,$businessName')
      ..writeln('Period,${month == 0 ? 'Full Year' : _monthName(month)} $year')
      ..writeln()
      ..writeln(
        'Check In,Check Out,Total Guests,Rooms Occupied,'
        'Country,Region,Sex,Age Group,Count',
      );

    for (final b in breakdowns) {
      final rec = recordMap[b['guest_record_id'] as String];
      if (rec == null) continue;
      final row = [
        rec['check_in'],
        rec['check_out'],
        rec['total_guests'],
        rec['rooms_occupied'],
        _csvCell(b['country'] as String),
        _csvCell(b['philippines_region'] as String? ?? ''),
        b['sex'],
        b['age_group'],
        b['count'],
      ];
      buf.writeln(row.join(','));
    }

    return buf.toString();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _csvCell(String value) =>
      value.contains(',') ? '"$value"' : value;

  String _monthName(int month) => const [
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
      ][month];
}