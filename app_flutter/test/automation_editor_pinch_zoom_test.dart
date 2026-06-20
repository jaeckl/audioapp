import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/automation/automation_editor_metrics.dart';
import 'package:audioapp/features/automation/automation_editor_viewport.dart';
import 'package:audioapp/features/piano_roll/piano_roll_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'horizontal-only pinch zooms time axis and leaves value axis untouched',
    (tester) async {
      await _pumpViewport(tester, bodyHeight: 400);
      final canvas = _findCanvas(tester);
      final before = tester.getSize(canvas);

      final origin = _canvasOrigin(tester);
      final left = await tester.startGesture(
        origin.translate(-80, 0),
        pointer: 1,
      );
      final right = await tester.startGesture(
        origin.translate(80, 0),
        pointer: 2,
      );

      for (var step = 0; step < 8; step++) {
        await left.moveBy(const Offset(-10, 0));
        await right.moveBy(const Offset(10, 0));
        await tester.pump();
      }

      final after = tester.getSize(canvas);
      expect(after.width, greaterThan(before.width));
      expect(after.height, before.height);

      await left.up();
      await right.up();
    },
  );

  testWidgets(
    'vertical-only pinch zooms value axis and leaves time axis untouched',
    (tester) async {
      await _pumpViewport(tester, bodyHeight: 600);
      final canvas = _findCanvas(tester);
      final before = tester.getSize(canvas);

      final origin = _canvasOrigin(tester);
      final top = await tester.startGesture(
        origin.translate(0, -80),
        pointer: 1,
      );
      final bottom = await tester.startGesture(
        origin.translate(0, 80),
        pointer: 2,
      );

      for (var step = 0; step < 8; step++) {
        await top.moveBy(const Offset(0, -6));
        await bottom.moveBy(const Offset(0, 6));
        await tester.pump();
      }

      final after = tester.getSize(canvas);
      expect(after.height, greaterThan(before.height));
      expect(after.width, before.width);

      await top.up();
      await bottom.up();
    },
  );

  testWidgets(
    'horizontal pinch-in shrinks time axis and leaves value axis untouched',
    (tester) async {
      await _pumpViewport(tester, bodyHeight: 400);
      final canvas = _findCanvas(tester);
      final before = tester.getSize(canvas);

      final origin = _canvasOrigin(tester);
      // Start the fingers 160px apart horizontally.
      final left = await tester.startGesture(
        origin.translate(-80, 0),
        pointer: 1,
      );
      final right = await tester.startGesture(
        origin.translate(80, 0),
        pointer: 2,
      );

      // Pinch-in: bring fingers toward each other.
      for (var step = 0; step < 6; step++) {
        await left.moveBy(const Offset(8, 0));
        await right.moveBy(const Offset(-8, 0));
        await tester.pump();
      }

      final after = tester.getSize(canvas);
      expect(after.width, lessThan(before.width));
      expect(after.height, before.height);

      await left.up();
      await right.up();
    },
  );

  testWidgets(
    'axis lock holds: horizontal gesture stays horizontal even when Y span '
    'temporarily overtakes X span mid-gesture',
    (tester) async {
      await _pumpViewport(tester, bodyHeight: 600);
      final canvas = _findCanvas(tester);
      final before = tester.getSize(canvas);

      final origin = _canvasOrigin(tester);
      // Spread clearly along X (240px) and only 4px along Y so the
      // resolver picks horizontal with a wide margin.
      final left = await tester.startGesture(
        origin.translate(-120, -2),
        pointer: 1,
      );
      final right = await tester.startGesture(
        origin.translate(120, 2),
        pointer: 2,
      );

      // First, move both fingers OUTWARD along X to grow the time axis.
      for (var step = 0; step < 4; step++) {
        await left.moveBy(const Offset(-10, 0));
        await right.moveBy(const Offset(10, 0));
        await tester.pump();
      }
      // Then SWING them apart along Y, well past the 1.15 ratio threshold,
      // while keeping X span constant. The locked axis should remain
      // horizontal: Y span changes must NOT bleed into height changes.
      for (var step = 0; step < 8; step++) {
        await left.moveBy(const Offset(0, -12));
        await right.moveBy(const Offset(0, 12));
        await tester.pump();
      }
      // Then swing them back along X to make sure axis is still horizontal.
      for (var step = 0; step < 8; step++) {
        await left.moveBy(const Offset(-10, 0));
        await right.moveBy(const Offset(10, 0));
        await tester.pump();
      }

      final after = tester.getSize(canvas);
      // Width grew (we only ever zoomed horizontal).
      expect(after.width, greaterThan(before.width));
      // Height must NOT have grown even though Y span exploded mid-gesture.
      expect(after.height, before.height);

      await left.up();
      await right.up();
    },
  );

  testWidgets(
    'horizontal pinch is clamped at maxPixelsPerBeat (96)',
    (tester) async {
      await _pumpViewport(tester, bodyHeight: 400);
      final canvas = _findCanvas(tester);
      final before = tester.getSize(canvas);

      final origin = _canvasOrigin(tester);
      final left = await tester.startGesture(
        origin.translate(-30, 0),
        pointer: 1,
      );
      final right = await tester.startGesture(
        origin.translate(30, 0),
        pointer: 2,
      );

      // Pinch-out aggressively to force clamp at maxPixelsPerBeat.
      for (var step = 0; step < 30; step++) {
        await left.moveBy(const Offset(-20, 0));
        await right.moveBy(const Offset(20, 0));
        await tester.pump();
      }

      final after = tester.getSize(canvas);
      // Width must grow but cannot exceed virtualLengthBeats *
      // maxPixelsPerBeat = 32 * 96 = 3072.
      expect(after.width, greaterThan(before.width));
      expect(
        after.width,
        lessThanOrEqualTo(
          AutomationEditorMetrics.virtualLengthBeats(4) *
              PianoRollMetrics.maxPixelsPerBeat +
              0.5,
        ),
      );

      await left.up();
      await right.up();
    },
  );

  testWidgets(
    'vertical pinch is clamped at maxValueAxisScale (4x viewport)',
    (tester) async {
      const viewportHeight = 600.0;
      await _pumpViewport(tester, bodyHeight: viewportHeight.toInt());
      final canvas = _findCanvas(tester);
      final before = tester.getSize(canvas);

      final origin = _canvasOrigin(tester);
      final top = await tester.startGesture(
        origin.translate(0, -20),
        pointer: 1,
      );
      final bottom = await tester.startGesture(
        origin.translate(0, 20),
        pointer: 2,
      );

      // Pinch-out aggressively along Y to force clamp at the upper bound.
      for (var step = 0; step < 30; step++) {
        await top.moveBy(const Offset(0, -12));
        await bottom.moveBy(const Offset(0, 12));
        await tester.pump();
      }

      final after = tester.getSize(canvas);
      // Height grew but is bounded by viewportHeight * 4.
      expect(after.height, greaterThan(before.height));
      expect(
        after.height,
        lessThanOrEqualTo(viewportHeight * AutomationEditorMetrics.maxValueAxisScale + 0.5),
      );

      await top.up();
      await bottom.up();
    },
  );

  testWidgets(
    'releasing both pointers clears pinch state, allowing a second pinch '
    'on the opposite axis afterwards',
    (tester) async {
      await _pumpViewport(tester, bodyHeight: 600);
      final canvas = _findCanvas(tester);
      final startSize = tester.getSize(canvas);

      // First gesture: horizontal pinch-out.
      final origin = _canvasOrigin(tester);
      final h1 = await tester.startGesture(
        origin.translate(-40, 0),
        pointer: 1,
      );
      final h2 = await tester.startGesture(
        origin.translate(40, 0),
        pointer: 2,
      );
      for (var step = 0; step < 4; step++) {
        await h1.moveBy(const Offset(-10, 0));
        await h2.moveBy(const Offset(10, 0));
        await tester.pump();
      }
      await h1.up();
      await h2.up();

      final afterHorizontal = tester.getSize(canvas);
      expect(
        afterHorizontal.width,
        greaterThan(startSize.width),
        reason: 'first horizontal pinch should have widened the time axis',
      );

      // Second gesture: vertical pinch-out, starting fresh. Axis resolution
      // should NOT remember the previous horizontal decision.
      final v1 = await tester.startGesture(
        origin.translate(0, -40),
        pointer: 1,
      );
      final v2 = await tester.startGesture(
        origin.translate(0, 40),
        pointer: 2,
      );
      for (var step = 0; step < 6; step++) {
        await v1.moveBy(const Offset(0, -8));
        await v2.moveBy(const Offset(0, 8));
        await tester.pump();
      }

      final afterVertical = tester.getSize(canvas);
      expect(
        afterVertical.height,
        greaterThan(afterHorizontal.height),
        reason: 'second vertical pinch should have grown the value axis',
      );
      // Width must stay where the previous (horizontal) gesture left it;
      // the vertical pinch must not reset it.
      expect(afterVertical.width, afterHorizontal.width);

      await v1.up();
      await v2.up();
    },
  );
}

// ---------------------------------------------------------------------------
// Test plumbing
// ---------------------------------------------------------------------------

Future<void> _pumpViewport(WidgetTester tester, {required int bodyHeight}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: bodyHeight.toDouble(),
          child: AutomationEditorViewport(
            points: const [
              AutomationPointSnapshot(beat: 0, value: 1),
              AutomationPointSnapshot(beat: 4, value: 0.25),
            ],
            clipLengthBeats: 4,
            virtualLengthBeats: 32,
            gridSettings: const PianoRollGridSettings(),
            tool: AutomationEditorTool.select,
            selectedIndices: const <int>{},
            deleteMarkedIndices: const <int>{},
            onPointsChanged: _noop,
            onToggleSelect: _noopInt,
            onToggleDeleteMark: _noopInt,
            onClearSelection: _noopVoid,
            onEditStarted: _noopVoid,
            onEditFinished: _noopVoid,
          ),
        ),
      ),
    ),
  ).then((_) => tester.pumpAndSettle());
}

Finder _findCanvas(WidgetTester tester) {
  return find.descendant(
    of: find.byType(AutomationEditorViewport),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox &&
          widget.height != null &&
          widget.height! >= AutomationEditorMetrics.minValueAxisHeight - 1 &&
          widget.width != null &&
          widget.width! > AutomationEditorMetrics.valueColumnWidth,
    ),
  );
}

/// Returns a point well inside the canvas Listener — to the right of the
/// value column and below the ruler band — that all gestures anchor from.
Offset _canvasOrigin(WidgetTester tester) {
  final rect = tester.getRect(find.byType(AutomationEditorViewport));
  return Offset(
    rect.left + AutomationEditorMetrics.valueColumnWidth + 160,
    rect.top + AutomationEditorMetrics.rulerHeight + 160,
  );
}

void _noop(List<AutomationPointSnapshot> _) {}
void _noopInt(int _) {}
void _noopVoid() {}
