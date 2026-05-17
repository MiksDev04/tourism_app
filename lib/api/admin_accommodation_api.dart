// lib/api/admin_accommodation_api.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/ui/admin/models/accommodation_models.dart';

class AccommodationResult {
  final bool success;
  final String? error;

  const AccommodationResult._({required this.success, this.error});
  factory AccommodationResult.ok() =>
      const AccommodationResult._(success: true);
  factory AccommodationResult.err(String error) =>
      AccommodationResult._(success: false, error: error);
}

class AdminAccommodationApi {
  final _supabase = Supabase.instance.client;

  // ── Fetch all businesses with joined profile (for contact/phone) ──────────
  Future<List<Accommodation>> fetchAll() async {
    try {
      final data = await _supabase
          .from('businesses')
          .select('''
          id,
          profile_id,
          business_name,
          business_type,
          owner_name,
          permit_number,
          registration_number,
          address,
          total_rooms,
          permit_file_url,
          valid_id_url,
          status,
          remarks,
          created_at,
          profiles(full_name, phone)
        ''')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      debugPrint('📦 fetchAll raw: $data');

      return (data as List)
          .map((e) => Accommodation.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ fetchAll error: $e');
      return [];
    }
  }

  // ── Approve ───────────────────────────────────────────────────────────────
  Future<AccommodationResult> approve(String businessId) async {
    debugPrint('✅ Approving business: $businessId');
    try {
      await _supabase
          .from('businesses')
          .update({'status': 'approved', 'remarks': null})
          .eq('id', businessId);
      return AccommodationResult.ok();
    } catch (e) {
      debugPrint('❌ approve error: $e');
      return AccommodationResult.err('Failed to approve. Please try again.');
    }
  }

  // ── Reject ────────────────────────────────────────────────────────────────
  Future<AccommodationResult> reject(
    String businessId, {
    String? remarks,
  }) async {
    try {
      await _supabase
          .from('businesses')
          .update({'status': 'rejected', 'remarks': remarks})
          .eq('id', businessId);
      return AccommodationResult.ok();
    } catch (e) {
      debugPrint('❌ reject error: $e');
      return AccommodationResult.err('Failed to reject. Please try again.');
    }
  }

  // ── Flag as warning ───────────────────────────────────────────────────────
  Future<AccommodationResult> flag(String businessId, {String? remarks}) async {
    try {
      await _supabase
          .from('businesses')
          .update({'status': 'warning', 'remarks': remarks})
          .eq('id', businessId);
      return AccommodationResult.ok();
    } catch (e) {
      debugPrint('❌ flag error: $e');
      return AccommodationResult.err('Failed to flag. Please try again.');
    }
  }

  // ── Soft delete ───────────────────────────────────────────────────────────
  Future<AccommodationResult> delete(String businessId) async {
    try {
      await _supabase
          .from('businesses')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', businessId);
      return AccommodationResult.ok();
    } catch (e) {
      debugPrint('❌ delete error: $e');
      return AccommodationResult.err('Failed to delete. Please try again.');
    }
  }
}
