import 'package:audioapp/features/transport/transport_bar.dart';
import 'package:audioapp/features/transport/transport_bar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('transport uses rounded panel chrome without a bottom divider',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TransportBar(
            bpm: 120,
            playheadBeats: 0,
            playing: false,
            loopEnabled: true,
            loopRegionStartBeat: 0,
            loopRegionEndBeat: 4,
            recordArmed: false,
            followPlayheadEnabled: true,
            followPlayheadSuspended: false,
          ),
        ),
      ),
    );

    final chrome = tester.widget<Container>(
      find.byKey(const ValueKey('transport-chrome')),
    );
    final decoration = chrome.decoration! as BoxDecoration;
    final border = decoration.border! as Border;

    expect(decoration.borderRadius,
        BorderRadius.circular(TransportBarTheme.panelRadius));
    expect(border.top, border.bottom);
    expect(border.left, border.bottom);
    expect(border.right, border.bottom);
    expect(border.bottom.color, TransportBarTheme.panelBorder);
  });
}
