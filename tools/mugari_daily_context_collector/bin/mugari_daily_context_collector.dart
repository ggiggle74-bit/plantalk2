import 'dart:io';

import 'package:mugari_daily_context_collector/mugari_daily_context_collector.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run bin/mugari_daily_context_collector.dart '
      '<daily-keyword-context.json>',
    );
    exitCode = 64;
    return;
  }

  final file = File(arguments.single);
  if (!file.existsSync()) {
    stderr.writeln('Input file does not exist: ${file.path}');
    exitCode = 66;
    return;
  }

  try {
    final document = DailyKeywordContextDocument.decode(file.readAsStringSync());
    final result = const DailyKeywordContractValidator().validate(document);
    if (!result.isValid) {
      stderr.writeln('Daily keyword context is invalid:');
      for (final error in result.errors) {
        stderr.writeln('- $error');
      }
      exitCode = 65;
      return;
    }

    stdout.writeln(
      'Valid ${document.schemaVersion}: '
      '${document.keywords.length} candidate(s) for '
      '${document.locale}/${document.regionCode}.',
    );
  } on FormatException catch (error) {
    stderr.writeln('Unable to parse daily keyword context: ${error.message}');
    exitCode = 65;
  } on FileSystemException catch (error) {
    stderr.writeln('Unable to read input file: ${error.message}');
    exitCode = 74;
  }
}
