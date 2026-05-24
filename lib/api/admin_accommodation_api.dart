// lib/api/admin_accommodation_api.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/ui/admin/models/accommodation_models.dart';

// ─── Result wrapper ───────────────────────────────────────────────────────────

class AccommodationResult {
  final bool success;
  final String? error;

  const AccommodationResult._({required this.success, this.error});
  factory AccommodationResult.ok() =>
      const AccommodationResult._(success: true);
  factory AccommodationResult.err(String error) =>
      AccommodationResult._(success: false, error: error);
}

// ─── Export row model ─────────────────────────────────────────────────────────

class AccommodationExportRow {
  const AccommodationExportRow({
    required this.businessName,
    required this.tradeName,
    required this.businessLine,
    required this.businessType,
    required this.ownerFirstName,
    required this.ownerMiddleName,
    required this.ownerLastName,
    required this.street,
    required this.region,
    required this.province,
    required this.cityMunicipality,
    required this.barangay,
    required this.phone,
  });

  final String businessName;
  final String tradeName;
  final String businessLine;
  final String businessType;
  final String ownerFirstName;
  final String ownerMiddleName;
  final String ownerLastName;
  final String street;
  final String region;
  final String province;
  final String cityMunicipality;
  final String barangay;
  final String phone;
}

// ─── API ──────────────────────────────────────────────────────────────────────

class AdminAccommodationApi {
  final _supabase = Supabase.instance.client;

  // ── Fetch all businesses with joined profile ──────────────────────────────
  Future<List<Accommodation>> fetchAll() async {
    try {
      final data = await _supabase
          .from('businesses')
          .select('''
            id,
            profile_id,
            business_name,
            business_type,
            business_line,
            owner_first_name,
            owner_middle_name,
            owner_last_name,
            tradename,
            permit_number,
            registration_number,
            street,
            barangay,
            city_municipality,
            province,
            region,
            total_rooms,
            permit_file_url,
            valid_id_url,
            status,
            remarks,
            created_at,
            profiles(full_name, email, phone)
          ''')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => Accommodation.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ fetchAll error: $e');
      return [];
    }
  }

  // ── Fetch rows formatted for export ───────────────────────────────────────
  Future<List<AccommodationExportRow>> fetchExportRows() async {
    try {
      final data = await _supabase
          .from('businesses')
          .select('''
            business_name,
            tradename,
            business_line,
            business_type,
            owner_first_name,
            owner_middle_name,
            owner_last_name,
            street,
            region,
            province,
            city_municipality,
            barangay,
            profiles(phone)
          ''')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (data as List).map((e) {
        final m = e as Map<String, dynamic>;

        final phone =
            (m['profiles'] as Map<String, dynamic>?)?['phone'] as String? ?? '';

        final rawLines = m['business_line'];
        final businessLine = rawLines is List
            ? rawLines
                .map((l) => _toTitleCase(l.toString()))
                .join(', ')
            : '';

        return AccommodationExportRow(
          businessName: _val(m['business_name']),
          tradeName: _val(m['tradename']),
          businessLine: businessLine.isEmpty ? '—' : businessLine,
          businessType: _toTitleCase(m['business_type'] as String? ?? ''),
          ownerFirstName: _val(m['owner_first_name']),
          ownerMiddleName: _val(m['owner_middle_name']),
          ownerLastName: _val(m['owner_last_name']),
          street: _val(m['street']),
          region: _val(m['region']),
          province: _val(m['province']),
          cityMunicipality: _val(m['city_municipality']),
          barangay: _val(m['barangay']),
          phone: phone.trim().isEmpty ? '—' : phone.trim(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ fetchExportRows error: $e');
      return [];
    }
  }

  // ── Approve ───────────────────────────────────────────────────────────────
  Future<AccommodationResult> approve(
    String businessId, {
    String? remarks,
  }) async {
    try {
      await _supabase
          .from('businesses')
          .update({'status': 'approved', 'remarks': remarks})
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
  Future<AccommodationResult> flag(
    String businessId, {
    String? remarks,
  }) async {
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

// ─── Private helpers ──────────────────────────────────────────────────────────

/// Returns trimmed string or '—' if null/empty.
String _val(dynamic v) {
  final s = (v as String?)?.trim() ?? '';
  return s.isEmpty ? '—' : s;
}

/// Converts snake_case enum string to Title Case (e.g. "sole_proprietorship" → "Sole Proprietorship").
String _toTitleCase(String s) => s
    .split('_')
    .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');