import 'dart:convert';
import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';
import 'package:test/test.dart';

import '../bin/src/dart_io_daily_context_storage_transport.dart';
import '../bin/src/supabase_daily_context_repository.dart';

void main() {
  group('SupabaseDailyContextRepository', () {
    test('builds a service-only idempotent upsert request', () async {
      const secret = 'fixture-service-role-key';
      DailyContextStorageRequest? captured;
      final repository = SupabaseDailyContextRepository(
        supabaseUrl: 'https://fixture-project.supabase.co',
        serverApiKey: secret,
        transport: (request) async {
          captured = request;
          return const DailyContextStorageResponse(
            statusCode: 201,
            body: '',
          );
        },
      );

      await repository.upsert(_document());

      expect(
        captured!.uri.toString(),
        'https://fixture-project.supabase.co/rest/v1/'
        'daily_keyword_contexts?on_conflict=context_date%2Clocale%2Cregion_code',
      );
      expect(captured!.headers['apikey'], secret);
      expect(captured!.headers['Authorization'], 'Bearer $secret');
      expect(
        captured!.headers['Prefer'],
        'resolution=merge-duplicates,return=minimal',
      );
      final body = jsonDecode(captured!.body) as Map<String, Object?>;
      expect(body['context_date'], '2026-07-18');
      expect(body['locale'], 'ko-KR');
      expect(body['region_code'], 'global');
      expect(body['schema_version'], 'daily-keyword-context/v1');
      expect(body['keywords'], isA<List<Object?>>());
      expect(captured!.body, isNot(contains(secret)));
    });

    test('uses a current secret API key only in the apikey header', () async {
      const secret = 'sb_secret_fixture-server-key';
      DailyContextStorageRequest? captured;
      final repository = SupabaseDailyContextRepository(
        supabaseUrl: 'https://fixture-project.supabase.co',
        serverApiKey: secret,
        transport: (request) async {
          captured = request;
          return const DailyContextStorageResponse(
            statusCode: 201,
            body: '',
          );
        },
      );

      await repository.upsert(_document());

      expect(captured!.headers['apikey'], secret);
      expect(captured!.headers, isNot(contains('Authorization')));
      expect(captured!.body, isNot(contains(secret)));
    });

    test('repeated runs target the same conflict key', () async {
      final requests = <DailyContextStorageRequest>[];
      final repository = SupabaseDailyContextRepository(
        supabaseUrl: 'https://fixture-project.supabase.co',
        serverApiKey: 'fixture-service-role-key',
        transport: (request) async {
          requests.add(request);
          return const DailyContextStorageResponse(
            statusCode: 204,
            body: '',
          );
        },
      );
      final document = _document();

      await repository.upsert(document);
      await repository.upsert(document);

      expect(requests, hasLength(2));
      expect(requests.first.uri, requests.last.uri);
      expect(requests.first.body, requests.last.body);
    });

    test('rejects invalid documents before calling storage', () async {
      var called = false;
      final repository = SupabaseDailyContextRepository(
        supabaseUrl: 'https://fixture-project.supabase.co',
        serverApiKey: 'fixture-service-role-key',
        transport: (_) async {
          called = true;
          return const DailyContextStorageResponse(
            statusCode: 204,
            body: '',
          );
        },
      );
      final invalid = DailyKeywordContextDocument(
        date: DateTime.utc(2026, 7, 18),
        locale: '',
        regionCode: 'global',
        generatedAt: DateTime.utc(2026, 7, 18, 1),
        sourceVersion: 'collector-cr2h-test',
        keywords: const [],
      );

      await expectLater(
        repository.upsert(invalid),
        throwsA(isA<DailyContextStorageException>()),
      );
      expect(called, isFalse);
    });

    test('sanitizes storage provider failures', () async {
      const secret = 'fixture-service-role-key';
      final repository = SupabaseDailyContextRepository(
        supabaseUrl: 'https://fixture-project.supabase.co',
        serverApiKey: secret,
        transport: (_) async => const DailyContextStorageResponse(
          statusCode: 403,
          body: '{"message":"sensitive provider detail"}',
        ),
      );

      Object? captured;
      try {
        await repository.upsert(_document());
      } catch (error) {
        captured = error;
      }

      expect(captured, isA<DailyContextStorageException>());
      expect(captured.toString(), contains('403'));
      expect(captured.toString(), isNot(contains(secret)));
      expect(
        captured.toString(),
        isNot(contains('sensitive provider detail')),
      );
    });

    test('redacts invalid URL and service key values', () {
      expect(
        () => SupabaseDailyContextRepository(
          supabaseUrl: 'http://secret-host.invalid/path',
          serverApiKey: 'fixture-key',
          transport: (_) async => const DailyContextStorageResponse(
            statusCode: 204,
            body: '',
          ),
        ),
        throwsA(
          predicate(
            (error) =>
                error.toString().contains('[redacted]') &&
                !error.toString().contains('secret-host'),
          ),
        ),
      );
      expect(
        () => SupabaseDailyContextRepository(
          supabaseUrl: 'https://fixture-project.supabase.co',
          serverApiKey: 'secret with spaces',
          transport: (_) async => const DailyContextStorageResponse(
            statusCode: 204,
            body: '',
          ),
        ),
        throwsA(
          predicate(
            (error) =>
                error.toString().contains('[redacted]') &&
                !error.toString().contains('secret with spaces'),
          ),
        ),
      );
    });
  });

  test('storage transport rejects another host before networking', () async {
    final transport = DartIoDailyContextStorageTransport(
      supabaseUrl: 'https://fixture-project.supabase.co',
    );

    await expectLater(
      transport.call(
        DailyContextStorageRequest(
          uri: Uri.parse(
            'https://example.com/rest/v1/daily_keyword_contexts',
          ),
          headers: const {},
          body: '{}',
        ),
      ),
      throwsA(isA<DailyContextStorageException>()),
    );
  });

  test('migration enforces uniqueness, RLS, and read-only app access', () {
    final migration = File(
      '../../supabase/migrations/'
      '20260718090000_create_daily_keyword_contexts.sql',
    ).readAsStringSync().toLowerCase();

    expect(
      migration,
      contains('primary key (context_date, locale, region_code)'),
    );
    expect(migration, contains('enable row level security'));
    expect(
      migration,
      contains(
        'revoke all on table public.daily_keyword_contexts '
        'from anon, authenticated',
      ),
    );
    expect(
      migration,
      contains(
        'grant select on table public.daily_keyword_contexts '
        'to anon, authenticated',
      ),
    );
    expect(migration, contains('to service_role'));
  });
}

DailyKeywordContextDocument _document() {
  return DailyKeywordContextDocument(
    date: DateTime.utc(2026, 7, 18),
    locale: 'ko-KR',
    regionCode: 'global',
    generatedAt: DateTime.utc(2026, 7, 18, 1),
    sourceVersion: 'collector-cr2h-test',
    keywords: [
      DailyKeywordCandidate(
        type: DailyKeywordTypes.seasonal,
        keyword: '여름',
        hint: '여름 기운이 이어지는 날',
        category: 'season',
        relevanceScore: 0.8,
        plantHint: '시원한 빛에서 쉬기',
        tone: DailyKeywordTones.bright,
        fitScore: 0.7,
        conversationAngles: const ['여름의 작은 변화를 이야기하기'],
      ),
    ],
  );
}
