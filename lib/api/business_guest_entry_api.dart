import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuestEntryResult {
  final bool success;
  final String? error;

  const GuestEntryResult._({required this.success, this.error});
  factory GuestEntryResult.ok() => const GuestEntryResult._(success: true);
  factory GuestEntryResult.err(String error) =>
      GuestEntryResult._(success: false, error: error);
}

class GuestBreakdownData {
  const GuestBreakdownData({
    required this.country,
    this.philippinesRegion,
    required this.sex,
    required this.ageGroup,
    required this.count,
    required this.residenceCategory,
  });

  final String country;
  final String? philippinesRegion;
  final String sex;
  final String ageGroup;
  final int count;
  final String residenceCategory;
}

class GuestEntryData {
  const GuestEntryData({
    required this.businessId,
    required this.checkIn,
    required this.checkOut,
    required this.totalGuests,
    required this.roomsOccupied,
    required this.purposeOfVisit,
    required this.transportationMode,
    required this.breakdowns,
  });

  final String businessId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int totalGuests;
  final int roomsOccupied;
  final String purposeOfVisit;
  final String transportationMode;
  final List<GuestBreakdownData> breakdowns;
}

class BusinessGuestEntryApi {
  final _supabase = Supabase.instance.client;

  // ── Fetch business ID for logged-in user ─────────────────────────────────
  Future<String?> fetchBusinessId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _supabase
          .from('businesses')
          .select('id')
          .eq('profile_id', userId)
          .maybeSingle();

      return data?['id'] as String?;
    } catch (e) {
      debugPrint('❌ fetchBusinessId error: $e');
      return null;
    }
  }

  // ── Save guest entry + breakdowns ─────────────────────────────────────────
  Future<GuestEntryResult> saveGuestEntry(GuestEntryData data) async {
    try {
      // 1. Insert guest_record
      final record = await _supabase
          .from('guest_records')
          .insert({
            'business_id': data.businessId,
            'check_in': data.checkIn.toIso8601String().split('T').first,
            'check_out': data.checkOut.toIso8601String().split('T').first,
            'total_guests': data.totalGuests,
            'rooms_occupied': data.roomsOccupied,
            'purpose_of_visit': data.purposeOfVisit,
            'transportation_mode': data.transportationMode,
            'status': 'active',
            'is_deleted': false,
          })
          .select('id')
          .single();

      final guestRecordId = record['id'] as String;

      // 2. Insert all breakdowns
      final breakdowns = data.breakdowns.map((b) => {
        'guest_record_id': guestRecordId,
        'country': b.country,
        'philippines_region': b.philippinesRegion,
        'sex': _mapSex(b.sex),
        'age_group': _mapAgeGroup(b.ageGroup),
        'count': b.count,
        'residence_category': b.residenceCategory,
      }).toList();

      await _supabase.from('guest_breakdowns').insert(breakdowns);

      return GuestEntryResult.ok();
    } catch (e) {
      debugPrint('❌ saveGuestEntry error: $e');
      return GuestEntryResult.err('Failed to save guest entry. Please try again.');
    }
  }

  // ── Map sex string to enum value ──────────────────────────────────────────
  String _mapSex(String sex) {
    switch (sex.toLowerCase()) {
      case 'male':   return 'male';
      case 'female': return 'female';
      default:       return 'male';
    }
  }

  // ── Map age group string to enum value ────────────────────────────────────
  String _mapAgeGroup(String ageGroup) {
    switch (ageGroup) {
      case '0–9':              return '1-9';
      case '10–17':            return '10-17';
      case '18–25':            return '18-25';
      case '26–35':            return '26-35';
      case '36–45':            return '36-45';
      case '46–55':            return '46-55';
      case '56+':              return '56+';
      case 'Prefer not to say': return 'prefer_not_to_say';
      default:                 return 'prefer_not_to_say';
    }
  }
}