import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ActivityStatus { active, lowActivity, inactive, noActivity }

enum BusinessStatusLevel { approved, warning, suspended }

// ─── Model ────────────────────────────────────────────────────────────────────

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

  /// Returns true when activity_status is 'active'.
  bool get isCompliant => activityStatus == ActivityStatus.active;

  /// Returns true when business_status is 'warning'.
  bool get hasWarning => businessStatus == BusinessStatusLevel.warning;

  /// Returns true when business_status is 'suspended'.
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


}
