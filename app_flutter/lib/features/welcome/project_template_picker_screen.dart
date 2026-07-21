import 'package:flutter/material.dart';

import 'project_templates.dart';
import 'welcome_theme.dart';

/// Full-screen template browser pushed on top of the shell when the user
/// starts a new project. Mirrors [ProjectWorkspaceBrowser] navigation style.
class ProjectTemplatePickerScreen extends StatelessWidget {
  const ProjectTemplatePickerScreen({
    super.key,
    this.templates = kProjectTemplates,
  });

  final List<ProjectTemplate> templates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WelcomeTheme.background,
      appBar: AppBar(
        backgroundColor: WelcomeTheme.panelBackground,
        foregroundColor: WelcomeTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('New Project'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Choose a template',
              style: TextStyle(
                color: WelcomeTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start blank or load a genre / advanced routing starter.',
              style: TextStyle(color: WelcomeTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: WelcomeTheme.sectionGap),
            for (final category in ProjectTemplateCategory.values) ...[
              Text(category.label, style: WelcomeTheme.sectionLabel),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: const TextStyle(color: WelcomeTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              _TemplateSection(
                templates: templates
                    .where((template) => template.category == category)
                    .toList(growable: false),
                onSelected: (template) => Navigator.of(context).pop(template),
              ),
              const SizedBox(height: WelcomeTheme.sectionGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _TemplateSection extends StatelessWidget {
  const _TemplateSection({
    required this.templates,
    required this.onSelected,
  });

  final List<ProjectTemplate> templates;
  final ValueChanged<ProjectTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WelcomeTheme.panelBackground,
        borderRadius: BorderRadius.circular(WelcomeTheme.panelRadius),
        border: Border.all(color: WelcomeTheme.panelBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < templates.length; i++)
            _TemplateRow(
              key: ValueKey('template-${templates[i].id}'),
              template: templates[i],
              showDivider: i != templates.length - 1,
              onTap: () => onSelected(templates[i]),
            ),
        ],
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    super.key,
    required this.template,
    required this.showDivider,
    required this.onTap,
  });

  final ProjectTemplate template;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (template.bpm != null) '${template.bpm} BPM',
      if (template.trackCount != null)
        '${template.trackCount} track${template.trackCount == 1 ? '' : 's'}',
    ].join(' · ');

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: WelcomeTheme.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(template.icon,
                        color: WelcomeTheme.accent, size: 21),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            color: WelcomeTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          template.subtitle,
                          style: const TextStyle(
                            color: WelcomeTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            style: TextStyle(
                              color: WelcomeTheme.accent.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          template.detail,
                          style: const TextStyle(
                            color: WelcomeTheme.textMuted,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: WelcomeTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 69,
            color: WelcomeTheme.rowDivider,
          ),
      ],
    );
  }
}
