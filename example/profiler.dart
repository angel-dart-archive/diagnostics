import 'dart:async';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';

main() async {
  var app = await createServer();

  // Add diagnostics AFTER everything else. Ideally, just before startup.
  await app.configure(profileRequests());

  var server = await app.startServer();
  print('Listening at http://${server.address.address}:${server.port}');
}

Future<Angel> createServer() async {
  var app = new Angel();

  app.get("/", "index");

  app.get(
      "/favicon.ico",
      (req, ResponseContext res) =>
          res.redirect("https://en.wikipedia.org/favicon.ico", code: 302));

  app.chain(profile('group-a')).group('a', (router) {
    router.chain(profile('group-b')).group('b', (router) {
      router.chain(profile('handler-c')).get('/c', 'd');
    });
  });

  app.get("/error", () {
    throw new AngelHttpException.conflict();
  });

  app.get('/general-error', () => throw new Exception('I hate everything'));

  app.chain(profile('10-second-delay')).get(
      "/wait",
      () => new Future.delayed(new Duration(seconds: 10))
          .then((_) => "10 second wait time"));

  app.after.add((RequestContext req) {
    throw new AngelHttpException.notFound(
        message: "No file exists at '${req.io.uri}'.");
  });

  return app..dumpTree();
}
