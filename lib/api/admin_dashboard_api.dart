// ignore_for_file: inference_failure_on_function_invocation

import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Required pubspec.yaml dependencies ───────────────────────────────────────
// supabase_flutter: ^2.x.x
// pdf: ^3.x.x
// printing: ^5.x.x
// share_plus: ^9.x.x
// path_provider: ^2.x.x

// ─── Models ───────────────────────────────────────────────────────────────────

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.activeAccommodations,
    required this.touristsThisPeriod,
    required this.pendingRegistrations,
    required this.touristsThisYear,
  });

  final int activeAccommodations;
  final int touristsThisPeriod;
  final int pendingRegistrations;
  final int touristsThisYear;
}

typedef DashboardStats = AdminDashboardStats;

class GenderDistribution {
  const GenderDistribution({
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

typedef SexDistribution = GenderDistribution;

class NationalityCount {
  const NationalityCount({required this.nationality, required this.count});

  final String nationality;
  final int count;
}

typedef CountryCount = NationalityCount;

class TransportCount {
  const TransportCount({required this.mode, required this.count});

  final String mode;
  final int count;
}

class RegionCount {
  const RegionCount({required this.region, required this.count});

  final String region;
  final int count;
}

class ComplianceData {
  const ComplianceData({
    required this.compliant,
    required this.nonCompliant,
  });

  final int compliant;
  final int nonCompliant;

  double get rate {
    final total = compliant + nonCompliant;
    return total == 0 ? 0 : compliant / total;
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.stats,
    required this.genderDistribution,
    required this.topNationalities,
    required this.transportModes,
    required this.compliance,
    required this.topRegions,
  });

  final AdminDashboardStats stats;
  final GenderDistribution genderDistribution;
  final List<NationalityCount> topNationalities;
  final List<TransportCount> transportModes;
  final ComplianceData compliance;
  final List<RegionCount> topRegions;
}

typedef DashboardData = AdminDashboardData;

class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String role;

  String get displayLabel => '$fullName • Admin';
}

class MonthlyCount {
  const MonthlyCount({required this.month, required this.count});

  final int month; // 1–12
  final int count;
}
// ─── API ──────────────────────────────────────────────────────────────────────

class AdminDashboardApi {
  AdminDashboardApi({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  (String start, String end) _dateRange(int month, int year) {
    if (month == 0) {
      return ('$year-01-01', '$year-12-31');
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    final mm = month.toString().padLeft(2, '0');
    final dd = lastDay.toString().padLeft(2, '0');
    return ('$year-$mm-01', '$year-$mm-$dd');
  }

  Future<AdminProfile?> fetchAdminProfile(String adminId) async {
    final response = await _supabase
        .from('profiles')
        .select('id, full_name, phone, email, role')
        .eq('id', adminId)
        .maybeSingle();

    if (response case final Map<String, dynamic> data) {
      return AdminProfile(
        id: data['id'] as String,
        fullName: (data['full_name'] as String?) ?? '',
        phone: (data['phone'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        role: (data['role'] as String?) ?? 'admin',
      );
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchGuestRecords({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _supabase
        .from('guest_records')
        .select('id, check_in, check_out, total_guests, rooms_occupied')
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

  Future<int> _countBusinessProfiles() async {
    final response = await _supabase
        .from('businesses')
        .select('id')
        .eq('status', 'approved')
        .isFilter('deleted_at', null);
    return (response as List).length;
  }

  Future<int> _countPendingRegistrations() async {
    final response = await _supabase
        .from('businesses')
        .select('id')
        .eq('status', 'pending')
        .isFilter('deleted_at', null);
    return (response as List).length;
  }

  Future<AdminDashboardData> fetchDashboardData({
    required int month,
    required int year,
  }) async {
    final (start, end) = _dateRange(month, year);
    final (yearStart, yearEnd) = _dateRange(0, year);

    final periodRecords = await _fetchGuestRecords(
      startDate: start,
      endDate: end,
    );

    final yearRecords = (month == 0)
        ? periodRecords
        : await _fetchGuestRecords(
            startDate: yearStart,
            endDate: yearEnd,
          );

    final touristsThisPeriod =
        periodRecords.fold<int>(0, (s, r) => s + (r['total_guests'] as int));
    final touristsThisYear =
        yearRecords.fold<int>(0, (s, r) => s + (r['total_guests'] as int));

    final activeAccommodations = await _countBusinessProfiles();
    final pendingRegistrations = await _countPendingRegistrations();

    final breakdowns = await _fetchBreakdowns(
      periodRecords.map((r) => r['id'] as String).toList(),
    );

    int male = 0, female = 0, other = 0;
    for (final breakdown in breakdowns) {
      final sex = (breakdown['sex'] as String? ?? '').toLowerCase();
      final count = breakdown['count'] as int? ?? 0;
      if (sex == 'male') {
        male += count;
      } else if (sex == 'female') {
        female += count;
      } else {
        other += count;
      }
    }

    final nationalityMap = <String, int>{};
    for (final breakdown in breakdowns) {
      final country = (breakdown['country'] as String? ?? '').trim();
      if (country.isEmpty) continue;
      nationalityMap[country] =
          (nationalityMap[country] ?? 0) + (breakdown['count'] as int? ?? 0);
    }
    final topNationalities = (nationalityMap.entries
            .map((entry) => NationalityCount(
                  nationality: entry.key,
                  count: entry.value,
                ))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(5)
        .toList();

    final regionMap = <String, int>{};
    for (final breakdown in breakdowns) {
      final region = (breakdown['philippines_region'] as String? ?? '').trim();
      if (region.isEmpty) continue;
      regionMap[region] =
          (regionMap[region] ?? 0) + (breakdown['count'] as int? ?? 0);
    }
    final topRegions = (regionMap.entries
            .map((entry) => RegionCount(region: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(5)
        .toList();

    return AdminDashboardData(
      stats: AdminDashboardStats(
        activeAccommodations: activeAccommodations,
        touristsThisPeriod: touristsThisPeriod,
        pendingRegistrations: pendingRegistrations,
        touristsThisYear: touristsThisYear,
      ),
      genderDistribution:
          GenderDistribution(male: male, female: female, other: other),
      topNationalities: topNationalities,
      transportModes: const [],
      compliance: ComplianceData(
        compliant: activeAccommodations,
        nonCompliant: pendingRegistrations,
      ),
      topRegions: topRegions,
    );
  }

  Future<Map<int, List<MonthlyCount>>> fetchYearlyComparison({
    required List<int> years,
  }) async {
    final result = <int, List<MonthlyCount>>{};

    for (final year in years) {
      final (start, end) = _dateRange(0, year);
      final records = await _fetchGuestRecords(
        startDate: start,
        endDate: end,
      );

      final monthMap = <int, int>{};
      for (final record in records) {
        final month = DateTime.parse(record['check_in'] as String).month;
        monthMap[month] =
            (monthMap[month] ?? 0) + (record['total_guests'] as int);
      }

      result[year] = List.generate(
        12,
        (index) => MonthlyCount(month: index + 1, count: monthMap[index + 1] ?? 0),
      );
    }

    return result;
  }

  Future<String> generateCsv({
    required String businessName,
    required int month,
    required int year,
  }) async {
    final (start, end) = _dateRange(month, year);
    final records = await _fetchGuestRecords(
      startDate: start,
      endDate: end,
    );
    final recordIds = records.map((record) => record['id'] as String).toList();
    final breakdowns = await _fetchBreakdowns(recordIds);

    final recordMap = {for (final record in records) record['id'] as String: record};

    final buffer = StringBuffer()
      ..writeln('Business,$businessName')
      ..writeln('Period,${month == 0 ? 'Full Year' : _monthName(month)} $year')
      ..writeln()
      ..writeln(
        'Check In,Check Out,Total Guests,Rooms Occupied,'
        'Country,Region,Sex,Age Group,Count',
      );

    for (final breakdown in breakdowns) {
      final record = recordMap[breakdown['guest_record_id'] as String];
      if (record == null) continue;
      final row = [
        record['check_in'],
        record['check_out'],
        record['total_guests'],
        record['rooms_occupied'],
        _csvCell(breakdown['country'] as String? ?? ''),
        _csvCell(breakdown['philippines_region'] as String? ?? ''),
        breakdown['sex'],
        breakdown['age_group'],
        breakdown['count'],
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  String _csvCell(String value) => value.contains(',') ? '"$value"' : value;

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