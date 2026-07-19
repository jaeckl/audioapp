import 'package:audioapp/features/device_strip/nesting_error_messages.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps NestingError bridge codes to snackbar copy', () {
    expect(
      nestingErrorSnackMessage(
          PlatformException(code: 'branch_device_cap', message: 'ignored')),
      'This strip is full (max 8 devices).',
    );
    expect(
      nestingErrorSnackMessage(PlatformException(code: 'pad_device_cap')),
      'This drum pad is full (max 4 devices).',
    );
    expect(
      nestingErrorSnackMessage(PlatformException(code: 'ring_lease_exhausted')),
      'Too many time-based/buffer effects on this track.',
    );
  });

  test('falls back to PlatformException message for unknown codes', () {
    expect(
      nestingErrorSnackMessage(
          PlatformException(code: 'other', message: 'Custom fail')),
      'Custom fail',
    );
  });
}
