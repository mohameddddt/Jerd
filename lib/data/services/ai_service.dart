import 'dart:convert';
import 'dart:io';
import '../../infrastructure/api_client.dart';

class ProductSuggestion {
  final String name;
  final String? unit;
  final String? category;

  const ProductSuggestion({required this.name, this.unit, this.category});
}

/// Gemini features, proxied by the backend so the API key never ships in the app.
class AiService {
  final ApiClient api;

  AiService(this.api);

  bool get isAvailable => api.isConfigured;

  /// Reads a photo of the label and suggests a name and unit for an unknown barcode.
  Future<ProductSuggestion?> suggestFromPhoto(String imagePath, {String? barcode}) async {
    final bytes = await File(imagePath).readAsBytes();
    final json = await api.post('/ai/suggest', {
      'image_base64': base64Encode(bytes),
      'mime_type': imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
      'barcode': ?barcode,
    });
    final name = (json['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    return ProductSuggestion(
      name: name,
      unit: json['unit'] as String?,
      category: json['category'] as String?,
    );
  }

  /// A short reorder plan drafted from recent movement history.
  Future<String> reorderSuggestions() async {
    final json = await api.get('/ai/reorder');
    return json['suggestion'] as String? ?? '';
  }
}
