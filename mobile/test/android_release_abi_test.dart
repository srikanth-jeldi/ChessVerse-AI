import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Android bundles support ARM64 and x86_64', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('"arm64-v8a"'));
    expect(gradle, contains('"x86_64"'));

    final workflow = File(
      '../.github/workflows/android-production-release.yml',
    ).readAsStringSync();
    expect(
      workflow,
      contains('--target-platform android-arm64,android-x64'),
    );
  });
}
