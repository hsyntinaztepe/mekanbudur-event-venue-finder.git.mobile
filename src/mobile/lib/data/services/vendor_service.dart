import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../models/public_vendor_model.dart';
import '../models/vendor_profile_model.dart';

class VendorService {
  final ApiClient _apiClient;

  VendorService(this._apiClient);

  Future<VendorProfile> getProfile() async {
    final response = await _apiClient.dio.get('/vendor/profile');
    return VendorProfile.fromJson(response.data);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _apiClient.dio.put('/vendor/profile', data: data);
  }

  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      return const <String>[];
    }

    final files = <MapEntry<String, MultipartFile>>[];
    for (final path in filePaths) {
      final normalizedPath = path.replaceAll('\\', '/');
      final fileName = normalizedPath.split('/').last;
      files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(path, filename: fileName),
        ),
      );
    }

    final formData = FormData();
    formData.files.addAll(files);

    final response = await _apiClient.dio.post(
      '/vendor/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['urls'] is List) {
      return (body['urls'] as List)
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    throw const FormatException('Fotoğraf yükleme yanıtı okunamadı');
  }

  Future<List<PublicVendor>> getPublicVendors() async {
    final response = await _apiClient.dio.get('/vendors');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PublicVendor.fromJson)
          .where((v) => v.userId.isNotEmpty && v.companyName.isNotEmpty)
          .toList(growable: false);
    }
    throw const FormatException('Vendor listesi okunamadı');
  }
}
