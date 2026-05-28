import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:tourism_app/core/services/session_service.dart';
import 'package:tourism_app/core/database/local_database.dart';
import 'package:tourism_app/core/services/offline_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'app.dart';

class _AppLifecycleSyncObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ConnectivityService.instance.isOnline) {
      SyncService.instance.sync();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── sqflite desktop init ───────────────────────────────────────────────────
  // Required on Windows, Linux, and macOS. Mobile (Android/iOS) uses the
  // default sqflite and does not need this.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Supabase.initialize(
    url: 'https://vhnuvhmvozzeufgzvzbt.supabase.co',
    anonKey: 'sb_publishable_VgX-aoJBn6FooTfEo2MADA_zzt9KLL9',
  );

  // ── Offline infrastructure ─────────────────────────────────────────────────
  await LocalDatabase.instance.database;
  ConnectivityService.instance.startWatching();
  SyncService.instance.listenForConnectivity();
  WidgetsBinding.instance.addObserver(_AppLifecycleSyncObserver());

  await SessionService.instance.loadAndCache();

  if (ConnectivityService.instance.isOnline) {
    await SyncService.instance.sync();
  }

  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(375, 500));
    await windowManager.setMaximumSize(const Size(1440, 900));
  }

  debugPaintBaselinesEnabled = false;
  runApp(const App());
}