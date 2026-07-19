part of 'library_content_pane.dart';

class _ResourcePathBar extends StatelessWidget {
  const _ResourcePathBar({
    required this.category,
    required this.step,
    required this.primaryFacet,
    required this.primaryTag,
    required this.secondaryTag,
    required this.deviceType,
    required this.useSecondary,
    required this.accent,
    this.onImportAudio,
    this.onCategoryTap,
    this.onPrimaryTap,
    this.onSecondaryTap,
  });

  final LibraryCategory category;
  final _ResourceBrowseStep step;
  final _PrimaryFacet primaryFacet;
  final String? primaryTag;
  final String? secondaryTag;
  final String? deviceType;
  final bool useSecondary;
  final Color accent;
  final VoidCallback? onImportAudio;
  final VoidCallback? onCategoryTap;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;

  String get _primaryLabel {
    if (primaryFacet == _PrimaryFacet.deviceType) {
      if (deviceType == null) {
        return step == _ResourceBrowseStep.primary ? 'Type' : 'All types';
      }
      final known = kDevicePresetFilters
          .where((f) => f.deviceType == deviceType)
          .map((f) => f.label);
      return known.isEmpty ? deviceType! : known.first;
    }
    if (primaryTag == null) {
      return step == _ResourceBrowseStep.primary
          ? (primaryFacet == _PrimaryFacet.source ? 'Source' : 'Role')
          : (primaryFacet == _PrimaryFacet.source
              ? 'All sources'
              : 'All roles');
    }
    return libraryTagLabel(primaryTag!);
  }

  @override
  Widget build(BuildContext context) {
    final crumbs = <_ResourceCrumb>[
      _ResourceCrumb(
        label: category.title,
        active: step == _ResourceBrowseStep.primary ||
            primaryFacet == _PrimaryFacet.none,
        onTap: onCategoryTap,
      ),
    ];
    if (primaryFacet != _PrimaryFacet.none) {
      crumbs.add(_ResourceCrumb(
        label: _primaryLabel,
        active: step == _ResourceBrowseStep.secondary ||
            (step == _ResourceBrowseStep.results && !useSecondary),
        onTap: step != _ResourceBrowseStep.primary ? onPrimaryTap : null,
      ));
    }
    if (useSecondary &&
        (step == _ResourceBrowseStep.secondary ||
            step == _ResourceBrowseStep.results)) {
      crumbs.add(_ResourceCrumb(
        label: secondaryTag == null
            ? (step == _ResourceBrowseStep.secondary
                ? 'Character'
                : 'All character')
            : libraryTagLabel(secondaryTag!),
        active: step == _ResourceBrowseStep.results,
        onTap: step == _ResourceBrowseStep.results ? onSecondaryTap : null,
      ));
    }
    if (step == _ResourceBrowseStep.results) {
      crumbs.add(const _ResourceCrumb(label: 'Results', active: true));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BROWSE', style: WelcomeTheme.sectionLabel),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < crumbs.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: LibraryTheme.labelMuted
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        _ResourceCrumbChip(crumb: crumbs[i], accent: accent),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onImportAudio != null)
            IconButton(
              tooltip: 'Import audio',
              onPressed: onImportAudio,
              icon: const Icon(Icons.upload_file_outlined,
                  color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

class _ResourceCrumb {
  const _ResourceCrumb({
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
}

class _ResourceCrumbChip extends StatelessWidget {
  const _ResourceCrumbChip({required this.crumb, required this.accent});

  final _ResourceCrumb crumb;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tappable = crumb.onTap != null;
    return Material(
      color: crumb.active ? accent.withValues(alpha: 0.16) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: crumb.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            crumb.label,
            style: TextStyle(
              color: crumb.active
                  ? WelcomeTheme.textPrimary
                  : (tappable
                      ? accent.withValues(alpha: 0.95)
                      : LibraryTheme.labelMuted),
              fontSize: 12,
              fontWeight: crumb.active ? FontWeight.w700 : FontWeight.w600,
              decoration:
                  tappable && !crumb.active ? TextDecoration.underline : null,
              decorationColor: accent.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
