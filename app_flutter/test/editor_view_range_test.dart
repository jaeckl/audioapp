import 'package:audioapp/features/piano_roll/editor_view_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('view range can fit more than four bars', () {
    expect(EditorViewRange.pixelsPerBeatForWidth(320, 4), 20);
    expect(EditorViewRange.pixelsPerBeatForWidth(320, 8), 10);
    expect(EditorViewRange.pixelsPerBeatForWidth(320, 16), 5);
  });
}
