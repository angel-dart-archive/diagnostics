import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:console/console.dart';
import 'package:logging/logging.dart';

class AngelDiagnostics extends AngelPlugin {
  final File _logFile;
  final Logger _logger = new Logger("Angel");
  TextPen _pen = new TextPen();

  AngelDiagnostics(this._logFile) {
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
  }

  @override
  Future call(Angel app) async {
    app.container.singleton(_logger, as: Logger);
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
