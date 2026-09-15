/// Build-time configuration, passed with `--dart-define` (or
/// `--dart-define-from-file=config/dev.json`). No secret lives in the app:
/// database keys and the Gemini key stay on the backend.
abstract final class AppConfig {
  /// Flask backend, e.g. https://jerd-api.onrender.com. Empty → offline demo mode.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Which repositories the service locator wires: `db` (default), `dummy` or `api`.
  static const dataSource = String.fromEnvironment('DATA_SOURCE', defaultValue: 'db');

  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Cloudinary unsigned upload preset — safe to ship, it can only create uploads.
  static const cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  static bool get hasBackend => apiBaseUrl.isNotEmpty;
  static bool get hasSentry => sentryDsn.isNotEmpty;
  static bool get hasCloudinary =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

  static const requestTimeout = Duration(seconds: 20);
  static const syncBatchSize = 100;
  static const backgroundSyncTask = 'jerd.sync';
}
