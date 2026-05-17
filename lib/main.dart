import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tourism_app/brick/repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // ── TEMPORARY: clear stale databases ──
  // final dbDir = await databaseFactoryFfi.getDatabasesPath();
  // final mainDb = File(p.join(dbDir, 'my_repository.sqlite'));
  // if (await mainDb.exists()) await mainDb.delete();
  // final queueDb = File(p.join(dbDir, 'brick_offline_queue.sqlite'));
  // if (await queueDb.exists()) await queueDb.delete();
  // ── END TEMPORARY ──

  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(375, 500));
    await windowManager.setMaximumSize(const Size(1440, 900));
  }

  await Repository.configure(databaseFactoryFfi);
  await Repository().initialize();

  debugPaintBaselinesEnabled = false;
  runApp(const App());
}
