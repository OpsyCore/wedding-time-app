// نگهبان رگرسیون برای دو خطایی که بیلد APK را شکستند:
//
//   1) تعریف تکراری یک ویجت در یک فایل
//      → lib/screens/tutorials_screen.dart دو بار TutorialsScreen داشت و
//        بیلد با «The name 'TutorialsScreen' is already defined» شکست.
//
//   2) استفاده از getter حذف‌شدهٔ Color.a
//      → با مهاجرت Flutter به کانال‌های double، `col.a` در دسترس نیست و
//        بیلد با «The getter 'a' isn't defined for the class 'Color'» شکست.
//        راه درست: Color.opacity یا مقادیر alpha مستقل.
//
// اجرا:  flutter test test/build_regression_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_time/core/app_lang.dart';

Iterable<File> _dartFilesUnder(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

void main() {
  group('build regressions', () {
    test('no duplicate class declarations inside one file', () {
      final duplicates = <String>[];

      for (final file in _dartFilesUnder('lib')) {
        final source = file.readAsStringSync();
        final seen = <String, int>{};
        for (final m in RegExp(r'^\s*(?:abstract\s+|base\s+|final\s+)?class\s+(\w+)',
                multiLine: true)
            .allMatches(source)) {
          final name = m.group(1)!;
          seen[name] = (seen[name] ?? 0) + 1;
        }
        seen.forEach((name, count) {
          if (count > 1) duplicates.add('${file.path}: $name declared $count×');
        });
      }

      expect(
        duplicates,
        isEmpty,
        reason: 'یک کلاس نباید در یک فایل دو بار تعریف شود:\n'
            '${duplicates.join('\n')}',
      );
    });

    test('colors never read the removed Color.a getter', () {
      // الگوی دقیقاً همان خطای قبلی: withValues(alpha: col.a * …)
      final pattern = RegExp(r'withValues\(\s*alpha:\s*[^()]*\.a\b');
      final offenders = <String>[];

      for (final file in _dartFilesUnder('lib')) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'به‌جای Color.a از Color.opacity استفاده کنید:\n'
            '${offenders.join('\n')}',
      );
    });

    test('every translation key used in lib exists in fa and en', () {
      final used = <String>{};
      final patterns = [
        RegExp(r"(?:AppLang\.tr|AppLang\.trArgs)\(\s*'([^']+)'"),
        RegExp(r"\bt\(\s*'([^']+)'"),
        RegExp(r"\bt\(\s*\n\s*'([^']+)'"),
      ];

      for (final file in _dartFilesUnder('lib')) {
        if (file.path.endsWith('core/app_lang.dart')) continue;
        final source = file.readAsStringSync();
        for (final p in patterns) {
          for (final m in p.allMatches(source)) {
            used.add(m.group(1)!);
          }
        }
      }

      final missing = <String>[];
      for (final key in used) {
        for (final code in AppLang.supported) {
          final value = AppLang.I.tIn(code, key);
          if (value == key || value.trim().isEmpty) {
            missing.add('$code/$key');
          }
        }
      }

      expect(
        missing,
        isEmpty,
        reason: 'کلیدهای ترجمهٔ گم‌شده (متن خام در UI دیده می‌شود):\n'
            '${(missing..sort()).join('\n')}',
      );
    });

    test('AppConfig.imgbbApiKey never uses the revoked key', () {
      final source = File('lib/core/app_config.dart').readAsStringSync();
      expect(
        source.contains('63ad9a49b307c10e9cbcbbe65c1e23bf'),
        isFalse,
        reason: 'کلید قدیمی و لو رفتهٔ ImgBB نباید در سورس باقی بماند.',
      );
    });

    test('every StreamBuilder in lib handles hasError', () {
      final missing = <String>[];

      for (final file in _dartFilesUnder('lib')) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!RegExp(r'\bStreamBuilder\s*(?:<|\()').hasMatch(lines[i])) {
            continue;
          }
          final end = (i + 30 < lines.length) ? i + 30 : lines.length;
          final window = lines.sublist(i, end).join('\n');
          if (!window.contains('hasError')) {
            missing.add('${file.path}:${i + 1}');
          }
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'هر StreamBuilder باید حالت hasError را مدیریت کند تا اسکرین در لودینگ بی‌نهایت نماند:\n'
            '${missing.join('\n')}',
      );
    });
  });
}
