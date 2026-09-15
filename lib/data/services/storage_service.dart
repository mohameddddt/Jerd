import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../infrastructure/app_config.dart';

/// Product photos: kept on the phone first, uploaded to Cloudinary when online.
/// Only the returned URL is stored in the product row.
class StorageService {
  final http.Client _http;

  StorageService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  bool get isConfigured => AppConfig.hasCloudinary;

  /// Copies a picked image into app storage so it survives the picker's cache cleanup.
  Future<String> keepLocally(String pickedPath, String productUuid) async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
    await dir.create(recursive: true);
    final target = p.join(dir.path, '$productUuid${p.extension(pickedPath)}');
    await File(pickedPath).copy(target);
    return target;
  }

  /// Returns the secure URL, or null when not configured.
  Future<String?> upload(String localPath, {required String productUuid}) async {
    if (!isConfigured) return null;
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..fields['folder'] = 'jerd/products'
      ..fields['public_id'] = productUuid
      ..files.add(await http.MultipartFile.fromPath('file', localPath));
    final response = await http.Response.fromStream(
      await _http.send(request).timeout(const Duration(seconds: 60)),
    );
    if (response.statusCode != 200) {
      throw HttpException('Upload failed (${response.statusCode})');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['secure_url'] as String;
  }
}
