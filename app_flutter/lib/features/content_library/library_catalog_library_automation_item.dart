part of 'library_catalog.dart';

class LibraryAutomationItem extends LibraryItem {
  const LibraryAutomationItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.parameterLabel,
    this.trackId,
    this.clip,
    this.suggestedParamId,
    super.tags,
  });

  final String parameterLabel;
  final String? trackId;
  final AutomationClipSnapshot? clip;
  final String? suggestedParamId;
}
