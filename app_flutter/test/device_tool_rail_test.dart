import 'package:audioapp/features/device_strip/device_tool_rail.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeviceToolRail shows bypass and library buttons',
      (tester) async {
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

  testWidgets('bypass button requests automation on long press',
      (tester) async {
    var automateCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: DeviceToolRail(
              deviceName: 'Sampler',
              accentColor: const Color(0xFFE8A54B),
              bypassed: false,
              showLibrary: false,
              onBypassToggle: () {},
              onAutomateBypass: () => automateCount++,
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byIcon(Icons.power_settings_new));
    expect(automateCount, 1);
  });

  testWidgets('bypass button links automation when link mode is active',
      (tester) async {
    var toggleCount = 0;
    var linkCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: DeviceToolRail(
              deviceName: 'Sampler',
              accentColor: const Color(0xFFE8A54B),
              bypassed: false,
              showLibrary: false,
              onBypassToggle: () => toggleCount++,
              bypassLinkModeActive: true,
              onBypassAutomationLinkTap: () => linkCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.power_settings_new));
    expect(linkCount, 1);
    expect(toggleCount, 0);
  });

  testWidgets('bypass button assigns modulation in connect mode',
      (tester) async {
    double? assignedAmount;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: DeviceToolRail(
              deviceName: 'Sampler',
              accentColor: const Color(0xFFE8A54B),
              bypassed: false,
              showLibrary: false,
              onBypassToggle: () {},
              bypassConnectModeActive: true,
              onBypassModulationAssign: (amount) => assignedAmount = amount,
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byIcon(Icons.power_settings_new));
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    await gesture.up();

    expect(assignedAmount, isNotNull);
    expect(assignedAmount, 1.0);
  });

  testWidgets('bypass connect mode drag down assigns negative binary state',
      (tester) async {
    double? assignedAmount;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: DeviceToolRail(
              deviceName: 'Sampler',
              accentColor: const Color(0xFFE8A54B),
              bypassed: false,
              showLibrary: false,
              onBypassToggle: () {},
              bypassConnectModeActive: true,
              onBypassModulationAssign: (amount) => assignedAmount = amount,
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byIcon(Icons.power_settings_new));
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    await gesture.up();

    expect(assignedAmount, -1.0);
  });
}
