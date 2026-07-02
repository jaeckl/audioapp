import 'package:audioapp/features/content_library/curve_library_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('factory and saved curves share the same library', () async {
    await CurveLibraryStore.save(
      const CurveLibraryResource(
        id: 'curve:user:test',
        name: 'My Curve',
        positions: [0, 0.5, 1],
        values: [0.2, 1, 0.4],
        shapes: [0, 1, 2],
      ),
    );

    final resources = await CurveLibraryStore.load();
    expect(resources.any((item) => item.factory), isTrue);
    final saved = resources.singleWhere((item) => item.id == 'curve:user:test');
    expect(saved.name, 'My Curve');
    expect(saved.positions, [0, 0.5, 1]);
    expect(saved.values, [0.2, 1, 0.4]);
    expect(saved.shapes, [0, 1, 2]);
  });
}
