import 'dart:convert';
import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';

import 'src/dart_io_daily_context_storage_transport.dart';
import 'src/dart_io_search_http_transport.dart';
import 'src/supabase_daily_context_repository.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    _usage();
    exitCode = 64;
    return;
  }

  try {
    final date = _parseDate(arguments[0]);
    final locale = arguments[1];
    final trailingArguments = arguments.skip(2).toList();
    final persistCount = trailingArguments
        .where((argument) => argument == '--persist')
        .length;
    if (persistCount > 1) {
      throw const FormatException('--persist may be specified only once.');
    }
    final persist = persistCount == 1;
    final options = _options(
      trailingArguments.where((argument) => argument != '--persist'),
    );

    final apiKey = Platform.environment['KAKAO_REST_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      stderr.writeln(
        'KAKAO_REST_API_KEY is required in the process environment.',
      );
      exitCode = 78;
      return;
    }

    final supabaseUrl = persist ? Platform.environment['SUPABASE_URL'] : null;
    final serverApiKey = persist
        ? Platform.environment['SUPABASE_SECRET_KEY'] ??
              Platform.environment['SUPABASE_SERVICE_ROLE_KEY']
        : null;
    if (persist &&
        (supabaseUrl == null ||
            supabaseUrl.trim().isEmpty ||
            serverApiKey == null ||
            serverApiKey.trim().isEmpty)) {
      stderr.writeln(
        'SUPABASE_URL and a server API key are required when --persist '
        'is enabled. Prefer SUPABASE_SECRET_KEY; the legacy '
        'SUPABASE_SERVICE_ROLE_KEY remains supported.',
      );
      exitCode = 78;
      return;
    }

    final ageBands = (options['age-bands'] ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final searchTransport = DartIoSearchHttpTransport();
    final searchClient = DaumSearchClient(
      restApiKey: apiKey,
      transport: searchTransport.call,
    );
    final runner = DailyContextCollectorRunner(
      searchLoader: DaumSearchDocumentLoader(client: searchClient),
    );
    final report = await runner.run(
      DailyCollectorRunRequest(
        date: date,
        locale: locale,
        regionCode: options['region-code'] ?? 'global',
        regionLabel: options['region-label'],
        targetAgeBands: ageBands,
        generatedAt: DateTime.now().toUtc(),
        sourceVersion: options['source-version'] ?? 'collector-cr2j1',
      ),
    );

    var stored = false;
    if (persist && report.status != DailyCollectorRunStatus.sourceFailed) {
      final storageTransport = DartIoDailyContextStorageTransport(
        supabaseUrl: supabaseUrl!,
      );
      final repository = SupabaseDailyContextRepository(
        supabaseUrl: supabaseUrl,
        serverApiKey: serverApiKey!,
        transport: storageTransport.call,
      );
      await repository.upsert(report.document);
      stored = true;
    }

    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'summary': {
          ...report.toSummaryJson(),
          'stored': stored,
        },
        'document': report.document.toJson(),
      }),
    );
    if (report.status == DailyCollectorRunStatus.sourceFailed) {
      exitCode = 75;
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on DailyContextStorageException catch (error) {
    stderr.writeln(error);
    exitCode = 74;
  } on Object {
    stderr.writeln('Daily context collection failed.');
    exitCode = 70;
  }
}

void _usage() {
  stderr.writeln(
    'Usage: dart run bin/collect_daily_context.dart <YYYY-MM-DD> <locale> '
    '[--region-code=CODE] [--region-label=LABEL] '
    '[--age-bands=10s,20s,...] [--source-version=VERSION] [--persist]',
  );
  stderr.writeln(
    'Search secret: set KAKAO_REST_API_KEY in the process environment.',
  );
  stderr.writeln(
    'Storage secrets for --persist: set SUPABASE_URL and '
    'SUPABASE_SECRET_KEY. The legacy SUPABASE_SERVICE_ROLE_KEY is '
    'also supported.',
  );
}

DateTime _parseDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw const FormatException('date must use YYYY-MM-DD format.');
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.utc(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('date is not a valid calendar date: $value.');
  }
  return parsed;
}

Map<String, String> _options(Iterable<String> arguments) {
  const allowed = {
    'region-code',
    'region-label',
    'age-bands',
    'source-version',
  };
  final result = <String, String>{};
  for (final argument in arguments) {
    if (!argument.startsWith('--') || !argument.contains('=')) {
      throw FormatException('invalid option: $argument');
    }
    final separator = argument.indexOf('=');
    final key = argument.substring(2, separator).trim();
    final value = argument.substring(separator + 1).trim();
    if (!allowed.contains(key) || value.isEmpty || result.containsKey(key)) {
      throw FormatException('invalid option: $argument');
    }
    result[key] = value;
  }
  return result;
}
