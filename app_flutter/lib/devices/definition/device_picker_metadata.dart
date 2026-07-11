import 'package:flutter/material.dart';

final class DevicePickerMetadata {
  const DevicePickerMetadata({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    this.libraryCategory,
    this.libraryTags = const [],
  });

  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final String? libraryCategory;
  final List<String> libraryTags;
}
