/// Example demonstrating the complete DeviceSnapshot integration
/// 
/// This example shows the end-to-end usage of the refactored device snapshot
/// system, demonstrating the new architecture's benefits:
/// - Type safety with DeviceType enum
/// - Clean parameter management with ParameterId enum
/// - Structured error handling with DeviceSnapshotException hierarchy
/// - Modular device family organization
/// - Easy extension for new device types
/// 
/// ## Example Flow
/// 1. Parse JSON into DeviceSnapshot using DeviceSnapshotParser
/// 2. Modify parameters using type-safe withParameter method
/// 3. Validate parameter values with DeviceParameterHelper
/// 4. Handle errors gracefully with specific exception types
/// 
/// ## Usage
/// ```dart
/// import 'package:audioapp_flutter/bridge/device_snapshots.dart';
/// import 'package:audioapp_flutter/bridge/device_snapshot_parser.dart';
/// import 'package:audioapp_flutter/bridge/device_exception_helper.dart';
/// import 'package:audioapp_flutter/bridge/device_parameter_helper.dart';
/// 
/// void main() {
///   // Example 1: Parse a track gain snapshot
///   final jsonData = {
///     'id': 'track1',
///     'type': 'track_gain',
///     'parameters': {'gain': 0.8, 'pan': 0.5, 'bypass': 0},
///     'meters': {'gainReductionDb': -3.2, 'inputLevel': -12.5},
///   };
///   
///   try {
///     final snapshot = DeviceSnapshot.fromMap(jsonData);
///     print('Created snapshot: \${snapshot.toString()}');
///     
///     // Example 2: Modify parameters with type safety
///     final updatedSnapshot = snapshot.withParameter('gain', 0.9);
///     print('Updated snapshot gain: \${updatedSnapshot.gain}');
///     
///     // Example 3: Validate parameter values
///     final helper = DeviceParameterHelper();
///     if (helper.isParameterValueValid(
///       ParameterId.gain, 
///       DeviceType.fromJson('track_gain'), 
///       0.5
///     )) {
///       print('Parameter value is valid');
///     }
///     
///     // Example 4: Error handling
///   } on UnknownDeviceTypeException catch (e) {
///     print('Unknown device type: \${e.deviceType}');
///   } on DeviceParseException catch (e) {
///     print('Parse error: \${e.message}');
///   } catch (e) {
///     print('Unexpected error: \${e.toString()}');
///   }
/// }
/// ```
/// 
/// ## Key Benefits
/// - **Type Safety**: Compile-time checking prevents invalid parameter IDs
/// - **Modularity**: Each device family is in its own file for maintainability
/// - **Error Clarity**: Specific exception types provide actionable error info
/// - **Extensibility**: Easy to add new device types without modifying core code
/// - **Validation**: Comprehensive parameter validation prevents invalid states

import 'package:flutter/foundation.dart';
import 'bridge/device_snapshots.dart';
import 'bridge/device_snapshot_parser.dart';
import 'bridge/device_exception_helper.dart';
import 'bridge/device_parameter_helper.dart';

/// Example device snapshot usage class
class DeviceSnapshotExample {
  /// Demonstrate parsing and working with a track gain device
  static void demonstrateTrackGainDevice() {
    print('=== Track Gain Device Example ===');
    
    final jsonData = {
      'id': 'track1',
      'type': 'track_gain',
      'parameters': {'gain': 0.8, 'pan': 0.5, 'bypass': 0},
      'meters': {'gainReductionDb': -3.2, 'inputLevel': -12.5},
    };
    
    try {
      // Parse JSON into DeviceSnapshot
      final snapshot = DeviceSnapshot.fromMap(jsonData);
      print('Created snapshot: ${snapshot.toString()}');
      
      // Verify device type
      final deviceType = DeviceType.fromJson(snapshot.type);
      print('Device type: ${deviceType.name}');
      
      // Get available parameters for this device type
      final helper = DeviceParameterHelper();
      print('Available parameters: ${helper.getCommonParameters().map((p) => p.paramName).toList()}');
      
      // Example 2: Modify parameters with type safety
      final updatedSnapshot = snapshot.withParameter('gain', 0.9);
      print('Updated snapshot gain: ${updatedSnapshot.gain}');
      
      // Example 3: Validate parameter values
      if (helper.isParameterValueValid(
        ParameterId.gain, 
        DeviceType.trackGain, 
        0.5
      )) {
        print('✓ Parameter value is valid');
      } else {
        print('✗ Parameter value is invalid');
      }
      
      // Example 4: Multiple parameter updates
      final fullyUpdated = updatedSnapshot
          .withParameter('pan', 0.7)
          .withParameter('bypass', 1.0);
      
      print('Fully updated snapshot: ${fullyUpdated.toString()}');
      
    } on UnknownDeviceTypeException catch (e) {
      print('Unknown device type: ${e.deviceType}');
    } on DeviceParseException catch (e) {
      print('Parse error: ${e.message}');
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
    }
  }

  /// Demonstrate error handling and validation
  static void demonstrateErrorHandling() {
    print('\n=== Error Handling Example ===');
    
    // Example with unknown device type
    final invalidJson = {
      'id': 'device1',
      'type': 'unknown_device_type',
      'parameters': {'gain': 0.5},
    };
    
    try {
      final snapshot = DeviceSnapshot.fromMap(invalidJson);
      print('Should not reach here');
    } on UnknownDeviceTypeException catch (e) {
      print('✓ Caught UnknownDeviceTypeException: ${e.message}');
    }
    
    // Example with malformed structure
    final malformedJson = {
      'id': 'device2',
      // Missing 'type' field
      'parameters': {'gain': 0.5},
    };
    
    try {
      final snapshot = DeviceSnapshot.fromMap(malformedJson);
      print('Should not reach here');
    } on DeviceSnapshotStructureException catch (e) {
      print('✓ Caught DeviceSnapshotStructureException: ${e.message}');
    }
  }

  /// Demonstrate parameter validation across device types
  static void demonstrateParameterValidation() {
    print('\n=== Parameter Validation Example ===');
    
    final helper = DeviceParameterHelper();
    
    // Check which parameters are valid for different device types
    print('Parameters for TrackGain:');
    for (final param in ParameterId.values) {
      if (helper.isParameterValidForDevice(param, DeviceType.trackGain)) {
        print('  ✓ ${param.paramName}');
      }
    }
    
    print('\nParameters for Oscillator:');
    for (final param in ParameterId.values) {
      if (helper.isParameterValidForDevice(param, DeviceType.oscillator)) {
        print('  ✓ ${param.paramName}');
      }
    }
    
    print('\nCommon parameters across all devices:');
    for (final param in helper.getCommonParameters()) {
      print('  ✓ ${param.paramName}');
    }
    
    print('\nDynamic parameters (device-specific):');
    for (final param in helper.getDynamicParameters()) {
      print('  ✓ ${param.paramName}');
    }
  }

  /// Demonstrate extensibility with a new device type
  static void demonstrateExtensibility() {
    print('\n=== Extensibility Example ===');
    
    print('The architecture makes it easy to add new device types:');
    print('1. Create a new device family directory (e.g., device_families/your_new_type/)');
    print('2. Create a device snapshot file in that directory');
    print('3. Add a parser delegate in DeviceSnapshotParser');
    print('4. Update DeviceParameterHelper if the device uses unique parameters');
    print('5. Add the device type to the DeviceType enum (if needed)');
    
    // Show how easy it is to check if a device type exists
    print('\nChecking if a device type is valid:');
    for (final deviceType in DeviceType.values) {
      try {
        DeviceType.fromJson(deviceType.jsonValue);
        print('  ✓ ${deviceType.name} (${deviceType.jsonValue})');
      } catch (e) {
        print('  ✗ ${deviceType.name} (${deviceType.jsonValue}): $e');
      }
    }
  }

  /// Main demonstration method
  static void runAllExamples() {
    print('=== DeviceSnapshot Integration Examples ===\n');
    
    demonstrateTrackGainDevice();
    demonstrateErrorHandling();
    demonstrateParameterValidation();
    demonstrateExtensibility();
    
    print('\n=== All Examples Complete ===');
  }
}

// Run the examples when executed as a script
void main() {
  if (kDebugMode) {
    DeviceSnapshotExample.runAllExamples();
  }
}