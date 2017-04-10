# diagnostics
Support for diagnostics within the Angel framework.

For accuracy, **these plugins must be called after all other plugins
are configured**. The best way to ensure this would be to call it
*right before server startup*:

```dart
app.justBeforeStart.addAll([
  logRequests(...),
  profileRequests(...)
]);
```

# Logging Requests
`logRequests`

This plug-in lets you log requests, responses and errors (optionally to a log
file), and also displays how much time (in milliseconds) it took to
handle a request.

# Profiler
`profileRequests`

This plug-in automatically prints profiling information on each request.

`profile(name)`

This middleware adds another label to the running profiler, if any.
This makes it easy to detect application bottlenecks.

Both automatically turn themselves off in production mode. Use `force`
to prevent this.

# Usage
See the [examples](/example).
