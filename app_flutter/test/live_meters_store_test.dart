import 'package:audioapp/bridge/live_meters_dto.dart';
import 'package:audioapp/bridge/live_meters_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyBatch updates readings without duplicate notify', () {
    final store = LiveMetersStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    store.applyBatch(const LiveMetersBatch(meters: [
      DeviceMeterReading(deviceId: 'dev-1', gainReductionDb: -3, inputLevel: 0.5),
    ]));
    expect(notifications, 1);
    expect(store['dev-1']?.gainReductionDb, -3);

    store.applyBatch(const LiveMetersBatch(meters: [
      DeviceMeterReading(deviceId: 'dev-1', gainReductionDb: -3, inputLevel: 0.5),
    ]));
    expect(notifications, 1);
  });
}
