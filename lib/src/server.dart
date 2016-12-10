import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:logging/logging.dart';
import 'plugin.dart';

class DiagnosticsServer extends Angel {
  Logger _logger;
  Angel inner;
  File logFile;

  DiagnosticsServer(this.inner, this.logFile) {
    var oldHandler = inner.errorHandler;
    inner.onError((e, req, res) async {
      _logger.warning("Angel HTTP Exception: $e (errors: ${e.errors})", e);
      await oldHandler(e, req, res);
    });

    inner.fatalErrorStream.listen((data) {
      var e = data.error, st = data.stack;

      if (e is AngelHttpException) {
        _logger.warning("HTTP Exception: $e", e, st);

        if (st != null) _logger.warning("\n$st");
      } else {
        final msg = e is Exception ? e.message : e.toString();
        _logger.severe("Unhandled exception occurred - $msg", e, st);
        if (st != null) _logger.severe("\n$st");
        stderr.writeln(e);
        stderr.writeln(st);
      }
    });
  }

  @override
  Future handleRequest(HttpRequest request) async {
    var sw = new Stopwatch()..start();
    try {
      await inner.handleRequest(request);
      sw.stop();
      _logger.info(
          "${request.response.statusCode} ${request.method} ${request.uri} (${sw.elapsedMilliseconds} ms)");
    } catch (e, st) {
      sw.stop();

      if (e is AngelHttpException) {
        _logger.warning("HTTP Exception: $e", e, st);
      } else {
        _logger.severe(
            "Unhandled exception occurred - ${request.method} ${request.uri}",
            e,
            st);
        stderr.writeln(e);
        stderr.writeln(st);
      }
    }
  }

  @override
  Future<HttpServer> startServer([InternetAddress address, int port]) async {
    await configure(new AngelDiagnostics(logFile));
    _logger = container.make(Logger);
    inner.container.singleton(_logger, as: Logger);

    var server = await super.startServer(address, port);

    _logger.info(
        "Server listening at http://${server.address.host}:${server.port}");
    _logger.config(
        "Starting server with given configuration: ${inner.properties}");
    return server;
  }
}
