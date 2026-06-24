import 'package:audioapp/features/device_strip/device_tool_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeviceToolRail shows bypass and library buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: DeviceToolRail(
              deviceName: 'Sampler',
              accentColor: const Color(0xFFE8A54B),
              bypassed: false,
              showLibrary: true,
              onBypassToggle: () {},
              onLibrary: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    expect(find.byIcon(Icons.library_music_outlined), findsOneWidget);
    expect(find.text('SAMPLER'), findsOneWidget);
  });
}
