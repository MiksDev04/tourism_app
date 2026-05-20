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
          .eq('profile_id', userId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Fetch All Guest Records for a Business ────────────────────────────────

  Future<ApiResult<List<GuestRecord>>> fetchGuestRecords(
    String businessId,
  ) async {
    try {
      final rows = await _supabase
          .from('guest_records')
          .select('''
            id,
            check_in,
            check_out,
            total_guests,
            rooms_occupied,
            purpose_of_visit,
            transportation_mode,
            status,
            guest_breakdowns (
              is_overseas,
              country,
              nationality,
              philippines_region,
              sex,
              age_group,
              count
            )
          ''')
          .eq('business_id', businessId)
          .eq('is_deleted', false)
          .order('check_in', ascending: false);

      final records = (rows as List).map((row) {
        final breakdowns = (row['guest_breakdowns'] as List?) ?? [];
        GuestDemographics? demographics;

        if (breakdowns.isNotEmpty) {
          final ageGroups = <String, int>{};
          final sex       = <String, int>{};
          final countries = <String, int>{};

          for (final b in breakdowns) {
            final count      = (b['count'] as int?) ?? 0;
            final isOverseas = (b['is_overseas'] as bool?) ?? false;

            // ── Age groups ──────────────────────────────────────────────────
            final ageGroup = b['age_group'] as String? ?? 'Unknown';
            ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + count;

            // ── Sex ─────────────────────────────────────────────────────────
            final s = b['sex'] as String? ?? 'Unknown';
            sex[s] = (sex[s] ?? 0) + count;

            // ── Countries map ───────────────────────────────────────────────
            // Overseas guests have null country — label them separately.
            final String countryKey;
            if (isOverseas) {
              countryKey = 'Overseas';
            } else {
              final country = b['country'] as String? ?? 'Unknown';
              final region  = b['philippines_region'] as String?;
              countryKey = (country == 'Philippines' &&
                      region != null &&
                      region != 'N/A')
                  ? 'PH – $region'
                  : country;
            }
            countries[countryKey] = (countries[countryKey] ?? 0) + count;
          }

          demographics = GuestDemographics(
            ageGroups: ageGroups,
            sexDistribution: sex,
            countries: countries,
            breakdowns: breakdowns
                .map(
                  (b) {
                    final isOverseas =
                        (b['is_overseas'] as bool?) ?? false;

                    return GuestBreakdownEntry(
                      // Overseas: country / nationality / region all null
                      country: isOverseas
                          ? null
                          : b['country'] as String?,
                      nationality: (isOverseas ||
                              (b['country'] as String?) != 'Philippines')
                          ? null
                          : b['nationality'] as String?,
                      philippinesRegion: (!isOverseas &&
                              (b['country'] as String?) == 'Philippines' &&
                              (b['philippines_region'] as String?) != null &&
                              (b['philippines_region'] as String?) != 'N/A')
                          ? b['philippines_region'] as String?
                          : null,
                      sex:       b['sex']       as String? ?? '',
                      ageGroup:  b['age_group'] as String? ?? '',
                      count:     (b['count']    as int?)   ?? 0,
                      isOverseas: isOverseas,
                    );
                  },
                )
                .toList(),
          );
        }

        final checkIn  = row['check_in']  as String;
        final checkOut = row['check_out'] as String;
        final nights   = _calcNights(checkIn, checkOut);

        final statusStr = row['status'] as String? ?? 'active';

        return GuestRecord(
          id:        row['id']              as String,
          checkIn:   checkIn,
          checkOut:  checkOut,
          nights:    nights,
          guests:    (row['total_guests']      as int?) ?? 0,
          rooms:     (row['rooms_occupied']    as int?) ?? 0,
          purpose:   row['purpose_of_visit']   as String? ?? '',
          transport: row['transportation_mode'] as String? ?? '',
          status:    statusStr == 'archived'
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

  // ── Restore an Archived Record ────────────────────────────────────────────

  Future<ApiResult<void>> restoreRecord(String recordId) async {
    try {
      await _supabase
          .from('guest_records')
          .update({'status': 'active'})
          .eq('id', recordId);
      return const ApiResult.success(null);
    } on PostgrestException catch (e) {
      return ApiResult.failure(e.message);
    } catch (_) {
      return ApiResult.failure('Failed to restore record.');
    }
  }

  // ── Update a Record (stay info + breakdowns) ──────────────────────────────

  Future<ApiResult<void>> updateRecord({
    required String recordId,
    required String checkIn,
    required String checkOut,
    required int totalGuests,
    required int roomsOccupied,
    required String purposeOfVisit,
    required String transportationMode,
    required List<GuestBreakdownEntry> breakdowns,
  }) async {
    try {
      // 1. Update the guest record header fields.
      await _supabase
          .from('guest_records')
          .update({
            'check_in':            checkIn,
            'check_out':           checkOut,
            'total_guests':        totalGuests,
            'rooms_occupied':      roomsOccupied,
            'purpose_of_visit':    purposeOfVisit,
            'transportation_mode': transportationMode,
          })
          .eq('id', recordId);

      // 2. Delete ALL existing breakdowns for this record.
      //    Using .select() forces PostgREST to actually execute the DELETE
      //    and surface any RLS / permission denial as a thrown exception
      //    instead of silently doing nothing.
      await _supabase
          .from('guest_breakdowns')
          .delete()
          .eq('guest_record_id', recordId)
          .select();

      // 3. Insert the fresh set of breakdowns only after delete is confirmed.
      if (breakdowns.isNotEmpty) {
        final rows = breakdowns.map((b) {
          final isOverseas = b.isOverseas;
          final isPhilippines = !isOverseas && b.country == 'Philippines';

          return {
            'guest_record_id': recordId,
            'is_overseas':     isOverseas,

            // Overseas → country is NULL
            'country': isOverseas ? null : b.country,

            // Nationality only for domestic Philippines guests
            // Valid values: 'Filipino' | 'Foreign' | NULL
            'nationality': isPhilippines ? b.nationality : null,

            // Region only meaningful for Philippines domestic (not overseas)
            'philippines_region': isPhilippines ? b.philippinesRegion : null,

            'sex':       _mapSex(b.sex),
            'age_group': _mapAgeGroup(b.ageGroup),
            'count':     b.count,
          };
        }).toList();

        await _supabase.from('guest_breakdowns').insert(rows);
      }

      return const ApiResult.success(null);
    } on PostgrestException catch (e) {
      return ApiResult.failure('DB error: ${e.message}');
    } catch (e) {
      return ApiResult.failure('Failed to update record: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _calcNights(String checkIn, String checkOut) {
    try {
      final inDate  = DateTime.parse(checkIn);
      final outDate = DateTime.parse(checkOut);
      final n = outDate.difference(inDate).inDays;
      return '$n night${n == 1 ? '' : 's'}';
    } catch (_) {
      return '—';
    }
  }

  /// Normalises sex values from either the edit dialog ('Male'/'Female')
  /// or values already stored in the DB ('male'/'female').
  String _mapSex(String sex) {
    switch (sex.toLowerCase()) {
      case 'male':
        return 'male';
      case 'female':
        return 'female';
      default:
        return 'male';
    }
  }

  /// Normalises age-group values from either the edit dialog (en-dash '18–25')
  /// or values already stored in the DB (hyphen '18-25').
  String _mapAgeGroup(String ageGroup) {
    final normalised = ageGroup.trim().replaceAll('–', '-');
    switch (normalised) {
      case '0-9':
      case '1-9':
        return '1-9';
      case '10-17':
        return '10-17';
      case '18-25':
        return '18-25';
      case '26-35':
        return '26-35';
      case '36-45':
        return '36-45';
      case '46-55':
        return '46-55';
      case '56+':
        return '56+';
      case 'prefer_not_to_say':
      case 'prefer not to say':
        return 'prefer_not_to_say';
      default:
        return 'prefer_not_to_say';
    }
  }
}