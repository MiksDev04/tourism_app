import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ActivityStatus { active, lowActivity, inactive, noActivity }

enum BusinessStatusLevel { approved, warning, suspended }

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

  BusinessActivityRecord copyWith({BusinessStatusLevel? businessStatus}) {
    return BusinessActivityRecord(
      id: id,
      businessName: businessName,
      businessType: businessType,
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

  /// Updates the [business_status] of an accommodation by [id].
  static Future<void> updateBusinessStatus(
    String id,
    BusinessStatusLevel status,
  ) async {
    final String statusStr = switch (status) {
      BusinessStatusLevel.approved => 'active',
      BusinessStatusLevel.warning => 'warning',
      BusinessStatusLevel.suspended => 'suspended',
    };

    await _supabase
        .from('accommodations')
        .update({'business_status': statusStr})
        .eq('id', id);
  }
}