import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:console/console.dart';
import 'package:logging/logging.dart';

/// Logs requests, responses and errors to the given [logFile].
AngelPlugin logRequests(File logFile) => new _RequestLogger(logFile);

class _RequestLogger extends AngelPlugin {
  final File _logFile;
  final Logger _logger = new Logger("Angel");
  TextPen _pen = new TextPen();

  _RequestLogger(this._logFile);

  call(Angel app) async {
    Logger.root.level = Level.ALL;

    Logger.root.onRecord.listen((LogRecord rec) async {
      if (!await _logFile.exists()) await _logFile.create(recursive: true);

      if (rec.level != Level.FINE) {
        await _logFile.writeAsStringSync(
            "${rec.level.name}: ${rec.time}: ${rec.message}\n",
            mode: FileMode.APPEND);

        chooseColor(_pen.reset(), rec.level);
        _pen("${rec.level.name}: ${rec.time}: ${rec.message}");
        _pen();
      }
    });

    app.container.singleton(_logger);

    var oldHandler = app.errorHandler;
    app.onError((e, req, res) async {
      _logger.warning(
          "${req.uri}: Angel HTTP Exception: $e (errors: ${e.errors})", e);

      if (req.properties['__stopwatch'] is Stopwatch)
        req.properties['__stopwatch'].stop();

      await oldHandler(e, req, res);
    });

    app.fatalErrorStream.listen((data) {
      var e = data.error, st = data.stack;

      if (e is AngelHttpException) {
        _logger.warning("HTTP Exception: $e", e, st);

        if (st != null) _logger.warning("\n$st");
      } else {
        final msg = e is Exception ? e.message : e.toString();
        _logger.severe(
            "${data.request?.uri}: Unhandled exception occurred - $msg", e, st);
        if (st != null) _logger.severe("\n$st");
        stderr.writeln(e);
        stderr.writeln(st);
      }
    });

    app
      ..before.insert(
          0,
          ((RequestContext req, res) async {
            req.properties['__stopwatch'] = new Stopwatch()..start();
            return true;
          }))
      ..responseFinalizers.add((req, res) async {
        if (req.properties.containsKey('__stopwatch')) {
          Stopwatch sw = req.__stopwatch..stop();
          _logger.info(
              "${res.statusCode} ${req.method} ${req.uri} (${sw.elapsedMilliseconds} ms)");
        }
      });
  }

  void chooseColor(TextPen pen, Level level) {
    if (level == Level.SHOUT)
      pen.darkRed();
    else if (level == Level.SEVERE)
      pen.red();
    else if (level == Level.WARNING)
      pen.yellow();
    else if (level == Level.INFO)
      pen.magenta();
    else if (level == Level.FINER)
      pen.blue();
    else if (level == Level.FINEST)
      pen.darkBlue();
    else
      pen.black();
  }
}