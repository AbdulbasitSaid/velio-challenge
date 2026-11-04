import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:velio_tokens/velio_tokens.dart';

void main() {
  final fixtures = jsonDecode(File('../fixtures/avatar.json').readAsStringSync()) as List<dynamic>;

  test('avatarIndex matches the shared fixtures', () {
    for (final f in fixtures.cast<Map<String, dynamic>>()) {
      expect(avatarIndex(f['seed'] as String), f['index'], reason: f['seed'] as String);
    }
  });

  test('palette has five colours', () {
    expect(VelioColors.avatar, hasLength(5));
  });
}
