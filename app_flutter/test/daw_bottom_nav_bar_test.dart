import 'package:audioapp/app/daw_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DawBottomNavBar rotates icons in landscape', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 400)),
          child: Scaffold(
            bottomNavigationBar: DawBottomNavBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RotatedBox), findsAtLeastNWidgets(4));
  });

  testWidgets('DawBottomNavBar does not rotate icons in portrait', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            bottomNavigationBar: DawBottomNavBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RotatedBox), findsNothing);
  });
}
