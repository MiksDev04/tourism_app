import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/ui/business/pages/business_guest_records_page.dart';

// ─── Result Wrapper ───────────────────────────────────────────────────────────

class ApiResult<T> {
  const ApiResult.success(this.data) : error = null;
  const ApiResult.failure(this.error) : data = null;

  final T? data;
  final String? error;

  bool get isSuccess => error == null;
}

// ─── Business Guest Record API ────────────────────────────────────────────────

class BusinessGuestRecordApi {
  final _supabase = Supabase.instance.client;

  // ── Fetch Business ID ─────────────────────────────────────────────────────

  Future<String?> fetchBusinessId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('businesses')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Fetch All Guest Records for a Business ────────────────────────────────

  Future<ApiResult<List<GuestRecord>>> fetchGuestRecords(
      String businessId) async {
    try {
      final rows = await _supabase
          .from('guest_entries')
          .select('''
            id,
            check_in,
            check_out,
            total_guests,
            rooms_occupied,
            purpose_of_visit,
            transportation_mode,
            is_archived,
            guest_breakdowns (
              nationality,
              philippines_region,
              gender,
              age_group,
              count
            )
          ''')
          .eq('business_id', businessId)
          .order('check_in', ascending: false);

      final records = (rows as List).map((row) {
        // Build demographic aggregates from breakdowns
        final breakdowns = (row['guest_breakdowns'] as List?) ?? [];
        GuestDemographics? demographics;

        if (breakdowns.isNotEmpty) {
          final ageGroups = <String, int>{};
          final gender = <String, int>{};
          final countries = <String, int>{};

          for (final b in breakdowns) {
            final count = (b['count'] as int?) ?? 0;

            final ageGroup = b['age_group'] as String? ?? 'Unknown';
            ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + count;

            final g = b['gender'] as String? ?? 'Unknown';
            gender[g] = (gender[g] ?? 0) + count;

            // Use region label for Philippines, otherwise nationality
            final nat = b['nationality'] as String? ?? 'Unknown';
            final region = b['philippines_region'] as String?;
            final countryKey =
                (nat == 'Philippines' && region != null) ? 'PH – $region' : nat;
            countries[countryKey] = (countries[countryKey] ?? 0) + count;
          }

          demographics = GuestDemographics(
            ageGroups: ageGroups,
            genderDistribution: gender,
            countries: countries,
            breakdowns: breakdowns
                .map((b) => GuestBreakdownEntry(
                      nationality: b['nationality'] as String? ?? '',
                      philippinesRegion:
                          b['philippines_region'] as String?,
                      gender: b['gender'] as String? ?? '',
                      ageGroup: b['age_group'] as String? ?? '',
                      count: (b['count'] as int?) ?? 0,
                    ))
                .toList(),
          );
        }

        final checkIn = row['check_in'] as String;
        final checkOut = row['check_out'] as String;
        final nights = _calcNights(checkIn, checkOut);

        return GuestRecord(
          id: row['id'] as String,
          checkIn: checkIn,
          checkOut: checkOut,
          nights: nights,
          guests: (row['total_guests'] as int?) ?? 0,
          rooms: (row['rooms_occupied'] as int?) ?? 0,
          purpose: row['purpose_of_visit'] as String? ?? '',
          transport: row['transportation_mode'] as String? ?? '',
          status: (row['is_archived'] as bool? ?? false)
              ? GuestRecordStatus.archived
              : GuestRecordStatus.active,
          demographics: demographics,
        );
      }).toList();

      return ApiResult.success(records);
    } on PostgrestException catch (e) {
      return ApiResult.failure(e.message);
    } catch (e) {
      return ApiResult.failure('Failed to load records.');
    }
  }

  // ── Archive a Record ──────────────────────────────────────────────────────

  Future<ApiResult<void>> archiveRecord(String recordId) async {
    try {
      await _supabase
          .from('guest_entries')
          .update({'is_archived': true})
          .eq('id', recordId);
      return const ApiResult.success(null);
    } on PostgrestException catch (e) {
      return ApiResult.failure(e.message);
    } catch (_) {
      return ApiResult.failure('Failed to archive record.');
    }
  }

  // ── Restore an Archived Record ────────────────────────────────────────────

  Future<ApiResult<void>> restoreRecord(String recordId) async {
    try {
      await _supabase
          .from('guest_entries')
          .update({'is_archived': false})
          .eq('id', recordId);
      return const ApiResult.success(null);
    } on PostgrestException catch (e) {
      return ApiResult.failure(e.message);
    } catch (_) {
      return ApiResult.failure('Failed to restore record.');
    }
  }

  // ── Update a Record ───────────────────────────────────────────────────────

  Future<ApiResult<void>> updateRecord({
    required String recordId,
    required String checkIn,
    required String checkOut,
    required int totalGuests,
    required int roomsOccupied,
    required String purposeOfVisit,
    required String transportationMode,
  }) async {
    try {
      await _supabase.from('guest_entries').update({
        'check_in': checkIn,
        'check_out': checkOut,
        'total_guests': totalGuests,
        'rooms_occupied': roomsOccupied,
        'purpose_of_visit': purposeOfVisit,
        'transportation_mode': transportationMode,
      }).eq('id', recordId);
      return const ApiResult.success(null);
    } on PostgrestException catch (e) {
      return ApiResult.failure(e.message);
    } catch (_) {
      return ApiResult.failure('Failed to update record.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _calcNights(String checkIn, String checkOut) {
    try {
      final inDate = DateTime.parse(checkIn);
      final outDate = DateTime.parse(checkOut);
      final n = outDate.difference(inDate).inDays;
      return '$n night${n == 1 ? '' : 's'}';
    } catch (_) {
      return '—';
    }
  }
}