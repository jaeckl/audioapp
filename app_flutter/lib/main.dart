import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/daw_shell.dart';
import 'bridge/engine_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AudioApp());
}

class AudioApp extends StatelessWidget {
  const AudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioApp DAW',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DawShell(bridge: EngineBridge()),
    );
  }
}
