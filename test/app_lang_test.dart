import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_time/core/app_lang.dart';

void main() {
  group('AppLang', () {
    test('missing key falls back to the key itself', () {
      expect(
        AppLang.I.tIn('fa', '__definitely_missing__'),
        '__definitely_missing__',
      );
    });

    test('fa and en tables stay in sync for core keys', () {
      const keys = <String>[
        'login',
        'signup',
        'email',
        'password',
        'forgot_password',
        'forgot_password_title',
        'forgot_password_body',
        'send_reset_link',
        'reset_email_sent_to',
        'reset_email_hint',
        'reset_error',
        'reset_too_many_requests',
        'reset_network_error',
        'reset_done_button',
        'copied',
        'invite_code',
        'public_invite_link',
        'weather_dash',
      ];

      for (final key in keys) {
        for (final code in AppLang.supported) {
          final value = AppLang.I.tIn(code, key);
          expect(value, isNot(key), reason: 'missing translation: $code/$key');
          expect(value.trim().isNotEmpty, isTrue,
              reason: 'empty translation: $code/$key');
        }
      }
    });

    test('trArgs substitutes {placeholder} values', () {
      final out = AppLang.trArgs('reset_email_sent_to', {'email': 'a@b.com'});
      expect(out, contains('a@b.com'));
      expect(out.contains('{email}'), isFalse);
    });
  });
}
