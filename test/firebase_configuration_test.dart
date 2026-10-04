import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/firebase/firebase_options.dart';
import 'package:flutter_application_1/firebase_options.dart' as generated;
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    test('uses generated Firebase configuration for ${platform.name}', () {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(DefaultFirebaseOptions.isConfigured, isTrue);
      expect(
        DefaultFirebaseOptions.currentPlatform,
        generated.DefaultFirebaseOptions.currentPlatform,
      );
    });
  }

  test('unsupported platforms do not claim to be configured', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(DefaultFirebaseOptions.isConfigured, isFalse);
  });
}
