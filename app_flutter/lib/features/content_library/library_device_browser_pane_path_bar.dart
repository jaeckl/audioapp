part of 'library_device_browser_pane.dart';

class _PathBar extends StatelessWidget {
  const _PathBar({
    required this.family,
    required this.showKind,
    required this.kind,
    required this.typeId,
    required this.step,
    required this.lockedType,
    required this.accent,
    this.onFamilyTap,
    this.onKindTap,
    this.onTypeTap,
  });

  final LibraryDeviceFamily family;
  final bool showKind;
  final LibraryInstrumentKind? kind;
  final String? typeId;
  final _DeviceBrowseStep step;
  final bool lockedType;
  final Color accent;
  final VoidCallback? onFamilyTap;
  final VoidCallback? onKindTap;
  final VoidCallback? onTypeTap;

  @override
  Widget build(BuildContext context) {
    final crumbs = <_Crumb>[
      _Crumb(
        label: family.title,
        active: step == _DeviceBrowseStep.kind ||
            (!showKind && step == _DeviceBrowseStep.type),
        onTap: onFamilyTap,
      ),
    ];
    if (showKind) {
      final kindLabel = kind?.title ??
          (step == _DeviceBrowseStep.kind ? 'Kind' : 'All kinds');
      crumbs.add(_Crumb(
        label: kindLabel,
        active: step == _DeviceBrowseStep.type,
        onTap: step.index > _DeviceBrowseStep.kind.index ? onKindTap : null,
      ));
    }
    if (step == _DeviceBrowseStep.results || typeId != null) {
      final typeLabel = typeId == null
          ? 'All types'
          : (deviceDefinitionRepository.find(typeId!)?.picker.name ?? typeId!);
      crumbs.add(_Crumb(
        label: typeLabel,
        active: step == _DeviceBrowseStep.results,
        onTap: lockedType
            ? null
            : (step == _DeviceBrowseStep.results ? onTypeTap : null),
      ));
    }
    if (step == _DeviceBrowseStep.results) {
      crumbs.add(const _Crumb(label: 'Results', active: true));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
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
                        color: LibraryTheme.labelMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  _CrumbChip(crumb: crumbs[i], accent: accent),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Crumb {
  const _Crumb({
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
}

class _CrumbChip extends StatelessWidget {
  const _CrumbChip({required this.crumb, required this.accent});

  final _Crumb crumb;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tappable = crumb.onTap != null;
    return Material(
      color: crumb.active
          ? accent.withValues(alpha: 0.16)
          : Colors.transparent,
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
              decoration: tappable && !crumb.active
                  ? TextDecoration.underline
                  : null,
              decorationColor: accent.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
