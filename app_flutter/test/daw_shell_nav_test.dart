import 'package:audioapp/app/daw_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DawShellNavGeometry pins bar to left in landscape', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 400)),
          child: Builder(
            builder: (context) {
              final geometry = DawShellNavGeometry.of(context);
              return Stack(
                children: [
                  Padding(
                    padding: geometry.contentPadding,
                    child: const SizedBox.expand(),
                  ),
                  geometry.position(
                    context: context,
                    child: DawShellNav(
                      selectedIndex: 0,
                      geometry: geometry,
                      onDestinationSelected: (_) {},
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(DawShellNavGeometry.of(tester.element(find.byType(Stack))).edge,
        DawShellNavEdge.left);
    expect(find.byType(RotatedBox), findsAtLeastNWidgets(4));
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('DawShellNavGeometry pins bar to bottom in portrait', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final geometry = DawShellNavGeometry.of(context);
              return Stack(
                children: [
                  Padding(
                    padding: geometry.contentPadding,
                    child: const SizedBox.expand(),
                  ),
                  geometry.position(
                    context: context,
                    child: DawShellNav(
                      selectedIndex: 0,
                      geometry: geometry,
                      onDestinationSelected: (_) {},
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(DawShellNavGeometry.of(tester.element(find.byType(Stack))).edge,
        DawShellNavEdge.bottom);
    expect(find.byType(RotatedBox), findsNothing);
  });
}
