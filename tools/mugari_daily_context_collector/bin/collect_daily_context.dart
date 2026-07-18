import 'dart:convert';
import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    _usage();
    exitCode = 64;
    return;
  }

  try {
    final date = _parseDate(arguments[0]);
    final locale = arguments[1];
    final options = _options(arguments.skip(2));
    final apiKey = Platform.environment['KAKAO_REST_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      stderr.writeln(
        'KAKAO_REST_API_KEY is required in the process environment.',
      );
      exitCode = 78;
      return;
    }

    final ageBands = (options['age-bands'] ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final transport = DartIoSearchHttpTransport();
    final searchClient = DaumSearchClient(
      restApiKey: apiKey,
      transport: transport.call,
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
        sourceVersion: options['source-version'] ?? 'collector-cr2g',
      ),
    );

    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'summary': report.toSummaryJson(),
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
  } on Object {
    stderr.writeln('Daily context collection failed.');
    exitCode = 70;
  }
}

void _usage() {
  stderr.writeln(
    'Usage: dart run bin/collect_daily_context.dart <YYYY-MM-DD> <locale> '
    '[--region-code=CODE] [--region-label=LABEL] '
    '[--age-bands=10s,20s,...] [--source-version=VERSION]',
  );
  stderr.writeln(
    'Secret: set KAKAO_REST_API_KEY in the process environment.',
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
