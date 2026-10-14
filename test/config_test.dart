import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisa/config.dart';

void main() {
  test('kAppVersion pubspec.yaml dagi versiya bilan bir xil', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pubspec);
    expect(m, isNotNull);
    expect(kAppVersion, m!.group(1),
        reason: 'pubspec versiyasini oshirganda lib/config.dart ni ham yangilang');
  });
}
