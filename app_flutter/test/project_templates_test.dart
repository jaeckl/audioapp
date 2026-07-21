import 'package:audioapp/features/welcome/project_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project templates include starter, genre, and advanced entries', () {
    expect(
      templatesForCategory(ProjectTemplateCategory.starter),
      isNotEmpty,
    );
    expect(
      templatesForCategory(ProjectTemplateCategory.genre).length,
      greaterThanOrEqualTo(4),
    );
    expect(
      templatesForCategory(ProjectTemplateCategory.advanced).length,
      greaterThanOrEqualTo(3),
    );
    expect(
      kProjectTemplates.any((template) => template.isProceduralEmpty),
      isTrue,
    );
    expect(
      kProjectTemplates.where((template) => template.assetPath != null).length,
      greaterThanOrEqualTo(7),
    );
  });
}
