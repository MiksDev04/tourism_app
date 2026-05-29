import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/local_database.dart';
import 'session_service.dart';

// =============================================================================
// CONNECTIVITY SERVICE
// =============================================================================

class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  // Defaults to true so that a freshly loaded (online) session is never
  // incorrectly blocked before the first connectivity check fires.
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Timer? _timer;

  void startWatching() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    _check();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  Future<void> _check() async {
    if (kIsWeb) {
      if (!_isOnline) {
        _isOnline = true;
        _controller.add(_isOnline);
      }
      return;
    }

    bool online;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }

    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(_isOnline);
    }
  }
}

// =============================================================================
// OFFLINE AUTH SERVICE
// =============================================================================

class OfflineAuthService {
  OfflineAuthService._internal();
  static final OfflineAuthService instance = OfflineAuthService._internal();

  Future<void> cacheProfile({
    required String id,
    required String username,
    required String password,
    String? fullName,
    String? email,
    String? phone,
    String? role,
  }) async {
    final db = await LocalDatabase.instance.database;
    final hash = _hashPassword(password, id);

    await db.insert(
      LocalDatabase.tableLocalProfiles,
      {
        'id': id,
        'username': username,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'password_hash': hash,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> verifyOfflineLogin({
    required String username,
    required String password,
  }) async {
    final db = await LocalDatabase.instance.database;

    final rows = await db.query(
      LocalDatabase.tableLocalProfiles,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final profile = rows.first;
    final expectedHash = _hashPassword(password, profile['id'] as String);

    if (profile['password_hash'] != expectedHash) return null;

    return profile;
  }

  String _hashPassword(String password, String userId) {
    final bytes = utf8.encode(password + userId);
    return sha256.convert(bytes).toString();
  }
}

// =============================================================================
// SYNC STATE
// =============================================================================

enum SyncStatus { idle, syncing, synced, error }

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final String? errorMessage;

  const SyncState({
    required this.status,
    this.pendingCount = 0,
    this.errorMessage,
  });
}

// =============================================================================
// SYNC SERVICE
// =============================================================================

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final _supabase = Supabase.instance.client;

  final StreamController<SyncState> _controller =
      StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncStateStream => _controller.stream;

  SyncState _state = const SyncState(status: SyncStatus.idle);
  SyncState get currentState => _state;

  // ---------------------------------------------------------------------------
  // Delay after connectivity is restored before attempting sync.
  // Gives DNS and the network stack a moment to fully stabilise.
  // ---------------------------------------------------------------------------
  static const _syncDelay = Duration(seconds: 3);

  void listenForConnectivity() {
    ConnectivityService.instance.onConnectivityChanged.listen((isOnline) async {
      if (isOnline) {
        // When connectivity returns, prioritise pulling data for the
        // currently cached business (if available) so local offline
        // records reconcile with the online source immediately.
        try {
          final current = SessionService.instance.current;
          String? businessId = current?.businessId;

          // If the session exists but has no businessId, try local DB.
          if (businessId == null && current != null) {
            final db = await LocalDatabase.instance.database;
            final rows = await db.query(
              LocalDatabase.tableLocalBusinesses,
              where: 'profile_id = ?',
              whereArgs: [current.userId],
              limit: 1,
            );
            if (rows.isNotEmpty) {
              businessId = rows.first['id'] as String?;
            }
          }

          if (businessId != null) {
            await _pullForBusiness(businessId);
          } else {
            // No current business context — fall back to full sync.
            await Future.delayed(_syncDelay);
            await sync();
            return;
          }
        } catch (e) {
          debugPrint('⚠️ listenForConnectivity: pull-for-business failed: $e');
        }

        // Only clear the offline-session flag after the business pull
        // completes so guarded routes see consistent data.
        await _clearOfflineSessionFlag();

        // Now perform full sync (after a short stabilisation delay).
        Future.delayed(_syncDelay, sync);
      }
    });
  }

  /// Clears the `isOfflineSession` flag on the in-memory session and persists
  /// the change to SharedPreferences.
  Future<void> _clearOfflineSessionFlag() async {
    final current = SessionService.instance.current;
    if (current == null || !current.isOfflineSession) return;

    final updated = SessionData(
      userId:             current.userId,
      fullName:           current.fullName,
      username:           current.username,
      email:              current.email,
      phone:              current.phone,
      role:               current.role,
      isOfflineSession:   false,
      businessId:         current.businessId,
      businessName:       current.businessName,
      permitNumber:       current.permitNumber,
      registrationNumber: current.registrationNumber,
      street:             current.street,
      totalRooms:         current.totalRooms,
      permitFileUrl:      current.permitFileUrl,
      validIdUrl:         current.validIdUrl,
      businessType:       current.businessType,
      status:             current.status,
      remarks:            current.remarks,
      region:             current.region,
      cityMunicipality:   current.cityMunicipality,
      province:           current.province,
      barangay:           current.barangay,
      tradename:          current.tradename,
      businessLine:       current.businessLine,
      ownerFirstName:     current.ownerFirstName,
      ownerLastName:      current.ownerLastName,
      ownerMiddleName:    current.ownerMiddleName,
    );

    await SessionService.instance.save(updated);
    await SessionService.instance.loadAndCache();
    debugPrint('✅ _clearOfflineSessionFlag: isOfflineSession reset to false');
  }

  Future<void> sync() async {
    if (kIsWeb) {
      debugPrint('⏭ sync: skipped on web — local SQLite is disabled');
      return;
    }

    if (_state.status == SyncStatus.syncing) return;

    // Double-check connectivity right before syncing — the flag may have
    // changed in the brief window since listenForConnectivity fired.
    if (!ConnectivityService.instance.isOnline) {
      debugPrint('⏭ sync: skipped — device is offline');
      return;
    }

    _emit(const SyncState(status: SyncStatus.syncing));

    try {
      await _pushPendingCreates();
      await _pushPendingUpdates();
      await _pullFromSupabase();

      final remaining = await _countPending();
      _emit(SyncState(status: SyncStatus.synced, pendingCount: remaining));
    } catch (e) {
      _emit(SyncState(
        status: SyncStatus.error,
        errorMessage: e.toString(),
        pendingCount: await _countPending(),
      ));
    }
  }

  Future<int> getPendingCount() => _countPending();

  // ---------------------------------------------------------------------------
  // Returns true when the device can actually reach the Supabase host.
  // Used as a pre-flight check before each push phase.
  // ---------------------------------------------------------------------------
  Future<bool> _canReachSupabase() async {
    // Keep this guard version-safe across supabase_flutter updates by relying
    // on our global connectivity probe rather than an internal URL getter.
    return ConnectivityService.instance.isOnline;
  }

  // ---------------------------------------------------------------------------
  // PUSH — pending_create
  // ---------------------------------------------------------------------------
  Future<void> _pushPendingCreates() async {
    // Abort immediately if Supabase is unreachable — avoids per-record DNS
    // failures when the connection is still settling after coming back online.
    if (!await _canReachSupabase()) {
      debugPrint('⏭ _pushPendingCreates: skipped — Supabase unreachable');
      return;
    }

    final db = await LocalDatabase.instance.database;

    final records = await db.query(
      LocalDatabase.tableGuestRecords,
      where: 'sync_status = ?',
      whereArgs: [LocalDatabase.syncPendingCreate],
    );

    for (final record in records) {
      final recordId = record['id'] as String;

      try {
        // Upsert parent record first and wait for it to commit.
        await _supabase
            .from('guest_records')
            .upsert(_toSupabaseRecord(record), onConflict: 'id');

        // Delete stale breakdowns then re-insert the local set.
        final breakdowns = await db.query(
          LocalDatabase.tableGuestBreakdowns,
          where:     'guest_record_id = ?',
          whereArgs: [recordId],
        );

        await _supabase
            .from('guest_breakdowns')
            .delete()
            .eq('guest_record_id', recordId);

        if (breakdowns.isNotEmpty) {
          await _supabase
              .from('guest_breakdowns')
              .insert(breakdowns.map(_toSupabaseBreakdown).toList());
        }

        // Mark synced only after both upserts succeed.
        await db.update(
          LocalDatabase.tableGuestRecords,
          {
            'sync_status':      LocalDatabase.syncSynced,
            'local_updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where:     'id = ?',
          whereArgs: [recordId],
        );

        debugPrint('✅ _pushPendingCreates: pushed $recordId');
      } on SocketException catch (e) {
        // Network dropped mid-sync — abort this phase entirely so the
        // remaining records are retried on the next sync cycle.
        debugPrint('🌐 _pushPendingCreates: network lost — aborting ($e)');
        return;
      } catch (e) {
        // Non-network error — log and continue to the next record.
        debugPrint('❌ _pushPendingCreates: failed for $recordId — $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PUSH — pending_update
  // ---------------------------------------------------------------------------
  Future<void> _pushPendingUpdates() async {
    // Same pre-flight guard as _pushPendingCreates.
    if (!await _canReachSupabase()) {
      debugPrint('⏭ _pushPendingUpdates: skipped — Supabase unreachable');
      return;
    }

    final db = await LocalDatabase.instance.database;

    final records = await db.query(
      LocalDatabase.tableGuestRecords,
      where: 'sync_status = ?',
      whereArgs: [LocalDatabase.syncPendingUpdate],
    );

    for (final record in records) {
      final recordId = record['id'] as String;

      try {
        // Upsert instead of update — handles the case where a record was
        // created AND edited offline before ever reaching Supabase, meaning
        // its sync_status advanced straight to pending_update without ever
        // being pushed as pending_create. Without upsert the parent row would
        // be missing and the breakdown insert would fail the RLS check.
        await _supabase
            .from('guest_records')
            .upsert(_toSupabaseRecord(record), onConflict: 'id');

        // Replace breakdowns in full.
        final breakdowns = await db.query(
          LocalDatabase.tableGuestBreakdowns,
          where:     'guest_record_id = ?',
          whereArgs: [recordId],
        );

        await _supabase
            .from('guest_breakdowns')
            .delete()
            .eq('guest_record_id', recordId);

        if (breakdowns.isNotEmpty) {
          await _supabase
              .from('guest_breakdowns')
              .insert(breakdowns.map(_toSupabaseBreakdown).toList());
        }

        // Mark synced only after both succeed.
        await db.update(
          LocalDatabase.tableGuestRecords,
          {
            'sync_status':      LocalDatabase.syncSynced,
            'local_updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where:     'id = ?',
          whereArgs: [recordId],
        );

        debugPrint('✅ _pushPendingUpdates: pushed $recordId');
      } on SocketException catch (e) {
        // Network dropped mid-sync — abort this phase.
        debugPrint('🌐 _pushPendingUpdates: network lost — aborting ($e)');
        return;
      } catch (e) {
        debugPrint('❌ _pushPendingUpdates: failed for $recordId — $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PULL — fetch all Supabase records into local SQLite.
  // Skips any record that still has pending local changes.
  // ---------------------------------------------------------------------------
  Future<void> _pullFromSupabase() async {
    if (!await _canReachSupabase()) {
      debugPrint('⏭ _pullFromSupabase: skipped — Supabase unreachable');
      return;
    }

    final db = await LocalDatabase.instance.database;

    final businesses = await db.query(
      LocalDatabase.tableLocalBusinesses,
      columns: ['id'],
    );

    for (final business in businesses) {
      final businessId = business['id'] as String;

      try {
        final remoteRecords = await _supabase
            .from('guest_records')
            .select('*, guest_breakdowns(*)')
            .eq('business_id', businessId);

        for (final remote in remoteRecords) {
          final recordId = remote['id'] as String;

          // Don't overwrite a record with unsent local changes.
          final pending = await db.query(
            LocalDatabase.tableGuestRecords,
            where:     'id = ? AND sync_status != ?',
            whereArgs: [recordId, LocalDatabase.syncSynced],
            limit:     1,
          );
          if (pending.isNotEmpty) continue;

          await db.insert(
            LocalDatabase.tableGuestRecords,
            _fromSupabaseRecord(remote),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await db.delete(
            LocalDatabase.tableGuestBreakdowns,
            where:     'guest_record_id = ?',
            whereArgs: [recordId],
          );

          final breakdowns =
              remote['guest_breakdowns'] as List<dynamic>? ?? [];

          for (final b in breakdowns) {
            await db.insert(
              LocalDatabase.tableGuestBreakdowns,
              _fromSupabaseBreakdown(b as Map<String, dynamic>),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      } on SocketException catch (e) {
        debugPrint('🌐 _pullFromSupabase: network lost — aborting ($e)');
        return;
      } catch (e) {
        debugPrint('❌ _pullFromSupabase: failed for business $businessId — $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PULL — fetch Supabase records for a single business_id into local SQLite.
  // Used when connectivity is restored to prioritise the current session's
  // business data.
  // ---------------------------------------------------------------------------
  Future<void> _pullForBusiness(String businessId) async {
    if (!await _canReachSupabase()) {
      debugPrint('⏭ _pullForBusiness: skipped — Supabase unreachable');
      return;
    }

    final db = await LocalDatabase.instance.database;

    try {
      final remoteRecords = await _supabase
          .from('guest_records')
          .select('*, guest_breakdowns(*)')
          .eq('business_id', businessId);

      for (final remote in remoteRecords) {
        final recordId = remote['id'] as String;

        // Don't overwrite a record with unsent local changes.
        final pending = await db.query(
          LocalDatabase.tableGuestRecords,
          where:     'id = ? AND sync_status != ?',
          whereArgs: [recordId, LocalDatabase.syncSynced],
          limit:     1,
        );
        if (pending.isNotEmpty) continue;

        await db.insert(
          LocalDatabase.tableGuestRecords,
          _fromSupabaseRecord(remote),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await db.delete(
          LocalDatabase.tableGuestBreakdowns,
          where:     'guest_record_id = ?',
          whereArgs: [recordId],
        );

        final breakdowns = remote['guest_breakdowns'] as List<dynamic>? ?? [];

        for (final b in breakdowns) {
          await db.insert(
            LocalDatabase.tableGuestBreakdowns,
            _fromSupabaseBreakdown(b as Map<String, dynamic>),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } on SocketException catch (e) {
      debugPrint('🌐 _pullForBusiness: network lost — aborting ($e)');
      return;
    } catch (e) {
      debugPrint('❌ _pullForBusiness: failed for business $businessId — $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Count all records not yet synced.
  // ---------------------------------------------------------------------------
  Future<int> _countPending() async {
    if (kIsWeb) return 0;

    final db = await LocalDatabase.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${LocalDatabase.tableGuestRecords}
      WHERE sync_status != ?
      ''',
      [LocalDatabase.syncSynced],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  void _emit(SyncState state) {
    _state = state;
    _controller.add(state);
  }

  // ---------------------------------------------------------------------------
  // local row → Supabase record map (strips local-only columns).
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _toSupabaseRecord(Map<String, dynamic> row) {
    return {
      'id':                  row['id'],
      'business_id':         row['business_id'],
      'check_in':            row['check_in'],
      'check_out':           row['check_out'],
      'total_guests':        row['total_guests'],
      'rooms_occupied':      row['rooms_occupied'],
      'purpose_of_visit':    row['purpose_of_visit'],
      'transportation_mode': row['transportation_mode'],
      'status':              row['status'],
      'is_deleted':          row['is_deleted'] == 1,
      'created_at':          row['created_at'],
    };
  }

  // ---------------------------------------------------------------------------
  // local breakdown row → Supabase breakdown map.
  //
  // ⚠️  'id' is intentionally excluded. The local id is a composite string
  //     (e.g. "uuid_male_18-25_3"), not a UUID. Including it causes Supabase
  //     to reject the insert because the guest_breakdowns.id column expects a
  //     UUID. Letting Supabase auto-generate the id is the correct behaviour.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _toSupabaseBreakdown(Map<String, dynamic> row) {
    return {
      'guest_record_id':    row['guest_record_id'],
      'country':            row['country'],
      'philippines_region': row['philippines_region'],
      'nationality':        row['nationality'],
      'sex':                row['sex'],
      'age_group':          row['age_group'],
      'count':              row['count'],
      'is_overseas':        row['is_overseas'] == 1,
    };
  }

  // ---------------------------------------------------------------------------
  // Supabase record → local SQLite row (adds local-only columns).
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _fromSupabaseRecord(Map<String, dynamic> row) {
    return {
      'id':                  row['id'],
      'business_id':         row['business_id'],
      'check_in':            row['check_in'],
      'check_out':           row['check_out'],
      'total_guests':        row['total_guests'],
      'rooms_occupied':      row['rooms_occupied'],
      'purpose_of_visit':    row['purpose_of_visit'],
      'transportation_mode': row['transportation_mode'],
      'status':              row['status'] ?? 'active',
      'is_deleted':          (row['is_deleted'] == true) ? 1 : 0,
      'created_at':          row['created_at'],
      'sync_status':         LocalDatabase.syncSynced,
      'local_updated_at':    null,
    };
  }

  Map<String, dynamic> _fromSupabaseBreakdown(Map<String, dynamic> row) {
    return {
      'id':                 row['id'],
      'guest_record_id':    row['guest_record_id'],
      'country':            row['country'],
      'philippines_region': row['philippines_region'],
      'nationality':        row['nationality'],
      'sex':                row['sex'],
      'age_group':          row['age_group'],
      'count':              row['count'],
      'is_overseas':        (row['is_overseas'] == true) ? 1 : 0,
    };
  }
}
