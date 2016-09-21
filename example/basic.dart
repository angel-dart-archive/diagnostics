import 'dart:async';
import 'dart:io';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';

main() async {
  var app = new DiagnosticsServer(await createServer(), new File("log.txt"));
  await app.startServer();
}

Future<Angel> createServer() async {
  var app = new Angel();

  app.get("/", "index");

  app.get(
      "/favicon.ico",
      (req, ResponseContext res) =>
          res.redirect("https://en.wikipedia.org/favicon.ico", code: 302));

  app.get("/error", () {
    throw new AngelHttpException.Conflict();
  });

  app.get("/wait", () => new Future.delayed(new Duration(seconds: 10)).then((_) => "10 second wait time"));

  app.after.add((RequestContext req) {
    throw new AngelHttpException.NotFound(
        message: "No file exists at '${req.underlyingRequest.uri}'.");
  });

  return app;
}
