import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ActivityStatus { active, lowActivity, inactive, noActivity }

enum BusinessStatusLevel { approved, warning }

// ─── Model ────────────────────────────────────────────────────────────────────

class BusinessActivityRecord {
  const BusinessActivityRecord({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.businessStatus,
    required this.totalRecords,
    required this.totalGuests,
    this.lastActivity,
    required this.activityStatus,
  });

  final String id;
  final String businessName;
  final String businessType;
  final BusinessStatusLevel businessStatus;
  final int totalRecords;
  final int totalGuests;
  final DateTime? lastActivity;
  final ActivityStatus activityStatus;

  factory BusinessActivityRecord.fromJson(Map<String, dynamic> json) {
    return BusinessActivityRecord(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      businessType: json['business_type'] as String,
      businessStatus: (json['business_status'] as String) == 'warning'
          ? BusinessStatusLevel.warning
          : BusinessStatusLevel.approved,
      totalRecords: (json['total_records'] as num).toInt(),
      totalGuests: (json['total_guests'] as num).toInt(),
      lastActivity: json['last_activity'] != null
          ? DateTime.tryParse(json['last_activity'] as String)
          : null,
      activityStatus: _parseActivityStatus(json['activity_status'] as String),
    );
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