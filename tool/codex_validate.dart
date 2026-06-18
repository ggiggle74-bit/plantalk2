import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final script = File.fromUri(Platform.script);
  final repoRoot = script.parent.parent.path;
  final results = <_CommandResult>[];

  final steps = [
    _ValidationStep(
      label: 'format',
      executable: 'dart',
      arguments: [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        'lib',
        'test',
        'tool',
      ],
      timeout: const Duration(seconds: 60),
    ),
    _ValidationStep(
      label: 'analyze',
      executable: 'flutter',
      arguments: ['analyze'],
      timeout: const Duration(seconds: 300),
    ),
    _ValidationStep(
      label: 'test',
      executable: 'flutter',
      arguments: ['test', '--reporter', 'expanded'],
      timeout: const Duration(seconds: 300),
    ),
  ];

  for (final step in steps) {
    final result = await _runStep(step, repoRoot);
    results.add(result);

    if (result.timedOut) {
      stderr.writeln(
        '[${step.label}] TIMEOUT after ${_formatDuration(result.duration)}',
      );
      exit(124);
    }

    if (result.exitCode != 0) {
      stderr.writeln(
        '[${step.label}] FAILED with exit code ${result.exitCode} '
        'after ${_formatDuration(result.duration)}',
      );
      exit(result.exitCode);
    }
  }

  stdout.writeln('');
  stdout.writeln('PASS: validation completed successfully.');
  for (final result in results) {
    stdout.writeln(
      '- ${result.label}: exit ${result.exitCode}, '
      '${_formatDuration(result.duration)}',
    );
  }
}

Future<_CommandResult> _runStep(
  _ValidationStep step,
  String workingDirectory,
) async {
  stdout.writeln('');
  stdout.writeln(
    '[${step.label}] ${step.executable} ${step.arguments.join(' ')}',
  );

  final stopwatch = Stopwatch()..start();
  final process = await Process.start(
    step.executable,
    step.arguments,
    workingDirectory: workingDirectory,
    runInShell: Platform.isWindows,
  );

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .listen(stdout.write)
      .asFuture<void>();
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .listen(stderr.write)
      .asFuture<void>();

  var timedOut = false;
  final exitCode = await process.exitCode.timeout(
    step.timeout,
    onTimeout: () async {
      timedOut = true;
      await _terminateProcess(process);
      return 124;
    },
  );

  await Future.wait([stdoutDone, stderrDone]);
  stopwatch.stop();

  return _CommandResult(
    label: step.label,
    exitCode: exitCode,
    duration: stopwatch.elapsed,
    timedOut: timedOut,
  );
}

Future<void> _terminateProcess(Process process) async {
  if (Platform.isWindows) {
    await Process.run('taskkill', [
      '/PID',
      '${process.pid}',
      '/T',
      '/F',
    ], runInShell: true);
    return;
  }

  process.kill(ProcessSignal.sigkill);
}

String _formatDuration(Duration duration) {
  final seconds = duration.inMilliseconds / Duration.millisecondsPerSecond;
  return '${seconds.toStringAsFixed(1)}s';
}

class _ValidationStep {
  const _ValidationStep({
    required this.label,
    required this.executable,
    required this.arguments,
    required this.timeout,
  });

  final String label;
  final String executable;
  final List<String> arguments;
  final Duration timeout;
}

class _CommandResult {
  const _CommandResult({
    required this.label,
    required this.exitCode,
    required this.duration,
    required this.timedOut,
  });

  final String label;
  final int exitCode;
  final Duration duration;
  final bool timedOut;
}
