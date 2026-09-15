import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'data/services/messaging_service.dart';
import 'di/service_locator.dart';
import 'infrastructure/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMyApp();
  await getIt<MessagingService>().init();

  if (!AppConfig.hasSentry) {
    runApp(const JerdApp());
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.tracesSampleRate = 0.2;
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(SentryWidget(child: const JerdApp())),
  );
}
