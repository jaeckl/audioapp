import 'package:audioapp/features/arrangement/snap_grid_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixed snap resolutions cover 8 through 1/32 beats', () {
    expect(
      SnapGridResolution.values.skip(1).map((value) => value.fixedBeats),
      [8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125],
    );
  });

  test('adaptive grid gets finer as the timeline zooms in', () {
    expect(SnapGridResolution.adaptive.beatsForZoom(4), 8);
    expect(SnapGridResolution.adaptive.beatsForZoom(44), 0.5);
    expect(SnapGridResolution.adaptive.beatsForZoom(600), 0.03125);
  });

  test('triplet grid is two thirds of its straight resolution', () {
    expect(
      SnapGridResolution.one.beatsForZoom(44, triplet: true),
      closeTo(2 / 3, 0.000001),
    );
    expect(
      SnapGridResolution.thirtySecond.beatsForZoom(600, triplet: true),
      closeTo(1 / 48, 0.000001),
    );
  });
}
