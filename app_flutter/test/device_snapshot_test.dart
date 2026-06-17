import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DeviceSnapshot reads bypass from bool or number', () {
    final fromBool = DeviceSnapshot.fromMap({
      'id': 'dev-1',
      'type': 'simple_sampler',
      'parameters': {'bypass': false},
    });
    expect(fromBool.bypassed, isFalse);

    final fromTrue = DeviceSnapshot.fromMap({
      'id': 'dev-2',
      'type': 'simple_sampler',
      'parameters': {'bypass': true},
    });
    expect(fromTrue.bypassed, isTrue);

    final fromNumber = DeviceSnapshot.fromMap({
      'id': 'dev-3',
      'type': 'simple_sampler',
      'parameters': {'bypass': 1},
    });
    expect(fromNumber.bypassed, isTrue);
  });
}
