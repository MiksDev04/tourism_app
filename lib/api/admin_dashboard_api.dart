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

class AgeGroupCount {
  const AgeGroupCount({required this.ageGroup, required this.count});

  final String ageGroup;
  final int count;
}

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

class AccommodationTypeCount {
  const AccommodationTypeCount({required this.type, required this.count});

  final String type;
  final int count;
}

class PurposeCount {
  const PurposeCount({required this.purpose, required this.count});

  final String purpose;
  final int count;
}

class ComplianceData {
  const ComplianceData({required this.compliant, required this.nonCompliant});

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
    required this.ageGroups,
    required this.topNationalities,
    required this.transportModes,
    required this.compliance,
    required this.topRegions,
    required this.accommodationTypes,
    required this.purposeOfVisit,
  });

  final AdminDashboardStats stats;
  final GenderDistribution genderDistribution;
  final List<AgeGroupCount> ageGroups;
  final List<NationalityCount> topNationalities;
  final List<TransportCount> transportModes;
  final ComplianceData compliance;
  final List<RegionCount> topRegions;
  final List<AccommodationTypeCount> accommodationTypes;
  final List<PurposeCount> purposeOfVisit;
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
        .select(
          'id, business_id, check_in, check_out, total_guests, rooms_occupied, purpose_of_visit',
        )
        .eq('is_deleted', false)
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

  List<String> _extractBusinessLines(Object? value) {
    if (value is List) {
      return value
          .map((e) => (e?.toString() ?? '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[,|\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Aggregates period tourist counts by each approved business_line value.
  Future<List<AccommodationTypeCount>> _fetchAccommodationTypes(
    List<Map<String, dynamic>> periodRecords,
  ) async {
    final businessIds = periodRecords
        .map((record) => record['business_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    if (businessIds.isEmpty) return const [];

    final response = await _supabase
        .from('businesses')
        .select('id, business_line')
        .inFilter('id', businessIds)
        .eq('status', 'approved')
        .isFilter('deleted_at', null);

    final businesses = List<Map<String, dynamic>>.from(response as List);
    final linesByBusiness = {
      for (final business in businesses)
        if (business['id'] case final String id)
          id: _extractBusinessLines(business['business_line']),
    };
    final typeMap = <String, int>{};

    for (final record in periodRecords) {
      final businessId = record['business_id'] as String?;
      final lines = linesByBusiness[businessId] ?? const [];
      if (lines.isEmpty) continue;

      final guestCount = (record['total_guests'] as num?)?.toInt() ?? 0;
      for (final type in lines) {
        typeMap[type] = (typeMap[type] ?? 0) + guestCount;
      }
    }

    return typeMap.entries
        .map((e) => AccommodationTypeCount(type: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
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
        : await _fetchGuestRecords(startDate: yearStart, endDate: yearEnd);

    final touristsThisPeriod = periodRecords.fold<int>(
      0,
      (s, r) => s + (r['total_guests'] as int),
    );
    final touristsThisYear = yearRecords.fold<int>(
      0,
      (s, r) => s + (r['total_guests'] as int),
    );

    final activeAccommodations = await _countBusinessProfiles();
    final pendingRegistrations = await _countPendingRegistrations();

    final breakdowns = await _fetchBreakdowns(
      periodRecords.map((r) => r['id'] as String).toList(),
    );

    // ── Gender distribution ──────────────────────────────────────────────────
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

    // ── Age group distribution ───────────────────────────────────────────────
    final ageGroupMap = <String, int>{};
    for (final breakdown in breakdowns) {
      final ageGroup = (breakdown['age_group'] as String? ?? '').trim();
      if (ageGroup.isEmpty) continue;
      ageGroupMap[ageGroup] =
          (ageGroupMap[ageGroup] ?? 0) + (breakdown['count'] as int? ?? 0);
    }
    final ageGroups =
        ageGroupMap.entries
            .map((e) => AgeGroupCount(ageGroup: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    // ── Top nationalities / countries ────────────────────────────────────────
    final nationalityMap = <String, int>{};
    for (final breakdown in breakdowns) {
      final country = (breakdown['country'] as String? ?? '').trim();
      if (country.isEmpty) continue;
      nationalityMap[country] =
          (nationalityMap[country] ?? 0) + (breakdown['count'] as int? ?? 0);
    }
    final topNationalities =
        (nationalityMap.entries
                .map(
                  (entry) => NationalityCount(
                    nationality: entry.key,
                    count: entry.value,
                  ),
                )
                .toList()
              ..sort((a, b) => b.count.compareTo(a.count)))
            .take(5)
            .toList();

    // ── Top Philippine regions ───────────────────────────────────────────────
    final regionMap = <String, int>{};
    for (final breakdown in breakdowns) {
      final region = (breakdown['philippines_region'] as String? ?? '').trim();
      if (region.isEmpty) continue;
      regionMap[region] =
          (regionMap[region] ?? 0) + (breakdown['count'] as int? ?? 0);
    }
    final topRegions =
        (regionMap.entries
                .map(
                  (entry) => RegionCount(region: entry.key, count: entry.value),
                )
                .toList()
              ..sort((a, b) => b.count.compareTo(a.count)))
            .take(5)
            .toList();

    // ── Purpose of visit ─────────────────────────────────────────────────────
    final purposeMap = <String, int>{};
    for (final record in periodRecords) {
      final purpose = (record['purpose_of_visit'] as String? ?? '').trim();
      if (purpose.isEmpty) continue;
      purposeMap[purpose] =
          (purposeMap[purpose] ?? 0) + (record['total_guests'] as int? ?? 0);
    }
    final purposeOfVisit =
        (purposeMap.entries
                .map((e) => PurposeCount(purpose: e.key, count: e.value))
                .toList()
              ..sort((a, b) => b.count.compareTo(a.count)))
            .take(5)
            .toList();

    // ── Accommodation types ──────────────────────────────────────────────────
    final accommodationTypes = await _fetchAccommodationTypes(periodRecords);

    return AdminDashboardData(
      stats: AdminDashboardStats(
        activeAccommodations: activeAccommodations,
        touristsThisPeriod: touristsThisPeriod,
        pendingRegistrations: pendingRegistrations,
        touristsThisYear: touristsThisYear,
      ),
      genderDistribution: GenderDistribution(
        male: male,
        female: female,
        other: other,
      ),
      ageGroups: ageGroups,
      topNationalities: topNationalities,
      transportModes: const [],
      compliance: ComplianceData(
        compliant: activeAccommodations,
        nonCompliant: pendingRegistrations,
      ),
      topRegions: topRegions,
      accommodationTypes: accommodationTypes,
      purposeOfVisit: purposeOfVisit,
    );
  }

  Future<Map<int, List<MonthlyCount>>> fetchYearlyComparison({
    required List<int> years,
  }) async {
    final result = <int, List<MonthlyCount>>{};

    for (final year in years) {
      final (start, end) = _dateRange(0, year);
      final records = await _fetchGuestRecords(startDate: start, endDate: end);

      final monthMap = <int, int>{};
      for (final record in records) {
        final month = DateTime.parse(record['check_in'] as String).month;
        monthMap[month] =
            (monthMap[month] ?? 0) + (record['total_guests'] as int);
      }

      result[year] = List.generate(
        12,
        (index) =>
            MonthlyCount(month: index + 1, count: monthMap[index + 1] ?? 0),
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
    final records = await _fetchGuestRecords(startDate: start, endDate: end);
    final recordIds = records.map((record) => record['id'] as String).toList();
    final breakdowns = await _fetchBreakdowns(recordIds);

    final recordMap = {
      for (final record in records) record['id'] as String: record,
    };

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
