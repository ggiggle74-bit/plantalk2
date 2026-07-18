import 'dart:convert';
import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';

void main(List<String> arguments) {
  if (arguments.length < 2) {
    stderr.writeln(
      'Usage: dart run bin/plan_daily_queries.dart <YYYY-MM-DD> <locale> '
      '[--region-code=CODE] [--region-label=LABEL] '
      '[--age-bands=10s,20s,...]',
    );
    exitCode = 64;
    return;
  }

  try {
    final date = _parseDate(arguments[0]);
    final locale = arguments[1];
    final options = _options(arguments.skip(2));
    final ageBands = (options['age-bands'] ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);

    final request = DailyQueryPlanRequest(
      date: date,
      locale: locale,
      regionCode: options['region-code'] ?? 'global',
      regionLabel: options['region-label'],
      targetAgeBands: ageBands,
    );
    final plan = const DailyQueryPlanner().plan(request);
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(plan.toJson()));
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 70;
  }
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
  final result = <String, String>{};
  for (final argument in arguments) {
    if (!argument.startsWith('--') || !argument.contains('=')) {
      throw FormatException('invalid option: $argument');
    }
    final separator = argument.indexOf('=');
    final key = argument.substring(2, separator).trim();
    final value = argument.substring(separator + 1).trim();
    if (key.isEmpty || value.isEmpty) {
      throw FormatException('invalid option: $argument');
    }
    result[key] = value;
  }
  return result;
}
