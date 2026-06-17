import 'package:audioapp/features/device_strip/device_header_tab_bar.dart';
import 'package:audioapp/features/device_strip/device_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeviceHeaderTabBar shows flat tabs with selected highlight', (tester) async {
    const tabs = [
      DeviceTabSpec(label: 'Sample', icon: Icons.graphic_eq),
      DeviceTabSpec(label: 'Env', icon: Icons.show_chart),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceHeaderTabBar(
            tabs: tabs,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Sample'), findsOneWidget);
    expect(find.text('Env'), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
  });
}
