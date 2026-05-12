import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // or sqflite depending on platform
import 'package:tourism_app/brick/repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi; // ← set the global before anything else

  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(375, 500));
    await windowManager.setMaximumSize(const Size(1440, 900));
  }

  await Repository.configure(databaseFactoryFfi);

  debugPaintBaselinesEnabled = false;
  runApp(const App());
}