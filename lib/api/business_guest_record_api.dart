import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/core/database/local_database.dart';
import 'package:tourism_app/core/services/offline_service.dart';
import 'package:tourism_app/core/services/session_service.dart';
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
  //
  // Fallback priority (both online and offline):
  //   1. Supabase  (only when online — freshest source of truth)
  //   2. SessionService cache  (always available after any login type)
  //   3. SQLite local_businesses table  (populated by SyncService pull)
  //
  // This triple-fallback means a mid-session connectivity toggle never causes
  // "Business account not found" — we always have at least the cached value.

  Future<String?> fetchBusinessId() async {
    if (!ConnectivityService.instance.isOnline) {
      // ── Offline path ──────────────────────────────────────────────────────
      debugPrint('fetchBusinessId: offline — using local fallbacks');
      return _sessionId() ?? await _localDbId();
    }

    // ── Online path: try Supabase first ────────────────────────────────────
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await _supabase
            .from('businesses')
            .select('id')
            .eq('profile_id', userId)
            .maybeSingle();

        final id = response?['id'] as String?;
        if (id != null) {
          debugPrint('fetchBusinessId: resolved from Supabase → $id');
          return id;
        }
        debugPrint(
          'fetchBusinessId: Supabase returned null for userId=$userId — '
          'falling back to local caches',
        );
      } else {
        debugPrint(
          'fetchBusinessId: currentUser is null (token may not have refreshed) '
          '— falling back to local caches',
        );
      }
    } catch (e) {
      debugPrint('fetchBusinessId: Supabase threw $e — falling back to local caches');
    }

    // ── Fallback 1: SessionService in-memory cache ─────────────────────────
    final fromSession = _sessionId();
    if (fromSession != null) {
      debugPrint('fetchBusinessId: resolved from SessionService → $fromSession');
      return fromSession;
    }

    // ── Fallback 2: SQLite local_businesses ────────────────────────────────
    final fromDb = await _localDbId();
    debugPrint('fetchBusinessId: resolved from SQLite → $fromDb');
    return fromDb;
  }

  /// Returns the businessId stored in the in-memory session, or null.
  String? _sessionId() => SessionService.instance.current?.businessId;

  /// Returns the first businessId found in the local SQLite businesses table.
  Future<String?> _localDbId() async {
    try {
      final db = await LocalDatabase.instance.database;
      final rows = await db.query(
        LocalDatabase.tableLocalBusinesses,
        columns: ['id'],
        limit: 1,
      );
      if (rows.isNotEmpty) return rows.first['id'] as String?;
    } catch (e) {
      debugPrint('fetchBusinessId (_localDbId): SQLite error — $e');
    }
    return null;
  }

  // ── Fetch All Guest Records for a Business ────────────────────────────────

  Future<ApiResult<List<GuestRecord>>> fetchGuestRecords(
    String businessId,
  ) async {
    if (ConnectivityService.instance.isOnline) {
      return _fetchOnline(businessId);
    } else {
      return _fetchOffline(businessId);
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
    if (ConnectivityService.instance.isOnline) {
      return _updateOnline(
        recordId:           recordId,
        checkIn:            checkIn,
        checkOut:           checkOut,
        totalGuests:        totalGuests,
        roomsOccupied:      roomsOccupied,
        purposeOfVisit:     purposeOfVisit,
        transportationMode: transportationMode,
        breakdowns:         breakdowns,
      );
    } else {
      return _updateOffline(
        recordId:           recordId,
        checkIn:            checkIn,
        checkOut:           checkOut,
        totalGuests:        totalGuests,
        roomsOccupied:      roomsOccupied,
        purposeOfVisit:     purposeOfVisit,
        transportationMode: transportationMode,
        breakdowns:         breakdowns,
      );
    }
  }

  // ===========================================================================
  // SYNC — called by SyncService when connectivity is restored.
  // Pushes pending_create and pending_update records (with breakdowns)
  // to Supabase, then marks them synced in SQLite.
  // ===========================================================================

  /// Push all locally-created records that haven't reached Supabase yet.
  Future<void> syncPendingCreates() async {
    final db = await LocalDatabase.instance.database;

    final pendingRows = await db.query(
      LocalDatabase.tableGuestRecords,
      where: 'sync_status = ?',
      whereArgs: [LocalDatabase.syncPendingCreate],
    );

    for (final row in pendingRows) {
      final recordId = row['id'] as String;

      try {
        final recordPayload = {
          'id':                  recordId,
          'business_id':         row['business_id'],
          'check_in':            row['check_in'],
          'check_out':           row['check_out'],
          'total_guests':        row['total_guests'],
          'rooms_occupied':      row['rooms_occupied'],
          'purpose_of_visit':    row['purpose_of_visit'],
          'transportation_mode': row['transportation_mode'],
          'status':              row['status'] ?? 'active',
          'is_deleted':          false,
        };

        await _supabase
            .from('guest_records')
            .upsert(recordPayload, onConflict: 'id');

        final breakdownRows = await db.query(
          LocalDatabase.tableGuestBreakdowns,
          where: 'guest_record_id = ?',
          whereArgs: [recordId],
        );

        if (breakdownRows.isNotEmpty) {
          await _supabase
              .from('guest_breakdowns')
              .delete()
              .eq('guest_record_id', recordId);

          await _supabase.from('guest_breakdowns').insert(
            breakdownRows.map((b) => _localBreakdownRowToSupabase(recordId, b)).toList(),
          );
        }

        await db.update(
          LocalDatabase.tableGuestRecords,
          {
            'sync_status':      LocalDatabase.syncSynced,
            'local_updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where:     'id = ?',
          whereArgs: [recordId],
        );

        debugPrint('✅ syncPendingCreates: pushed $recordId');
      } catch (e) {
        debugPrint('❌ syncPendingCreates: failed for $recordId — $e');
      }
    }
  }

  /// Push all locally-edited records that haven't reached Supabase yet.
  Future<void> syncPendingUpdates() async {
    final db = await LocalDatabase.instance.database;

    final pendingRows = await db.query(
      LocalDatabase.tableGuestRecords,
      where: 'sync_status = ?',
      whereArgs: [LocalDatabase.syncPendingUpdate],
    );

    for (final row in pendingRows) {
      final recordId      = row['id'] as String;
      final localUpdated  = row['local_updated_at'] as String?;

      try {
        // ── Last-write-wins: compare timestamps before pushing ───────────────
        if (localUpdated != null) {
          final remoteRow = await _supabase
              .from('guest_records')
              .select('updated_at')
              .eq('id', recordId)
              .maybeSingle();

          if (remoteRow != null) {
            final remoteUpdated = remoteRow['updated_at'] as String?;
            if (remoteUpdated != null) {
              final localDt  = DateTime.tryParse(localUpdated);
              final remoteDt = DateTime.tryParse(remoteUpdated);
              if (localDt != null &&
                  remoteDt != null &&
                  remoteDt.isAfter(localDt)) {
                await db.update(
                  LocalDatabase.tableGuestRecords,
                  {'sync_status': LocalDatabase.syncSynced},
                  where:     'id = ?',
                  whereArgs: [recordId],
                );
                debugPrint(
                  '⚠️ syncPendingUpdates: remote newer for $recordId — discarding local',
                );
                continue;
              }
            }
          }
        }

        await _supabase.from('guest_records').update({
          'check_in':            row['check_in'],
          'check_out':           row['check_out'],
          'total_guests':        row['total_guests'],
          'rooms_occupied':      row['rooms_occupied'],
          'purpose_of_visit':    row['purpose_of_visit'],
          'transportation_mode': row['transportation_mode'],
        }).eq('id', recordId);

        final breakdownRows = await db.query(
          LocalDatabase.tableGuestBreakdowns,
          where: 'guest_record_id = ?',
          whereArgs: [recordId],
        );

        await _supabase
            .from('guest_breakdowns')
            .delete()
            .eq('guest_record_id', recordId);

        if (breakdownRows.isNotEmpty) {
          await _supabase.from('guest_breakdowns').insert(
            breakdownRows
                .map((b) => _localBreakdownRowToSupabase(recordId, b))
                .toList(),
          );
        }

        await db.update(
          LocalDatabase.tableGuestRecords,
          {
            'sync_status':      LocalDatabase.syncSynced,
            'local_updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where:     'id = ?',
          whereArgs: [recordId],
        );

        debugPrint('✅ syncPendingUpdates: pushed $recordId');
      } catch (e) {
        debugPrint('❌ syncPendingUpdates: failed for $recordId — $e');
      }
    }
  }

  // ===========================================================================
  // ONLINE — fetch from Supabase, then refresh local SQLite cache.
  // ===========================================================================

  Future<ApiResult<List<GuestRecord>>> _fetchOnline(String businessId) async {
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
            created_at,
            guest_breakdowns (
              id,
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

      final records = _parseSupabaseRows(rows as List);

      _refreshLocalCache(businessId, rows).catchError(
        (e) => debugPrint('⚠️ Local cache refresh error: $e'),
      );

      return ApiResult.success(records);
    } on PostgrestException catch (e) {
      return ApiResult.failure(e.message);
    } catch (e) {
      return ApiResult.failure('Failed to load records.');
    }
  }

  // ===========================================================================
  // OFFLINE — read entirely from SQLite.
  // ===========================================================================

  Future<ApiResult<List<GuestRecord>>> _fetchOffline(String businessId) async {
    try {
      final db = await LocalDatabase.instance.database;

      final rows = await db.query(
        LocalDatabase.tableGuestRecords,
        where:   'business_id = ? AND is_deleted = 0',
        whereArgs: [businessId],
        orderBy: 'check_in DESC',
      );

      final records = <GuestRecord>[];

      for (final row in rows) {
        final recordId = row['id'] as String;

        final breakdownRows = await db.query(
          LocalDatabase.tableGuestBreakdowns,
          where:     'guest_record_id = ?',
          whereArgs: [recordId],
        );

        final checkIn  = row['check_in']  as String;
        final checkOut = row['check_out'] as String;

        records.add(GuestRecord(
          id:           recordId,
          checkIn:      checkIn,
          checkOut:     checkOut,
          nights:       _calcNights(checkIn, checkOut),
          guests:       (row['total_guests']       as int?) ?? 0,
          rooms:        (row['rooms_occupied']      as int?) ?? 0,
          purpose:      row['purpose_of_visit']     as String? ?? '',
          transport:    row['transportation_mode']  as String? ?? '',
          status:       (row['status'] as String?) == 'archived'
              ? GuestRecordStatus.archived
              : GuestRecordStatus.active,
          demographics: _buildDemographicsFromLocal(breakdownRows),
        ));
      }

      return ApiResult.success(records);
    } catch (e) {
      debugPrint('❌ fetchGuestRecords (offline) error: $e');
      return ApiResult.failure('Failed to load local records.');
    }
  }

  // ===========================================================================
  // ONLINE UPDATE — Supabase first, then mirror to SQLite as synced.
  // ===========================================================================

  Future<ApiResult<void>> _updateOnline({
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
      await _supabase.from('guest_records').update({
        'check_in':            checkIn,
        'check_out':           checkOut,
        'total_guests':        totalGuests,
        'rooms_occupied':      roomsOccupied,
        'purpose_of_visit':    purposeOfVisit,
        'transportation_mode': transportationMode,
      }).eq('id', recordId);

      await _supabase
          .from('guest_breakdowns')
          .delete()
          .eq('guest_record_id', recordId);

      if (breakdowns.isNotEmpty) {
        await _supabase.from('guest_breakdowns').insert(
          breakdowns
              .map((b) => _breakdownEntryToSupabase(recordId, b))
              .toList(),
        );
      }

      if (!kIsWeb) {
        final db = await LocalDatabase.instance.database;
        await db.update(
          LocalDatabase.tableGuestRecords,
          {
            'check_in':            checkIn,
            'check_out':           checkOut,
            'total_guests':        totalGuests,
            'rooms_occupied':      roomsOccupied,
            'purpose_of_visit':    purposeOfVisit,
            'transportation_mode': transportationMode,
            'sync_status':         LocalDatabase.syncSynced,
            'local_updated_at':    DateTime.now().toUtc().toIso8601String(),
          },
          where:     'id = ?',
          whereArgs: [recordId],
        );
        await _replaceLocalBreakdowns(db, recordId, breakdowns);
      }

      return const ApiResult.success(null);
    } on PostgrestException catch (e) {
      return ApiResult.failure('DB error: ${e.message}');
    } catch (e) {
      return ApiResult.failure('Failed to update record: $e');
    }
  }

  // ===========================================================================
  // OFFLINE UPDATE — SQLite only, tagged pending_update.
  // ===========================================================================

  Future<ApiResult<void>> _updateOffline({
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
      final now = DateTime.now().toUtc().toIso8601String();
      final db  = await LocalDatabase.instance.database;

      await db.update(
        LocalDatabase.tableGuestRecords,
        {
          'check_in':            checkIn,
          'check_out':           checkOut,
          'total_guests':        totalGuests,
          'rooms_occupied':      roomsOccupied,
          'purpose_of_visit':    purposeOfVisit,
          'transportation_mode': transportationMode,
          'sync_status':         LocalDatabase.syncPendingUpdate,
          'local_updated_at':    now,
        },
        where:     'id = ?',
        whereArgs: [recordId],
      );

      await _replaceLocalBreakdowns(db, recordId, breakdowns);

      return const ApiResult.success(null);
    } catch (e) {
      debugPrint('❌ updateRecord (offline) error: $e');
      return ApiResult.failure(
        'Failed to save changes locally. Please try again.',
      );
    }
  }

  // ===========================================================================
  // Local cache helpers
  // ===========================================================================

  Future<void> _refreshLocalCache(String businessId, List rows) async {
    if (kIsWeb) {
      debugPrint('⏭ _refreshLocalCache: skipped on web — local SQLite is disabled');
      return;
    }

    final db = await LocalDatabase.instance.database;

    for (final row in rows) {
      final recordId = row['id'] as String;

      final pending = await db.query(
        LocalDatabase.tableGuestRecords,
        columns:   ['sync_status'],
        where:     'id = ? AND sync_status != ?',
        whereArgs: [recordId, LocalDatabase.syncSynced],
        limit:     1,
      );
      if (pending.isNotEmpty) continue;

      await db.insert(
        LocalDatabase.tableGuestRecords,
        {
          'id':                  recordId,
          'business_id':         businessId,
          'check_in':            row['check_in'],
          'check_out':           row['check_out'],
          'total_guests':        row['total_guests'],
          'rooms_occupied':      row['rooms_occupied'],
          'purpose_of_visit':    row['purpose_of_visit'],
          'transportation_mode': row['transportation_mode'],
          'status':              row['status'] ?? 'active',
          'is_deleted':          0,
          'created_at':          row['created_at'],
          'sync_status':         LocalDatabase.syncSynced,
          'local_updated_at':    null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.delete(
        LocalDatabase.tableGuestBreakdowns,
        where:     'guest_record_id = ?',
        whereArgs: [recordId],
      );

      final bds = row['guest_breakdowns'] as List? ?? [];
      for (final b in bds) {
        await db.insert(
          LocalDatabase.tableGuestBreakdowns,
          {
            'id':                 b['id'],
            'guest_record_id':    recordId,
            'country':            b['country'],
            'philippines_region': b['philippines_region'],
            'nationality':        b['nationality'],
            'sex':                b['sex'],
            'age_group':          b['age_group'],
            'count':              b['count'],
            'is_overseas':        (b['is_overseas'] == true) ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> _replaceLocalBreakdowns(
    dynamic db,
    String recordId,
    List<GuestBreakdownEntry> breakdowns,
  ) async {
    await db.delete(
      LocalDatabase.tableGuestBreakdowns,
      where:     'guest_record_id = ?',
      whereArgs: [recordId],
    );

    for (int i = 0; i < breakdowns.length; i++) {
      final b             = breakdowns[i];
      final isOverseas    = b.isOverseas;
      final isPhilippines = !isOverseas && b.country == 'Philippines';

      await db.insert(
        LocalDatabase.tableGuestBreakdowns,
        {
          'id':                 '${recordId}_breakdown_$i',
          'guest_record_id':    recordId,
          'country':            isOverseas ? null : b.country,
          'philippines_region': isPhilippines ? b.philippinesRegion : null,
          'nationality':        isPhilippines ? b.nationality : null,
          'sex':                _mapSex(b.sex),
          'age_group':          _mapAgeGroup(b.ageGroup),
          'count':              b.count,
          'is_overseas':        isOverseas ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ===========================================================================
  // Converts a raw SQLite breakdown row to a Supabase-compatible map.
  // ===========================================================================

  Map<String, dynamic> _localBreakdownRowToSupabase(
    String recordId,
    Map<String, dynamic> b,
  ) {
    final isOverseas = (b['is_overseas'] as int?) == 1;
    return {
      'guest_record_id':    recordId,
      'is_overseas':        isOverseas,
      'country':            isOverseas ? null : b['country'],
      'nationality':        b['nationality'],
      'philippines_region': b['philippines_region'],
      'sex':                b['sex'],
      'age_group':          b['age_group'],
      'count':              b['count'],
    };
  }

  // ===========================================================================
  // Parsing helpers
  // ===========================================================================

  List<GuestRecord> _parseSupabaseRows(List rows) {
    return rows.map((row) {
      final breakdowns = (row['guest_breakdowns'] as List?) ?? [];
      final checkIn    = row['check_in']  as String;
      final checkOut   = row['check_out'] as String;
      final statusStr  = row['status']    as String? ?? 'active';

      return GuestRecord(
        id:           row['id'] as String,
        checkIn:      checkIn,
        checkOut:     checkOut,
        nights:       _calcNights(checkIn, checkOut),
        guests:       (row['total_guests']       as int?) ?? 0,
        rooms:        (row['rooms_occupied']      as int?) ?? 0,
        purpose:      row['purpose_of_visit']     as String? ?? '',
        transport:    row['transportation_mode']  as String? ?? '',
        status:       statusStr == 'archived'
            ? GuestRecordStatus.archived
            : GuestRecordStatus.active,
        demographics: _buildDemographicsFromSupabase(breakdowns),
      );
    }).toList();
  }

  GuestDemographics? _buildDemographicsFromSupabase(List breakdowns) {
    if (breakdowns.isEmpty) return null;

    final ageGroups = <String, int>{};
    final sex       = <String, int>{};
    final countries = <String, int>{};
    final entries   = <GuestBreakdownEntry>[];

    for (final b in breakdowns) {
      final count      = (b['count']       as int?)  ?? 0;
      final isOverseas = (b['is_overseas'] as bool?) ?? false;
      final ageGroup   = b['age_group']    as String? ?? 'Unknown';
      final s          = b['sex']          as String? ?? 'Unknown';

      ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + count;
      sex[s]              = (sex[s]              ?? 0) + count;

      final String countryKey;
      if (isOverseas) {
        countryKey = 'Overseas';
      } else {
        final country = b['country'] as String? ?? 'Unknown';
        final region  = b['philippines_region'] as String?;
        countryKey    = (country == 'Philippines' &&
                region != null && region != 'N/A')
            ? 'PH – $region'
            : country;
      }
      countries[countryKey] = (countries[countryKey] ?? 0) + count;

      entries.add(GuestBreakdownEntry(
        country:           isOverseas ? null : b['country'] as String?,
        nationality:       (!isOverseas && b['country'] == 'Philippines')
            ? b['nationality'] as String?
            : null,
        philippinesRegion: (!isOverseas &&
                b['country'] == 'Philippines' &&
                (b['philippines_region'] as String?) != null &&
                (b['philippines_region'] as String?) != 'N/A')
            ? b['philippines_region'] as String?
            : null,
        sex:        b['sex']       as String? ?? '',
        ageGroup:   b['age_group'] as String? ?? '',
        count:      count,
        isOverseas: isOverseas,
      ));
    }

    return GuestDemographics(
      ageGroups:       ageGroups,
      sexDistribution: sex,
      countries:       countries,
      breakdowns:      entries,
    );
  }

  GuestDemographics? _buildDemographicsFromLocal(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return null;

    final ageGroups = <String, int>{};
    final sex       = <String, int>{};
    final countries = <String, int>{};
    final entries   = <GuestBreakdownEntry>[];

    for (final b in rows) {
      final count      = (b['count']       as int?) ?? 0;
      final isOverseas = (b['is_overseas'] as int?) == 1;
      final ageGroup   = b['age_group']    as String? ?? 'Unknown';
      final s          = b['sex']          as String? ?? 'Unknown';

      ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + count;
      sex[s]              = (sex[s]              ?? 0) + count;

      final String countryKey;
      if (isOverseas) {
        countryKey = 'Overseas';
      } else {
        final country = b['country'] as String? ?? 'Unknown';
        final region  = b['philippines_region'] as String?;
        countryKey    = (country == 'Philippines' &&
                region != null && region != 'N/A')
            ? 'PH – $region'
            : country;
      }
      countries[countryKey] = (countries[countryKey] ?? 0) + count;

      entries.add(GuestBreakdownEntry(
        country:           isOverseas ? null : b['country'] as String?,
        nationality:       (!isOverseas && b['country'] == 'Philippines')
            ? b['nationality'] as String?
            : null,
        philippinesRegion: (!isOverseas &&
                b['country'] == 'Philippines' &&
                (b['philippines_region'] as String?) != null &&
                (b['philippines_region'] as String?) != 'N/A')
            ? b['philippines_region'] as String?
            : null,
        sex:        b['sex']       as String? ?? '',
        ageGroup:   b['age_group'] as String? ?? '',
        count:      count,
        isOverseas: isOverseas,
      ));
    }

    return GuestDemographics(
      ageGroups:       ageGroups,
      sexDistribution: sex,
      countries:       countries,
      breakdowns:      entries,
    );
  }

  Map<String, dynamic> _breakdownEntryToSupabase(
    String recordId,
    GuestBreakdownEntry b,
  ) {
    final isOverseas    = b.isOverseas;
    final isPhilippines = !isOverseas && b.country == 'Philippines';
    return {
      'guest_record_id':    recordId,
      'is_overseas':        isOverseas,
      'country':            isOverseas ? null : b.country,
      'nationality':        isPhilippines ? b.nationality : null,
      'philippines_region': isPhilippines ? b.philippinesRegion : null,
      'sex':                _mapSex(b.sex),
      'age_group':          _mapAgeGroup(b.ageGroup),
      'count':              b.count,
    };
  }

  // ===========================================================================
  // Value mappers
  // ===========================================================================

  String _calcNights(String checkIn, String checkOut) {
    try {
      final inDate  = DateTime.parse(checkIn);
      final outDate = DateTime.parse(checkOut);
      final n       = outDate.difference(inDate).inDays;
      return '$n night${n == 1 ? '' : 's'}';
    } catch (_) {
      return '—';
    }
  }

  String _mapSex(String sex) {
    switch (sex.toLowerCase()) {
      case 'male':   return 'male';
      case 'female': return 'female';
      default:       return 'male';
    }
  }

  String _mapAgeGroup(String ageGroup) {
    final normalised = ageGroup.trim().replaceAll('–', '-');
    switch (normalised) {
      case '0-9':
      case '1-9':               return '1-9';
      case '10-17':             return '10-17';
      case '18-25':             return '18-25';
      case '26-35':             return '26-35';
      case '36-45':             return '36-45';
      case '46-55':             return '46-55';
      case '56+':               return '56+';
      case 'prefer_not_to_say':
      case 'prefer not to say': return 'prefer_not_to_say';
      default:                  return 'prefer_not_to_say';
    }
  }
}