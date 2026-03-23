import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

void configureAppLogging({required String appName}) {
  Logger.level = kDebugMode ? Level.trace : Level.info;
  Logger.defaultPrinter = () => _AppLogPrinter(appName: appName);
  Logger.defaultOutput = () => _SplitConsoleOutput();
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null || message.isEmpty) {
      return;
    }
    Logger().d(message);
  };
}

class _SplitConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    final sink = event.level >= Level.error ? stderr : stdout;
    for (final line in event.lines) {
      sink.writeln(line);
    }
  }
}

class _AppLogPrinter extends LogPrinter {
  _AppLogPrinter({required this.appName});

  final String appName;

  @override
  List<String> log(LogEvent event) {
    final label = '[$appName][${_levelLabel(event.level)}]';
    final lines = <String>[];

    lines.addAll(
      _splitLines(event.message?.toString()).map((line) => '$label $line'),
    );

    if (event.error != null) {
      lines.add('$label error=${event.error}');
    }

    if (event.stackTrace != null) {
      lines.addAll(
        _splitLines(event.stackTrace.toString())
            .map((line) => '$label stack=$line'),
      );
    }

    return lines.isEmpty ? <String>['$label <empty log message>'] : lines;
  }

  Iterable<String> _splitLines(String? value) sync* {
    if (value == null || value.isEmpty) {
      return;
    }

    for (final line in value.split('\n')) {
      final normalizedLine = line.trimRight();
      if (normalizedLine.isNotEmpty) {
        yield normalizedLine;
      }
    }
  }

  String _levelLabel(Level level) {
    if (level == Level.warning) {
      return 'WARN';
    }
    return level.name.toUpperCase();
  }
}
