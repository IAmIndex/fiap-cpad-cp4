import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/firebase/firebase_options.dart';
import 'package:flutter_application_1/firebase_options.dart' as generated;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android native configuration matches generated Dart configuration', () {
    final native = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final project = native['project_info'] as Map<String, dynamic>;
    final client = (native['client'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere(
          (client) =>
              client['client_info']['android_client_info']['package_name'] ==
              'br.com.academya.flutter_application_1',
        );
    const options = generated.DefaultFirebaseOptions.android;
    expect(
      project['project_id'],
      options.projectId,
      reason: 'Android and Dart must use the same Firebase project.',
    );
    expect(project['project_number'].toString(), options.messagingSenderId);
    expect(client['client_info']['mobilesdk_app_id'], options.appId);
    expect(
      client['api_key'][0]['current_key'] == options.apiKey,
      isTrue,
      reason: 'Android and Dart must use the same Firebase API key.',
    );
    expect(project['storage_bucket'], options.storageBucket);
  });

  test('FlutterFire metadata matches generated platform applications', () {
    final metadata = jsonDecode(File('firebase.json').readAsStringSync());
    final platforms = metadata['flutter']['platforms'];
    const options = generated.DefaultFirebaseOptions.android;
    expect(platforms['android']['default']['projectId'], options.projectId);
    expect(platforms['android']['default']['appId'], options.appId);
    final dart = platforms['dart']['lib/firebase_options.dart'];
    expect(dart['projectId'], options.projectId);
    expect(dart['configurations']['android'], options.appId);
    expect(
      dart['configurations']['web'],
      generated.DefaultFirebaseOptions.web.appId,
    );
    expect(
      dart['configurations']['windows'],
      generated.DefaultFirebaseOptions.windows.appId,
    );
  });

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
