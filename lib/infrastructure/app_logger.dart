import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app_config.dart';

/// Console logging everywhere, plus Sentry for errors once a DSN is configured.
abstract final class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 6, noBoxingByDefault: true),
  );

  static void debug(String message) => _logger.d(message);

  static void info(String message) => _logger.i(message);

  static void warning(String message, [Object? error]) => _logger.w(message, error: error);

  static void error(String message, Object error, [StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    if (AppConfig.hasSentry) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) => scope.setContexts('jerd', {'message': message}),
      );
    }
  }
}
