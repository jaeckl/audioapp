# Versioning

## App version

Semantic versioning: `MAJOR.MINOR.PATCH` in `app_flutter/pubspec.yaml`.

## Project file format

- `project_format_version` integer in `project.json`
- Migrations documented when version increments

## Bridge API

- Documented in [flutter_native_bridge.md](../bridge/flutter_native_bridge.md)
- Increment on breaking command/event changes

## Engine / device API

- Device `type` + `version` per serialized device block
- New parameters added with defaults for backward compatibility when possible

## JUCE

- Pinned tag in [juce_dependency.md](../architecture/juce_dependency.md)
