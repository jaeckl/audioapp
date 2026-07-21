import 'package:audioapp/features/welcome/project_template_picker_screen.dart';
import 'package:audioapp/features/welcome/project_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('template picker returns selected template', (tester) async {
    ProjectTemplate? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  selected = await Navigator.of(context).push<ProjectTemplate>(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const ProjectTemplatePickerScreen(),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a template'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('template-template-beat-lab')));
    await tester.pumpAndSettle();

    expect(selected?.id, 'template-beat-lab');
    expect(selected?.assetPath, 'assets/project_templates/beat_lab.json');
  });
}
