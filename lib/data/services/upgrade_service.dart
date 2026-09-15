import 'package:package_info_plus/package_info_plus.dart';
import '../../infrastructure/api_client.dart';
import '../../infrastructure/app_logger.dart';

class UpgradeInfo {
  final String latestVersion;
  final String apkUrl;
  final String notes;

  /// Below the backend's minimum build the app must update before use.
  final bool required;

  const UpgradeInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.notes,
    required this.required,
  });
}

/// In-app upgrade check for private APK distribution (no Play Store updates).
class UpgradeService {
  final ApiClient api;

  UpgradeService(this.api);

  Future<UpgradeInfo?> check() async {
    if (!api.isConfigured) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber) ?? 0;
      final json = await api.get('/app/version');
      final latest = (json['latest_build'] as num?)?.toInt() ?? 0;
      final minimum = (json['min_build'] as num?)?.toInt() ?? 0;
      if (latest <= build) return null;
      return UpgradeInfo(
        latestVersion: json['latest_version'] as String? ?? '',
        apkUrl: json['apk_url'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        required: build < minimum,
      );
    } catch (e) {
      AppLogger.warning('Upgrade check skipped', e);
      return null;
    }
  }
}
