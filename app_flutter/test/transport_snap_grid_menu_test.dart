import 'package:audioapp/features/arrangement/snap_grid_resolution.dart';
import 'package:audioapp/features/transport/transport_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('snap menu selects resolution and triplet mode independently',
      (tester) async {
    var resolution = SnapGridResolution.adaptive;
    var triplet = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransportBar(
            bpm: 120,
            playheadBeats: 0,
            playing: false,
            loopEnabled: false,
            loopRegionStartBeat: 0,
            loopRegionEndBeat: 4,
            recordArmed: false,
            followPlayheadEnabled: true,
            followPlayheadSuspended: false,
            onSnapGridResolutionChanged: (value) => resolution = value,
            onSnapGridTripletChanged: (value) => triplet = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.grid_4x4));
    await tester.pumpAndSettle();
    expect(find.text('Adaptive'), findsOneWidget);
    expect(find.text('Straight'), findsOneWidget);
    expect(find.text('Triplets'), findsOneWidget);

    await tester.tap(find.text('1 beat'));
    await tester.pump();
    expect(resolution, SnapGridResolution.one);
    expect(find.text('Triplets'), findsOneWidget);

    await tester.tap(find.text('Triplets'));
    await tester.pump();
    expect(triplet, isTrue);
  });
}
