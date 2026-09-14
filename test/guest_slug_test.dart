import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_time/core/guest_slug.dart';

void main() {
  group('GuestSlug.from', () {
    test('extracts the slug from /invite/<slug>', () {
      expect(GuestSlug.from('/invite/zaza-sara'), 'zaza-sara');
    });

    test('accepts portal, guest and g roots', () {
      expect(GuestSlug.from('/portal/abc'), 'abc');
      expect(GuestSlug.from('/guest/abc'), 'abc');
      expect(GuestSlug.from('/g/abc'), 'abc');
    });

    test('strips the query string', () {
      expect(GuestSlug.from('/invite/abc?x=1&y=2'), 'abc');
    });

    test('handles a full URL', () {
      expect(GuestSlug.from('https://example.com/invite/abc'), 'abc');
    });

    test('handles hash-based routing', () {
      expect(GuestSlug.from('#/invite/abc'), 'abc');
    });

    test('url-decodes the slug', () {
      expect(GuestSlug.from('/invite/a%20b'), 'a b');
    });

    test('returns empty string when the path is valid but no slug', () {
      expect(GuestSlug.from('/invite'), '');
      expect(GuestSlug.from('/invite/'), '');
    });

    test('returns null for non-guest paths', () {
      expect(GuestSlug.from('/'), isNull);
      expect(GuestSlug.from('/home'), isNull);
      expect(GuestSlug.from(''), isNull);
      expect(GuestSlug.from(null), isNull);
    });
  });
}
