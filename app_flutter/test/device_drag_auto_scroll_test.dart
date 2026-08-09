import 'package:flutter_test/flutter_test.dart';

/// Mirrors [_DeviceChainRowDragAutoScroll] speed curve for regression.
double _dragAutoScrollDelta({
  required double localX,
  required double viewportWidth,
  required double edgePx,
  required double minPxPerSec,
  required double maxPxPerSec,
  required double dtSec,
}) {
  double direction = 0;
  double depth = 0;
  if (localX < edgePx) {
    direction = -1;
    depth = ((edgePx - localX) / edgePx).clamp(0.0, 1.0);
  } else if (localX > viewportWidth - edgePx) {
    direction = 1;
    depth = ((localX - (viewportWidth - edgePx)) / edgePx).clamp(0.0, 1.0);
  }
  if (direction == 0) return 0;
  final t = depth * depth;
  final speed = minPxPerSec + (maxPxPerSec - minPxPerSec) * t;
  return direction * speed * dtSec;
}

void main() {
  const edge = 96.0;
  const width = 400.0;
  const minV = 70.0;
  const maxV = 480.0;
  const dt = 0.016;

  test('center of viewport does not scroll', () {
    expect(
      _dragAutoScrollDelta(
        localX: width / 2,
        viewportWidth: width,
        edgePx: edge,
        minPxPerSec: minV,
        maxPxPerSec: maxV,
        dtSec: dt,
      ),
      0,
    );
  });

  test('shallow left edge scrolls slowly left', () {
    final delta = _dragAutoScrollDelta(
      localX: edge - 8,
      viewportWidth: width,
      edgePx: edge,
      minPxPerSec: minV,
      maxPxPerSec: maxV,
      dtSec: dt,
    );
    expect(delta, lessThan(0));
    expect(delta.abs(), lessThan(minV * dt * 1.5));
  });

  test('deep right edge scrolls faster than shallow', () {
    final shallow = _dragAutoScrollDelta(
      localX: width - edge + 12,
      viewportWidth: width,
      edgePx: edge,
      minPxPerSec: minV,
      maxPxPerSec: maxV,
      dtSec: dt,
    );
    final deep = _dragAutoScrollDelta(
      localX: width - 4,
      viewportWidth: width,
      edgePx: edge,
      minPxPerSec: minV,
      maxPxPerSec: maxV,
      dtSec: dt,
    );
    expect(shallow, greaterThan(0));
    expect(deep, greaterThan(shallow));
    expect(deep, lessThanOrEqualTo(maxV * dt + 0.001));
  });
}
