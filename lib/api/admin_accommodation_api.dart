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

// ─── Ranking row model ────────────────────────────────────────────────────────

class AccommodationRankingRow {
  const AccommodationRankingRow({
    required this.businessId,
    required this.businessName,
    required this.totalGuests,
    required this.rank,
  });

  final String businessId;
  final String businessName;
  final int totalGuests;
  final int rank;
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
      rethrow;
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

  // ── Fetch tourist rankings for a given month/year ─────────────────────────
  //
  // Counts tourists by SUM(total_guests) WHERE check_in falls in [month, year].
  // Aggregation is done in Dart to avoid needing a DB-side RPC/view.
  Future<List<AccommodationRankingRow>> fetchRankings({
    required int month,
    required int year,
  }) async {
    try {
      var query = _supabase
          .from('guest_records')
          .select('business_id, total_guests, check_in, businesses(business_name)')
          .eq('is_deleted', false);

      if (year != 0) {
        if (month != 0) {
          final startDate = DateTime(year, month, 1);
          final endDate = month < 12
              ? DateTime(year, month + 1, 1)
              : DateTime(year + 1, 1, 1);

          String _pad(DateTime d) =>
              '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';

          query = query.gte('check_in', _pad(startDate)).lt('check_in', _pad(endDate));
        } else {
          // All months in a specific year
          final startDate = DateTime(year, 1, 1);
          final endDate = DateTime(year + 1, 1, 1);

          String _pad(DateTime d) =>
              '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';

          query = query.gte('check_in', _pad(startDate)).lt('check_in', _pad(endDate));
        }
      } else if (month != 0) {
        // Specific month across all years
        // Supabase doesn't easily support extracting month from date in a simple query without RPC or extra columns.
        // For now, let's just fetch all and filter in Dart if month is specified but year is 0.
        // OR better: if year is 0, we probably should ignore month too or fetch all?
        // Usually "All years" implies we don't care about the year.
        // But if user selects "January" and "All Years", they want all Januaries.
        // Since we are already aggregating in Dart, fetching all is fine if the dataset isn't massive.
      }

      final data = await query;

      // Aggregate totals per business in Dart
      final Map<String, _RankAgg> agg = {};
      for (final row in data as List) {
        final m = row as Map<String, dynamic>;

        // Filter by month in Dart if year was 0 but month was specified
        if (year == 0 && month != 0) {
          final checkInStr = m['check_in'] as String?;
          if (checkInStr != null) {
            final checkIn = DateTime.tryParse(checkInStr);
            if (checkIn != null && checkIn.month != month) {
              continue;
            }
          }
        }

        final bid = m['business_id'] as String;
        final guests = (m['total_guests'] as int?) ?? 0;
        final biz = m['businesses'] as Map<String, dynamic>?;
        final name = (biz?['business_name'] as String?)?.trim() ?? '—';

        if (!agg.containsKey(bid)) {
          agg[bid] = _RankAgg(name: name, total: 0);
        }
        agg[bid]!.total += guests;
      }

      // Sort descending by total guests
      final sorted = agg.entries.toList()
        ..sort((a, b) => b.value.total.compareTo(a.value.total));

      return sorted.asMap().entries.map((e) {
        return AccommodationRankingRow(
          businessId: e.value.key,
          businessName: e.value.value.name,
          totalGuests: e.value.value.total,
          rank: e.key + 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ fetchRankings error: $e');
      rethrow;
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

/// Lightweight accumulator used during rankings aggregation.
class _RankAgg {
  _RankAgg({required this.name, required this.total});
  final String name;
  int total;
}

/// Returns trimmed string or '—' if null/empty.
String _val(dynamic v) {
  final s = (v as String?)?.trim() ?? '';
  return s.isEmpty ? '—' : s;
}

/// Converts snake_case enum string to Title Case.
String _toTitleCase(String s) => s
    .split('_')
    .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');