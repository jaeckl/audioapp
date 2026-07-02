import 'package:audioapp/features/content_library/user_device_preset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserDevicePresetStore.cached = const [];
  });

  test('user device presets persist, rename, overwrite and delete', () async {
    const original = UserDevicePreset(
        id: 'user-preset:1',
        name: 'Wide Chain',
        deviceType: 'device_chain',
        presetJson: '{"mix":1}',
        updatedAt: 1);
    await UserDevicePresetStore.save(original);
    expect((await UserDevicePresetStore.load()).single.name, 'Wide Chain');

    await UserDevicePresetStore.rename(original.id, 'Parallel Chain');
    expect(UserDevicePresetStore.cached.single.name, 'Parallel Chain');

    await UserDevicePresetStore.save(const UserDevicePreset(
        id: 'user-preset:1',
        name: 'Parallel Chain',
        deviceType: 'device_chain',
        presetJson: '{"mix":0.5}',
        updatedAt: 2));
    expect(UserDevicePresetStore.cached.single.presetJson, '{"mix":0.5}');

    await UserDevicePresetStore.delete(original.id);
    expect(UserDevicePresetStore.cached, isEmpty);
  });
}
