import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';

void main() async {
   // 1. Required setup for desktop apps
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize the window manager
  await windowManager.ensureInitialized();

  // 3. Define your constraints here
  await windowManager.setMinimumSize(const Size(700, 500));
  await windowManager.setMaximumSize(const Size(1440, 900));
  
  
  debugPaintBaselinesEnabled = false;
  runApp(const App());
}