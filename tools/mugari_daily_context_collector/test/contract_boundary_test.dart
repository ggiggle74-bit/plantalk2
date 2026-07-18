import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

void main() {
  test('contract package has no UI, network, storage, or crawler dependency', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    const forbiddenSnippets = [
      'dart:html',
      'package:flutter',
      'package:http',
      'supabase',
      'kakao',
      'dapi.kakao.com',
      'crawler',
      'scheduler',
    ];

    for (final file in dartFiles) {
      final source = file.readAsStringSync().toLowerCase();
      for (final snippet in forbiddenSnippets) {
        expect(
          source,
          isNot(contains(snippet)),
          reason: '${file.path} must not reference $snippet in CR-2A',
        );
      }
    }
  });

  test('checked-in example satisfies the executable contract', () {
    final source = File(
      'example/daily_keyword_context.json',
    ).readAsStringSync();
    final document = DailyKeywordContextDocument.decode(source);
    final result = const DailyKeywordContractValidator().validate(document);

    expect(result.errors, isEmpty);
    expect(document.keywords, hasLength(3));
    expect(
      document.keywords.expand((keyword) => keyword.conversationAngles),
      isNotEmpty,
    );
  });

  test('JSON Schema and executable model use the same schema version', () {
    final schema = File(
      'schema/daily_keyword_context_v1.schema.json',
    ).readAsStringSync();

    expect(
      schema,
      contains(DailyKeywordContextDocument.currentSchemaVersion),
    );
  });
}
