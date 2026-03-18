import 'package:flutter_test/flutter_test.dart';
import 'package:inkwell/core/markdown/frontmatter_parser.dart';
import 'package:inkwell/models/frontmatter.dart';

void main() {
  group('FrontmatterParser', () {
    test('parses mood, energy, sleep and tags', () {
      const raw = '''---
mood: 4
energy: 3
sleep: 7.5
tags:
  - daily
  - work
---

Hello World
''';

      final (fm, body) = FrontmatterParser.parse(raw);

      expect(fm.mood, 4);
      expect(fm.energy, 3);
      expect(fm.sleep, 7.5);
      expect(fm.tags, ['daily', 'work']);
      expect(body.trim(), 'Hello World');
    });

    test('returns empty frontmatter when no YAML block present', () {
      const raw = 'Just plain text\nno frontmatter here';

      final (fm, body) = FrontmatterParser.parse(raw);

      expect(fm.isEmpty, isTrue);
      expect(body, raw);
    });

    test('preserves unknown fields in extra map on roundtrip', () {
      const raw = '''---
mood: 3
custom_field: "hello"
another: 42
---

Body text
''';

      final (fm, body) = FrontmatterParser.parse(raw);

      expect(fm.mood, 3);
      expect(fm.extra['custom_field'], 'hello');
      expect(fm.extra['another'], 42);

      final serialized = FrontmatterParser.serialize(fm, body);
      final (fm2, body2) = FrontmatterParser.parse(serialized);

      expect(fm2.mood, 3);
      expect(fm2.extra['custom_field'], 'hello');
      expect(fm2.extra['another'], 42);
      expect(body2.trim(), 'Body text');
    });

    test('serializes frontmatter back to YAML', () {
      const fm = Frontmatter(
        mood: 5,
        energy: 4,
        tags: ['journal', 'travel'],
      );

      final result = FrontmatterParser.serialize(fm, 'My entry\n');

      expect(result, contains('mood: 5'));
      expect(result, contains('energy: 4'));
      expect(result, contains('journal'));
      expect(result, contains('My entry'));
    });

    test('parses writing_duration string', () {
      const raw = '''---
writing_duration: 12m
---

content
''';

      final (fm, _) = FrontmatterParser.parse(raw);
      expect(fm.writingDuration, const Duration(minutes: 12));
    });
  });
}
