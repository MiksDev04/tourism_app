import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ActivityStatus { active, lowActivity, inactive, noActivity }

enum BusinessStatusLevel { approved, warning, suspended }

// ─── Models ───────────────────────────────────────────────────────────────────

class BusinessActivityRecord {
  const BusinessActivityRecord({
    required this.id,
    required this.businessName,
    required this.businessLine,
    required this.businessStatus,
    required this.totalRecords,
    required this.totalGuests,
    this.lastActivity,
    required this.activityStatus,
  });

  final String id;
  final String businessName;
  final List<String> businessLine;
  final BusinessStatusLevel businessStatus;
  final int totalRecords;
  final int totalGuests;
  final DateTime? lastActivity;
  final ActivityStatus activityStatus;

  factory BusinessActivityRecord.fromJson(Map<String, dynamic> json) {
    return BusinessActivityRecord(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      businessLine: (json['business_line'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      businessStatus: _parseBusinessStatus(json['business_status'] as String),
      totalRecords: (json['total_records'] as num).toInt(),
      totalGuests: (json['total_guests'] as num).toInt(),
      lastActivity: json['last_activity'] != null
          ? DateTime.tryParse(json['last_activity'] as String)
          : null,
      activityStatus: _parseActivityStatus(json['activity_status'] as String),
    );
  }

  static BusinessStatusLevel _parseBusinessStatus(String raw) {
    switch (raw) {
      case 'warning':
        return BusinessStatusLevel.warning;
      case 'suspended':
        return BusinessStatusLevel.suspended;
      case 'approved':
      case 'active':
      default:
        return BusinessStatusLevel.approved;
    }
  }

  static ActivityStatus _parseActivityStatus(String raw) {
    switch (raw) {
      case 'active':
        return ActivityStatus.active;
      case 'low_activity':
        return ActivityStatus.lowActivity;
      case 'inactive':
        return ActivityStatus.inactive;
      case 'no_activity':
      default:
        return ActivityStatus.noActivity;
    }
  }

  bool get isCompliant => activityStatus == ActivityStatus.active;
  bool get hasWarning => businessStatus == BusinessStatusLevel.warning;
  bool get isSuspended => businessStatus == BusinessStatusLevel.suspended;

  String get businessLineLabel {
    if (businessLine.isEmpty) return '—';
    return businessLine
        .map(_formatBusinessLine)
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  static String _formatBusinessLine(String raw) {
    switch (raw) {
      case 'hotel':
        return 'Hotel';
      case 'resort':
        return 'Resort';
      case 'motel':
        return 'Motel';
      case 'pension_inn':
        return 'Pension Inn';
      case 'youth_hostel':
        return 'Youth Hostel';
      case 'apartment':
        return 'Apartment';
      case 'others':
        return 'Others';
      default:
        return raw;
    }
  }

  BusinessActivityRecord copyWith({BusinessStatusLevel? businessStatus}) {
    return BusinessActivityRecord(
      id: id,
      businessName: businessName,
      businessLine: businessLine,
      businessStatus: businessStatus ?? this.businessStatus,
      totalRecords: totalRecords,
      totalGuests: totalGuests,
      lastActivity: lastActivity,
      activityStatus: activityStatus,
    );
  }
}

/// Holds the aggregated guest total for a single check-in date.
class DailyGuestStat {
  const DailyGuestStat({
    required this.date,
    required this.totalGuests,
  });

  final DateTime date;
  final int totalGuests;
}

// ─── API ──────────────────────────────────────────────────────────────────────

class AdminComplianceApi {
  static final _supabase = Supabase.instance.client;

  /// Fetches all rows from the [business_activity_summary] view,
  /// ordered by last_activity descending (most-recent first; nulls last).
  static Future<List<BusinessActivityRecord>> fetchActivitySummary() async {
    final response = await _supabase
        .from('business_activity_summary')
        .select()
        .order('last_activity', ascending: false, nullsFirst: false);

    return (response as List<dynamic>)
        .map((e) => BusinessActivityRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates the [status] column of a business row in [businesses].
  static Future<void> updateBusinessStatus(
    String businessId,
    BusinessStatusLevel newStatus,
  ) async {
    final raw = switch (newStatus) {
      BusinessStatusLevel.approved => 'approved',
      BusinessStatusLevel.warning => 'warning',
      BusinessStatusLevel.suspended => 'suspended',
    };

    await _supabase
        .from('businesses')
        .update({'status': raw})
        .eq('id', businessId);
  }

  /// Fetches and aggregates total guests per [check_in] date for [businessId]
  /// within the given [month] (1–12) and [year].
  ///
  /// Only non-deleted records are considered. Results are sorted by date
  /// ascending and multiple records sharing the same check-in date are
  /// summed into a single [DailyGuestStat].
  static Future<List<DailyGuestStat>> fetchDailyStats(
    String businessId,
    int month,
    int year,
  ) async {
    final mm = month.toString().padLeft(2, '0');
    final yyyy = year.toString().padLeft(4, '0');
    final lastDay = DateTime(year, month + 1, 0).day;
    final startStr = '$yyyy-$mm-01';
    final endStr = '$yyyy-$mm-${lastDay.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from('guest_records')
        .select('check_in, total_guests')
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .gte('check_in', startStr)
        .lte('check_in', endStr)
        .order('check_in', ascending: true);

    // Aggregate multiple records that share the same check-in date.
    final aggregated = <String, int>{};
    for (final row in response as List<dynamic>) {
      final checkIn = (row['check_in'] as String).substring(0, 10);
      final guests = (row['total_guests'] as num).toInt();
      aggregated[checkIn] = (aggregated[checkIn] ?? 0) + guests;
    }

    final entries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map(
          (e) => DailyGuestStat(
            date: DateTime.parse(e.key),
            totalGuests: e.value,
          ),
        )
        .toList();
  }
}