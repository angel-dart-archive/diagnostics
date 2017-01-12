import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:fnx_profiler/fnx_profiler.dart';

/// Adds another label to the running profiler.
///
/// Use [force] to force the profiler to run, even in production mode.
profile(String name, {bool force: false}) {
  return (Angel app, RequestContext req) {
    if (app.isProduction && !force) return new Future.value(true);

    if (req.injections.containsKey(RequestProfiler))
      req.injections[RequestProfiler].nest(name);
    return new Future.value(true);
  };
}

/// Profiles route handlers and request processing.
///
/// Use [force] to force the profiler to run, even in production mode.
AngelConfigurer profileRequests({bool force: false}) {
  return (Angel app) async {
    if (app.isProduction && !force) return;

    app.before.insert(0, (RequestContext req, res) async {
      clearAllStats();

      var profiler = openRootProfiler('${req.method} ${req.uri}');
      var c = app.properties['__profileCompleter'] = new Completer();

      profiler.profileFuture('handleRequest', c.future).then((_) {
        print('Stats for ${req.method} ${req.uri}:');
        printProfilerStats();
        print('');
      });

      var requestProfiler = app.properties['__profiler'] =
          new _RequestProfilerImpl(profiler, req);
      req..inject(RequestProfiler, requestProfiler)..inject(Profiler, profiler);
      return true;
    });

    app.responseFinalizers.add((req, res) async {
      if (app.properties.containsKey('__profiler')) {
        List<Profiler> profilers = [];
        _RequestProfilerImpl profiler = app.properties['__profiler'];

        while (profiler != null) {
          profilers.insert(0, profiler._profiler);
          profiler = profiler._child;
        }

        profilers.forEach((p) => p.close());
      }

      app.properties['__profileCompleter']?.complete();
    });
  };
}

/// Allows you to customize profiling per request.
abstract class RequestProfiler {
  Profiler nest(String name);
}

class _RequestProfilerImpl implements RequestProfiler {
  _RequestProfilerImpl _child;
  final Profiler _profiler;
  final RequestContext _request;

  _RequestProfilerImpl(this._profiler, this._request);

  @override
  Profiler nest(String name) {
    var profiler = _profiler.openChild(name);
    var requestProfiler = _child = new _RequestProfilerImpl(profiler, _request);
    _request
      ..inject(RequestProfiler, requestProfiler)
      ..inject(Profiler, profiler);
    return profiler;
  }
}
