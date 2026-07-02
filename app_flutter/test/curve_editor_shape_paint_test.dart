import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/curve_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('curve modulator paints a repeated toolbar shape',
      (tester) async {
    List<Map<String, dynamic>>? saved;
    await tester.pumpWidget(MaterialApp(
      home: CurveEditorScreen(
        mod: const LfoSnapshot(id: 1, type: 'curve'),
        onUpdate: (_, __) async {},
        onBatchUpdate: (updates) async => saved = updates,
      ),
    ));

    await tester.tap(find.byTooltip('Sine'));
    await tester.pump();

    final canvas = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter.runtimeType.toString() == '_CurveEditorPainter',
    );
    expect(canvas, findsOneWidget);
    final rect = tester.getRect(canvas);
    final gesture = await tester.startGesture(
      Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.7),
    );
    await gesture.moveTo(
      Offset(rect.left + rect.width * 0.5, rect.top + rect.height * 0.45),
    );
    await tester.pump();
    await gesture.moveTo(
      Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.25),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(saved, isNotNull);
    final count = saved!.firstWhere(
      (update) => update['param'] == 'breakpointCount',
    )['value'] as double;
    expect(count, greaterThan(2));
  });
}
